#--
# Copyright (c) 2019 Fuyuki Academy
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#++

class Teacher::AllocationsController < ApplicationController
  before_action :require_assigned, only: [:show, :create, :assign, :confirm]
  before_action :set_courses, only: [:index]
  before_action :set_course, only: [:show, :create, :assign, :confirm]
  before_action :set_class_session, only: [:update]

  def show
    if params[:session_no]
      if params[:session_no] =~ /^[0-9]+$/ && params[:session_no].to_i <= @course.class_session_count
        @class_session = @course.class_session(params[:session_no])
        unless @class_session
          @class_session = ClassSession.new
          @class_session.class_session_day = I18n.t("common.COMMON_COUNTFORM", :param0 => params[:session_no])
          @class_session.class_session_no = params[:session_no]
        end
      end
    end
  end

  def create
    @class_session = ClassSession.new(class_session_params)
    @class_session.course_id = @course.id
    if class_session_valid? && @class_session.save
      url = url_for(:action => :show, :course_id => @course, :session_no => @class_session.class_session_no)
      redirect_to url, notice: I18n.t("select_class_session.BEA_MAT_ALL_SELECTCLASSSESSIONBEAN_ERROR1")
    else
      render action: :show
    end
  end

  def update
    @course = @class_session.course
    @class_session.assign_attributes(class_session_params)
    if class_session_valid? && @class_session.save
      url = url_for(:action => :show, :course_id => @course, :session_no => @class_session.class_session_no)
      redirect_to url, notice: I18n.t("select_class_session.BEA_MAT_ALL_SELECTCLASSSESSIONBEAN_ERROR1")
    else
      render action: :show
    end
  end

  def assign
    ActiveRecord::Base.transaction do
      @class_session = @course.class_session(params[:session_no])
      if @class_session.nil?
        @class_session = ClassSession.new
        @class_session.course_id = @course.id
        @class_session.class_session_day = I18n.t("common.COMMON_COUNTFORM", :param0 => params[:session_no])
        @class_session.class_session_no = params[:session_no]
        @class_session.save!
      end

      params["allocation"].each do |key, value|
        @assigned = GenericPageClassSessionAssociation.where(:class_session_id => @class_session.id, :generic_page_id => key).first
        if value["assign"] == "0"
          @assigned.destroy! if @assigned
        else
          unless @assigned
            @assigned = GenericPageClassSessionAssociation.new
            @assigned.class_session_id = @class_session.id
            @assigned.generic_page_id = key
          end

          if value["view_rank"].blank?
            @assigned.view_rank = 0
          else
            @assigned.view_rank = value["view_rank"]
          end
          @assigned.save!
        end
      end
    end
    render action: :show

  rescue => e
    if @assigned && @assigned.errors.count > 0
      @assigned.errors.messages.each do |key, msg|
        flash.now[:notice] = msg.join("")
        break
      end
    else
      logger.error e.backtrace.join("\n")
      flash.now[:notice] = e.message
    end
    render action: :show

  end

  def confirm
    @class_session = @course.class_session(params[:session_no])
  end

  private
    def set_class_session
      @class_session = ClassSession.find(params[:id])
    end

    def class_session_params
      params.require(:class_session).permit(:class_session_title, :class_session_day,
        :overview, :class_session_memo_closed, :class_session_memo, :class_session_no)
    end

    def class_session_valid?
      params = class_session_params
      if params[:class_session_title].blank?
        flash[:notice] = I18n.t("select_class_session.BEA_MAT_ALL_SELECTCLASSSESSIONBEAN_ERROR3")
        return false
      end
      if params[:class_session_no].to_i > 0 && params[:class_session_day].blank?
        flash[:notice] = I18n.t("select_class_session.BEA_MAT_ALL_SELECTCLASSSESSIONBEAN_ERROR4")
        return false
      end
      if params[:class_session_memo_closed].size > 4096
        flash[:notice] = I18n.t("select_class_session.MAT_ALL_SELECTCLASSSESSION_CLASSSESSIONOVERVIEWERROR1")
        return false
      end
      if params[:class_session_memo].size > 4096
        flash[:notice] = I18n.t("select_class_session.MAT_ALL_SELECTCLASSSESSION_CLASSSESSIONOVERVIEWERROR2")
        return false
      end

      return true
    end
end
