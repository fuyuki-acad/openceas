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

class Teacher::FaqsController < ApplicationController
  before_action :require_assigned, only: [:show, :replied, :edit, :confirm, :update, :replied]
  before_action :set_courses, only: [:index]
  before_action :set_course, only: [:show, :replied]
  before_action :set_faq, only: [:edit, :confirm, :update, :replied]

  def edit
    if params[:back] && session[:faq]
      @faq.assign_attributes(session[:faq])
      session[:faq] = nil
    else
      if @faq.faq_answer.nil?
        @faq.faq_answer_attributes = FaqAnswer.new(:answer_title => "Re:", :open_question => @faq.question)
      else
        @faq.faq_answer_attributes = @faq.faq_answer
      end
    end
  end

  def confirm
    @faq.assign_attributes(faq_params)
    if @faq.valid?
      session[:faq] = faq_params
    else
      render action: :edit
    end
  end

  def update
    response_flag = @faq.response_flag
    @faq.response_flag = Settings.FAQ_RESPONSEFLG_REPLIED
    ActiveRecord::Base.transaction do
      @faq.update_attributes!(session[:faq])
      if response_flag == Settings.FAQ_RESPONSEFLG_UNREPLY
        FaqMailer.answer(@faq.faq_answer, @faq.user).deliver_now

        @faq.course.assigned_users.each do |user|
          FaqMailer.answer(@faq.faq_answer, user).deliver_now
        end
      end
      session[:faq] = nil
      redirect_to action: :show, :course_id => @faq.course_id
    end

  rescue => e
    logger.error e.backtrace.join("\n")
    @faq.response_flag = response_flag
    flash.now[:notice] = e.message
    render action: :edit
  end

  def replied
    ActiveRecord::Base.transaction do
      @faq.open_flag = Settings.COURSE_OPENCOURSEFAQFLG_OFF
      @faq.response_flag = Settings.FAQ_RESPONSEFLG_REPLIED
      @faq.save!
      answer = FaqAnswer.new
      answer.faq_id = @faq.id
      answer.answer_title = @faq.faq_title
      answer.answer = I18n.t("faq.COMMONFAQ_SEPARATEANSWERED")
      answer.open_answer = ""
      answer.open_question = ""
      answer.insert_user_id = current_user.id
      answer.save!
    end
    redirect_to teacher_faq_path(@faq.course_id)

  rescue => e
    logger.error e.backtrace.join("\n")
    redirect_to teacher_faq_path(@faq.course_id), :notice => e.message
  end

  def destroy
    items = params[:faq].keys if params[:faq]
    items.each do |item|
      course = Course.joins(:faqs).where("faqs.id = ?", item).first
      must_be_assigned(course)
    end
    Faq.destroy(items)

    redirect_to :action => :show, :course_id => params[:course_id]
  end

  private
    def set_faq
      @faq = Faq.find(params[:id])
    end

    def faq_params
      params.require(:faq).permit(:open_flag,
        :faq_answer_attributes => [:id, :answer_title, :answer, :open_question, :open_answer])
    end
end
