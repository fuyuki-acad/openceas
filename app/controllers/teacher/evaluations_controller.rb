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

class Teacher::EvaluationsController < ApplicationController
  before_action :require_assigned, only: [
    :show, :new, :create, :select_course, :select_page, :copy,
    :edit, :update, :destroy_file]
  before_action :set_courses, only: [:index]
  before_action :set_course, only: [:show, :new, :create, :select_course, :select_page, :copy]
  before_action :set_generic_page, only: [:edit, :update, :destroy_file]

  def new
    @generic_page = GenericPage.new()
    @generic_page.course = @course
    @generic_page.type_cd = Settings.GENERICPAGE_TYPECD_EVALUATIONLISTCODE
    @generic_page.score_open_flag = Settings.GENERICPAGE_SCOREOPENFLG_OFF
  end

  def create
    @generic_page = GenericPage.new(generic_page_params)
    if @generic_page.save
      redirect_to action: :show, :course_id => @generic_page.course
    else
      render action: :new
    end
  end

  def update
    if @generic_page.update(generic_page_params)
      redirect_to action: :show, :course_id => @generic_page.course
    else
      render action: :edit
    end
  end

  def destroy
    items = params[:evaluation].keys if params[:evaluation]
    GenericPage.destroy(items)

    redirect_to :action => :show, :course_id => params[:course_id]
  end

  def select_course
    if current_user.admin?
      @other_courses = Course.order(VIEW_COUSE_ORER).
        where("courses.id != ? AND course_name LIKE ?", params[:course_id], "%#{params[:course_name]}%").
        page(params[:page])
    else
      @other_courses = Course.order(VIEW_COUSE_ORER).
        joins(:course_assigned_users).
        where("user_id = ? AND courses.id != ? AND course_name LIKE ?", current_user.id, params[:course_id], "%#{params[:course_name]}%").
        page(params[:page])
    end
  end

  def select_page
    @origin = Course.find(params[:origin_id])
  end

  def copy
    if params[:evaluation] && params[:evaluation].to_unsafe_h.count > 0
      ActiveRecord::Base.transaction do
        params[:evaluation].to_unsafe_h.keys.each do |compound|
          old_object = GenericPage.find(compound)
          new_object = old_object.copy(@course)
          new_object.save!
        end
      end

      redirect_to :action => :show, :course_id => params[:course_id]
    else
      redirect_to :action => :select_page, :course_id => params[:course_id], :origin_id => params[:origin_id]
    end

  rescue => e
    logger.error e.backtrace.join("\n")
    redirect_to teacher_select_page_evaluation_path(@generic_page.id, params[:origin_id]), notice: e.message
  end

  private
    def set_generic_page
      @generic_page = GenericPage.find(params[:id])
    end

    def generic_page_params
      params.require(:generic_page).permit(:course_id, :type_cd, :generic_page_title,
        :material_memo, :score_open_flag)
    end
end
