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

class FaqsController < ApplicationController
  before_action :require_enrolled_or_open_assigned, only: [:course, :new]
  before_action :set_course, only: [:course, :new]
  before_action :permited_open_course, only: [:course, :new]

  def index
    sql_texts = []
    sql_params = {}

    if !params[:keyword].blank?
      sql_texts.push("courses.course_name like :keyword or faq_answers.open_question like :keyword or faq_answers.open_answer like :keyword")
      sql_params[:keyword] = "%" + params[:keyword] + "%"
    end

    sql_texts.push("faqs.open_flag = :open_flag AND faqs.response_flag = :response_flag")
    sql_params[:open_flag] = true
    sql_params[:response_flag] = true

    if current_user.admin?
      @faq_answers = FaqAnswer.order("faq_answers.updated_at desc").joins({:faq => :course}).where(sql_texts.join(" AND "), sql_params)

    elsif current_user.teacher?
      sql_texts.push("course_assigned_users.user_id = :user_id")
      sql_params[:user_id] = current_user.id

      @faq_answers = FaqAnswer.order("faq_answers.updated_at desc").joins({:faq => {:course => :course_assigned_users}}).where(sql_texts.join(" AND "), sql_params)

    else
      sql_texts.push("course_enrollment_users.user_id = :user_id")
      sql_params[:user_id] = current_user.id

      @faq_answers = FaqAnswer.order("faq_answers.updated_at desc").joins({:faq => {:course => :course_enrollment_users}}).where(sql_texts.join(" AND "), sql_params)
    end
  end

  def show
    @faq_answer = FaqAnswer.find(params[:course_id])
  end

  def course
    @not_answers = Faq.eager_load(:faq_answers).
      where("course_id = ? AND user_id = ? AND faq_answers.id IS NULL", @course.id, current_user.id).
      order("faqs.updated_at desc")
    @answers = FaqAnswer.joins({:faq => :course}).
      where("faqs.course_id = ? AND faqs.open_flag = ?", @course.id, true).
      order("faqs.updated_at desc")
    @closed_answers = FaqAnswer.joins({:faq => :course}).
      where("faqs.course_id = ? AND faqs.open_flag = ? AND faqs.user_id = ?", @course.id, false, current_user.id).
      order("faqs.updated_at desc")
  end

  def new
    if params[:back] && session[:faq]
      @faq = Faq.new(session[:faq])
      session[:faq] = nil
    else
      @faq = Faq.new
      @faq.course = @course
    end
  end

  def confirm
    @faq = Faq.new(faq_params)
    @faq.user_id = current_user.id
    if @faq.valid?
      session[:faq] = faq_params
    else
      @course = @faq.course
      render action: :new
    end
  end

  def create
    @faq = Faq.new(session[:faq])
    @faq.open_flag = Settings.FAQ_OPENFLG_PRIVATE
    @faq.response_flag = Settings.FAQ_RESPONSEFLG_UNREPLY
    @faq.user_id = current_user.id
    if @faq.save
      @faq.course.assigned_users.each do |user|
        FaqMailer.question(@faq, user).deliver_now
      end

      session[:faq] = nil
      redirect_to faq_course_path(@faq.course), :notice => I18n.t("faq.FAQ_OPENFAQLIST_SCRIPT")
    else
      render action: :new
    end
  end

  private
    def faq_params
      params.require(:faq).permit(:course_id, :faq_title, :question)
    end

    def permited_open_course
      if @course.open_course_flag == Settings.COURSE_OPENCOURSEFLG_PUBLIC
        if @course.announcement_cd != Settings.COURSE_ANNOUNCEMENTCD_NORMAL ||
           @course.open_course_announcement_flag != Settings.COURSE_OPENCOURSEANNOUNCEMENTFLG_ON
          raise Forbidden
        end
      else
        if @course.announcement_cd != Settings.COURSE_ANNOUNCEMENTCD_NORMAL
         raise Forbidden
       end
     end
    end

  end
