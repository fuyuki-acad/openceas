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

class QuestionnairesController < ApplicationController
  skip_before_action :verify_authenticity_token, only: :confirm
  before_action :set_generic_page, only: [:show, :save, :confirm, :password]

  def show
    if params[:back] && session[:answers]
      @answers = session[:answers]
      session[:answers] = nil
    else
      create_access_log(@generic_page.course.id)

      session[:answers] = nil
      @answers = get_answers(@generic_page, current_user)
      latest_score = @generic_page.latest_score(current_user.id)
      if @generic_page.valid_term?
        if latest_score && !@generic_page.answer_saved?(current_user) && @generic_page.edit_flag != Settings.GENERICPAGE_EDITFLG_ON
          render "confirm"
          return
        end
      else
        render "error"
        return
      end
    end

    if !@generic_page.start_pass.blank? && !session[:questionnaire_start_pass_flag]
      render "password"
    end
  end

  def password
    if params[:start_pass].blank?
      flash.now[:notice] = I18n.t("execution.COMMONMATERIALSEXECUTION_STARTPASSWORDCHECK1")
    elsif params[:start_pass] == @generic_page.start_pass
      session[:questionnaire_start_pass_flag] = true
      redirect_to :action => :show, :id => @generic_page
    else
      flash.now[:notice] = I18n.t("execution.COMMONMATERIALSEXECUTION_STARTPASSWORDCHECK2")
    end
  end

  def save
    if session[:answers]
      @answers = session[:answers]
      total_score = 0
      validate_flg = true
    else
      @answers = params[:answers]
      total_score = Settings.ANSWERSCORE_TMP_SAVED_SCORE
      validate_flg = false
    end

    if current_user.student?
      ActiveRecord::Base.transaction do
        answer_score = @generic_page.answer_scores.where(:user_id => current_user.id, :answer_count => 1).first
        if answer_score
          answer_score.total_score = total_score
        else
          answer_score = AnswerScore.new(:page_id => @generic_page.id, :user_id => current_user.id, :answer_count => 1, :total_score => total_score, :pass_cd => 0)
        end
        answer_score.save!

        Answer.where(answer_score_id: answer_score.id).each do |answer|
          answer.destroy_historty(answer_score.answer_count)
          answer.delete
        end

        questions = Question.joins(
            "INNER JOIN questions AS parents ON parents.id = questions.parent_question_id" +
            " INNER JOIN generic_page_question_associations AS associations ON associations.question_id = parents.id"
          ).
          where("associations.generic_page_id = ?", answer_score.page_id)

        questions.each do |question|
          if @answers && @answers[question.id.to_s]
            value = @answers[question.id.to_s]
            if question.pattern_cd == Settings.QUESTION_PATTERNCD_CHECK
              value.each do |select_answer|
                if select_answer["select_answer_id"]
                  @answer = Answer.new(:question_id => question.id, :user_id => current_user.id, :answer_count => 1)
                  @answer.select_answer_id = select_answer["select_answer_id"]
                  @answer.text_answer = select_answer["text_answer"] if select_answer["select_answer_id"] == Answer::OTHER_ANSWER_ID
                  @answer.answer_score_id = answer_score.id
                  @answer.save!(validate: validate_flg)
                end
              end
            else
              unless question.pattern_cd != Settings.QUESTION_PATTERNCD_ESSAY && value["select_answer_id"].blank?
                @answer = Answer.new(:question_id => question.id, :user_id => current_user.id, :answer_count => 1)
                @answer.select_answer_id = value["select_answer_id"] ? value["select_answer_id"] : Answer::OTHER_ANSWER_ID
                @answer.text_answer = value["text_answer"] if value["text_answer"]
                @answer.answer_score_id = answer_score.id
                @answer.save!(validate: validate_flg)
              end
            end
          end
        end
      end
    end
    session[:answers] = nil
    if total_score == Settings.ANSWERSCORE_TMP_SAVED_SCORE
      flash[:notice] = I18n.t("execution.COMMONMATERIALSEXECUTION_TEMP_SAVE_DATE") + Time.zone.now.strftime('%Y/%m/%d') + I18n.t("execution.COMMONMATERIALSEXECUTION_TEMP_SAVE_SUCCESS")
      redirect_to :action => :show, :id => @generic_page
    else
      redirect_to :action => :finish
    end

  rescue => e
    if @answer && @answer.errors.count == 0
      logger.error e.backtrace.join("\n")
      flash.now[:notice] = e.message
    end
    render action: :show
  end

  def finish
  end

  def confirm
    @answers = {}
    if params[:answers]
      params[:answers].each do |key, values|
        @answer = Answer.new(:question_id => key, :user_id => current_user.id, :answer_count => 1)
        if @answer.question.pattern_cd == Settings.QUESTION_PATTERNCD_CHECK
          if @answer.question.must_flag == Settings.QUESTION_MUSTFLG_MUST
            selected_flg = false
            if values.instance_of?(Hash) && values["select_answer_id"].count > 0
              selected_flg = true
            elsif values.instance_of?(Array) && values.any? { |value| value["select_answer_id"] }
              selected_flg = true
            end
            if !selected_flg
              @answer.errors[:base] << '"' + @answer.question.content.html_safe + '"' + I18n.t("execution.MAT_EXE_QUE_EXECUTEQUESTIONNAIRE_ERROR1")
              @answers = params[:answers]
              render :action => :show
              return
            end
          end
          @answers[key] = []
          values.each do |value|
            if value["select_answer_id"]
              @answer.select_answer_id = value["select_answer_id"]
              @answer.text_answer = value["text_answer"] if value["select_answer_id"] == Answer::OTHER_ANSWER_ID && value["text_answer"]
              unless @answer.valid?
                @answers = params[:answers]
                render :action => :show
                return
              end
              @answers[key] << @answer
              @answer = Answer.new(:question_id => key, :user_id => current_user.id, :answer_count => 1)
            end
          end
        else
          @answer.select_answer_id = values["select_answer_id"] if values["select_answer_id"]
          @answer.text_answer = values["text_answer"] if values["text_answer"]
          unless @answer.valid?
            @answers = params[:answers]
            render :action => :show
            return
          end
          @answers[key] = @answer
        end
      end
      session[:answers] = params[:answers].to_unsafe_h
    else
      session[:answers] = {}
    end
  end

  def clear_password
    session[:questionnaire_start_pass_flag] = nil
    head :no_content
  end

  private
    def set_generic_page
      @generic_page = GenericPage.find_by(id: params[:id], type_cd: Settings.GENERICPAGE_TYPECD_QUESTIONNAIRECODE)
    end

    def get_answers(generic_page, user)
      answers = {}

      generic_page.parent_questions.each do |parent_question|
        parent_question.questions.eager_load(:answers).where(answers: {user_id: current_user.id}).each do |question|
          if question.pattern_cd == Settings.QUESTION_PATTERNCD_CHECK
            answers[question.id.to_s] = question.answers.map { |answer| answer }
          else
            answers[question.id.to_s] = question.answers.first
          end
        end
      end

      answers
    end
end
