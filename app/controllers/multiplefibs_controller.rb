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

require 'nkf'

class MultiplefibsController < ApplicationController
  before_action :require_enrolled_or_open_assigned, only: [:show, :quiz, :password]
  before_action :require_enrolled, only: [:mark]
  before_action :set_generic_page, only: [:show, :quiz, :mark, :password]

  def show
    create_access_log(@generic_page.course.id)

    @latest_score = @generic_page.latest_score(current_user.id)
    @execution_count = get_execution_count(@latest_score, false)

    if @generic_page.not_ready?
      @message = I18n.t("execution.MAT_EXE_MUL_ERROREXECUTEMULTIPLEFIB_NOTREADYSTARTTIME_html", :param0 => I18n.l(@generic_page.start_time))
      render "error"
      return
    end

    if @generic_page.passed?(current_user.id)
    elsif !@generic_page.valid_term?
      @message = I18n.t("execution.MAT_EXE_MUL_ERROREXECUTEMULTIPLEFIB_ALREADYPASSEDENDTIME_html", :param0 => I18n.l(@generic_page.end_time))
      render "error"
    elsif @latest_score && @latest_score.answer_count >= @generic_page.max_count
      @message = I18n.t("execution.MAT_EXE_MUL_ERROREXECUTEMULTIPLEFIB_ALREADYEXAMEDMAXCOUNT_html", :param0 => @generic_page.max_count)
    else
      @execution_count = get_execution_count(@latest_score)

      if !(@generic_page.start_pass.blank? || session[:multiplefib_start_pass_flag])
        render "password"
      end
    end
  end

  def quiz
    @is_view_only = params[:view_only]
    template = "quiz"

    @latest_score = @generic_page.latest_score(current_user.id)

    if @generic_page.passed?(current_user.id)
      @score = @generic_page.latest_score(current_user.id)
      template = "result"
    elsif !@generic_page.valid_term?
      template = "redirect"
    elsif @latest_score && @latest_score.answer_count >= @generic_page.max_count
      @score = @generic_page.latest_score(current_user.id)
      template = "result"
    elsif !(@generic_page.start_pass.blank? || session[:multiplefib_start_pass_flag])
      template = "redirect"
    end

    render template, :layout => "content_only"
  end

  def mark
    @latest_score = @generic_page.latest_score(current_user.id)
    
    if !@generic_page.valid_term? || (@latest_score && @latest_score.answer_count >= @generic_page.max_count)
      render "redirect", :layout => "content_only"
      return
    elsif params[:answer].blank?
      redirect_to :action => :quiz, :id => @generic_page
      return
    else
      total_score = 0
      mark_score = 0
      @your_scores = {}

      @generic_page.parent_questions.each do |parent|
        ## 順不同、完全解答コードが両方ある時
        full_cds = Question.where("random_cd IS NOT NULL AND answer_in_full_cd IS NOT NULL AND parent_question_id = ?", parent.id).
          select("answer_in_full_cd").distinct
        full_cds.each do |full_cd|
          count = 0
          score = 0
          answer_scores = {}
          questions = Question.where("random_cd IS NOT NULL AND answer_in_full_cd IS NOT NULL AND answer_in_full_cd = ? AND parent_question_id = ?", full_cd.answer_in_full_cd, parent.id)
          answerd_questions = []
          user_answers = []
          questions.each.with_index do |question, index|
            if index == 0
              total_score += question.score
              score += question.score
            end
            user_answers << full_to_half(params[:answer][question.id.to_s])
          end
          user_answers.each do |user_answer|
            questions.each do |question|
              next if answerd_questions.include?(question.id)

              if user_answer == question.answer_memo
                count += 1
                answerd_questions << question.id
                answer_scores[question.id] = question.score
              end
            end
          end
          if count == questions.count
            mark_score += score
            @your_scores = answer_scores
          end
        end

        ## 順不同コードのみある時
        questions = parent.questions.where("random_cd IS NOT NULL AND answer_in_full_cd IS NULL")
        answerd_questions = []
        user_answers = []
        questions.each do |question|
          total_score += question.score
          user_answers << full_to_half(params[:answer][question.id.to_s])
        end
        user_answers.each do |user_answer|
          questions.each do |question|
            next if answerd_questions.include?(question.id)
            if user_answer == question.answer_memo
              mark_score += question.score
              answerd_questions << question.id
              @your_scores[question.id] = question.score
            end
          end
        end

        ## 完全解答コードのみある時
        full_cds = Question.where("random_cd IS NULL AND answer_in_full_cd IS NOT NULL AND parent_question_id = ?", parent.id).
          select("answer_in_full_cd").distinct
        full_cds.each do |full_cd|
          count = 0
          score = 0
          answer_scores = {}
          questions = Question.where("random_cd IS NULL AND answer_in_full_cd IS NOT NULL AND answer_in_full_cd = ? AND parent_question_id = ?", full_cd.answer_in_full_cd, parent.id)
          questions.each.with_index do |question, index|
            if index == 0
              total_score += question.score
              score += question.score
            end
            user_answer = full_to_half(params[:answer][question.id.to_s])
            unless user_answer.nil?
              if user_answer.to_s == question.answer_memo
                count += 1
                answer_scores[question.id] = question.score
              end
            end
          end
          if count == questions.count
            mark_score += score
            @your_scores = answer_scores
          end
        end

        ## 順不同、完全解答コードが両方ない時
        parent.questions.where("random_cd IS NULL AND answer_in_full_cd IS NULL").each do |question|
          total_score += question.score
          user_answer = full_to_half(params[:answer][question.id.to_s])
          unless user_answer.nil?
            if user_answer == question.answer_memo
              mark_score += question.score
              @your_scores[question.id] = question.score
            end
          end
        end
      end

      ## 100点換算する
      if mark_score > 0
        score_p = (mark_score * 100 / total_score).to_i
      else
        score_p = 0
      end

      if score_p < @generic_page.pass_grade
        pass_cd = Settings.ANSWERSCORE_PASSCD_UNSUBMITTING
      else
        pass_cd = Settings.ANSWERSCORE_PASSCD_SUBMITTED
      end

      ## 学生の時はDBに登録する
      if current_user.student?
        @score = @generic_page.latest_score(current_user.id)
        if @score.blank?
          @score = AnswerScore.new(:page_id => @generic_page.id, :user_id => current_user.id, :answer_count => 1)
        else
          @score.answer_count = @score.answer_count + 1
        end
        @score.total_score = score_p
        @score.pass_cd = pass_cd
        @score.effective_date = Time.zone.now
        @score.save!
      else
        @score = AnswerScore.new
        @score.answer_count = 1
        @score.total_score = score_p
        @score.effective_date = Time.zone.now
      end
    end
    render :layout => "content_only"
  end

  def password
    if params[:start_pass].blank?
      @message = I18n.t("execution.COMMONMATERIALSEXECUTION_STARTPASSWORDCHECK1")
    elsif params[:start_pass] == @generic_page.start_pass
      session[:multiplefib_start_pass_flag] = true
      redirect_to :action => :show, :id => @generic_page
    else
      @message = I18n.t("execution.COMMONMATERIALSEXECUTION_STARTPASSWORDCHECK2")
      @execution_count = get_execution_count(@generic_page.latest_score(current_user.id))
      render "password"
    end
  end

  def clear_password
    session[:multiplefib_start_pass_flag] = nil
    head :no_content
  end

  private
    def set_generic_page
      @generic_page = Multiplefib.find_by(id: params[:id], type_cd: Settings.GENERICPAGE_TYPECD_MULTIPLEFIBCODE)
    end

    def full_to_half(value)
      NKF.nkf('-w -x -Z4', value) if value
    end

    def get_execution_count(latest_score, is_increment = true)
      execution_count = 1

      ## 最新の解答結果を取得
      if latest_score.present?
        if latest_score.total_score == Settings.ANSWERSCORE_TMP_SAVED_SCORE
          execution_count = latest_score.answer_count
        elsif is_increment
          execution_count = latest_score.answer_count + 1
        else
          execution_count = latest_score.answer_count
        end
      end

      execution_count
    end
end
