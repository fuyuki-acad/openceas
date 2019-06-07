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

class Teacher::EssayQuestionsController < ApplicationController
  before_action :set_generic_page, only: [:show, :create, :update, :destroy, :confirm]
  before_action :set_question, only: [:update, :destroy]

  def show
    @question = Question.new
  end

  def create
    @question = Question.new(question_params)
    @question.pattern_cd = Settings.QUESTION_PATTERNCD_ASSIGNMENTESSAY
    @question.shuffle_flag = Settings.QUESTION_SHUFFLEFLG_OFF
    if @question.save
      @generic_page.questions << @question
      redirect_to action: :show, :generic_page_id => @generic_page
    else
      render action: :show
    end
  end

  def update
    content = nil
    params[:question].each do |index, question|
      content = question['content']
      break
    end

    @question.content = content
    if @question.save
      redirect_to action: :show, :generic_page_id => params[:generic_page_id]
    else
      @question.content = ""
      render action: :show
    end
  end

  def destroy
    if @question.destroy
      redirect_to action: :show, :generic_page_id => params[:generic_page_id]
    else
      render action: :show
    end
  end

  def confirm
  end

  private
    def set_generic_page
      @generic_page = GenericPage.find(params[:generic_page_id])
    end

    def set_question
      @question = Question.find(params[:id])
    end

    def question_params
      params.require(:question).permit(:content)
    end
end
