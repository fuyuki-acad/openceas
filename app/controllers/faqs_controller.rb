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
  before_action :set_course, only: [:course, :new]

  def index
    if current_user.admin?
      @faq_answers = FaqAnswer.order("faq_answers.updated_at desc").joins({:faq => :course}).where("open_flag = ? AND response_flag = ?", true, true)
    elsif current_user.teacher?
      @faq_answers = FaqAnswer.order("faq_answers.updated_at desc").joins({:faq => {:course => :course_assigned_users}}).where("course_assigned_users.user_id = ? AND open_flag = ? AND response_flag = ?", current_user.id, true, true)
    else
      @faq_answers = FaqAnswer.order("faq_answers.updated_at desc").joins({:faq => {:course => :course_enrollment_users}}).where("course_enrollment_users.user_id = ? AND open_flag = ? AND response_flag = ?", current_user.id, true, true)
    end
  end

  def show
    @faq_answer = FaqAnswer.find(params[:course_id])
  end

  def course
    @not_answers = Faq.eager_load(:faq_answers).where("course_id = ? AND user_id = ? AND faq_answers.id IS NULL", @course.id, current_user.id).order("faqs.updated_at desc")
    @answers = FaqAnswer.joins({:faq => :course}).where("faqs.course_id = ? AND faqs.open_flag = ?", @course.id, true).order("faqs.updated_at desc")
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
end
