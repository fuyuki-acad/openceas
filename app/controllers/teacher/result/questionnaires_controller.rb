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

require 'csv'

class Teacher::Result::QuestionnairesController < ApplicationController
  before_action :require_assigned, only: [:show, :bulk_outputcsv, :bulk_outputcsv_user,
    :result, :outputcsv, :outputcsv_user, :detail_outputcsv]
  before_action :set_courses, only: [:index]
  before_action :set_course, only: [:show, :bulk_outputcsv, :bulk_outputcsv_user]
  before_action :set_generic_page, only: [:result, :outputcsv, :outputcsv_user, :detail_outputcsv]

  def show
    @questionnaires = @course.questionnaires.joins(:class_sessions)
  end

  def result
  end

  def detail
    @question = Question.find(params[:id])
    @generic_page = @question.parent.generic_pages.first
    @other_answers = []

    if @generic_page.anonymous_flag == Settings.GENERICPAGE_ANONYNOUSFLG_ON
      users = User.joins(:answer_scores).where("answer_scores.page_id = ?", @generic_page.id).order("answer_scores.created_at")
    else
      users = User.joins(:enrollment_courses => :questionnaires).where("generic_pages.id = ?", @generic_page.id)
    end

    if @question.pattern_cd == Settings.QUESTION_PATTERNCD_ESSAY
      users.each do |user|
        score = AnswerScore.where("page_id = ? AND user_id = ?", @generic_page.id, user.id).order("answer_count DESC").first
        if score && score.total_score > -1
          answer = @question.answers.where("user_id = ? AND answer_count = ?", user.id, score.answer_count).first
          if answer
            @other_answers << answer
          end
        end
      end
    else
      users.each do |user|
        score = AnswerScore.where("page_id = ? AND user_id = ?", @generic_page.id, user.id).order("answer_count DESC").first
        if score && score.total_score > -1
          answer = @question.answers.where("user_id = ? AND answer_count = ? AND select_answer_id = ?", user.id, score.answer_count, Answer::OTHER_ANSWER_ID).first
          if answer
            @other_answers << answer
          end
        end
      end
    end
  end

  def bulk_outputcsv
    bom = %w(EF BB BF).map { |e| e.hex.chr }.join
    csv_data = CSV.generate(bom) do |csv|

      @course.questionnaires.each do |generic_page|
        csv << ["#{I18n.t('materials_administration.MAT_ADM_ASS_ASSIGNMENTESSAYTOTALRESULT_CSVCOLUMN1')}#{generic_page.course.course_name}"]
        csv << ["#{I18n.t('materials_administration.PRE_BEA_MAT_ADM_QUE_ADMINISTRATEQUESTIONNAIREBEAN_CSVCOLUMN1')}#{generic_page.generic_page_title}"]

        generic_page.parent_questions.each do |parent_question|
          csv << ["#{I18n.t('materials_administration.PRE_BEA_MAT_ADM_QUE_ADMINISTRATEQUESTIONNAIREBEAN_CSVCOLUMN2')}#{parent_question.content.html_safe}"]
          parent_question.questions.each do |question|

            csv << ["#{I18n.t('materials_administration.PRE_BEA_MAT_ADM_QUE_ADMINISTRATEQUESTIONNAIREBEAN_CSVCOLUMN3')}#{question.content.html_safe}"]
            generic_page.course.enrolled_users.each do |user|
              line = []
              line << I18n.t('common.COMMON_TARGETNAME')
              line << I18n.t('materials_administration.PRE_BEA_MAT_ADM_QUE_ADMINISTRATEQUESTIONNAIREBEAN_CSVCOLUMN4')
              line << I18n.t('materials_administration.PRE_BEA_MAT_ADM_QUE_ADMINISTRATEQUESTIONNAIREBEAN_CSVCOLUMN5')
              line << I18n.t('materials_administration.PRE_BEA_MAT_ADM_QUE_ADMINISTRATEQUESTIONNAIREBEAN_CSVCOLUMN6')
              csv << line

              line = []
              if generic_page.anonymous_flag == Settings.GENERICPAGE_ANONYNOUSFLG_ON
                line << "****"
              else
                line << user.get_name_no_prefix + user.user_name
              end

              answer_date = ""
              select_content = ""
              text_answer = ""

              latest_score = generic_page.latest_score(user.id)
              if latest_score && latest_score.total_score > -1
                answers = question.answers.where(:user_id => user.id, :answer_count => latest_score.answer_count)
                if answers.first
                  select_content = get_select_content(question, answers)
                  answers.each do |answer|
                    answer_date = I18n.l(answer.created_at, format: :short) if answer_date.blank? && !answer.created_at.blank?
                    text_answer = answer.text_answer.html_safe unless answer.text_answer.blank?
                  end
                end
              end

              line << select_content
              line << text_answer
              line << answer_date

              csv << line
            end
          end
        end
      end
    end

#    send_data csv_data, filename: "#{I18n.t('materials_administration.MAT_ADM_COM_ADMINISTRATECOMPOUND_CSVFILENAME')}.csv"
    send_data csv_data, filename: "questionnaire.csv"
  end

  def bulk_outputcsv_user
    bom = %w(EF BB BF).map { |e| e.hex.chr }.join

    csv_data = CSV.generate(bom) do |csv|
      @course.questionnaires.each do |generic_page|
        csv << ["#{I18n.t('materials_administration.MAT_ADM_ASS_ASSIGNMENTESSAYTOTALRESULT_CSVCOLUMN1')}#{generic_page.course.course_name}"]
        csv << ["#{I18n.t('materials_administration.PRE_BEA_MAT_ADM_QUE_ADMINISTRATEQUESTIONNAIREBEAN_CSVCOLUMN1')}#{generic_page.generic_page_title}"]

        # 大門
        line = []
        line << I18n.t('materials_administration.PRE_BEA_MAT_ADM_QUE_ADMINISTRATEQUESTIONNAIREBEAN_CSVCOLUMN2')
        line << ""
        generic_page.parent_questions.each do |parent_question|
          line << parent_question.content.html_safe
          line << ""
          parent_question.questions.each.with_index do |question, index|
            if index > 0
              line << ""
              line << ""
            end
          end
        end
        csv << line

        # 設問
        line = []
        line << I18n.t('materials_administration.PRE_BEA_MAT_ADM_QUE_ADMINISTRATEQUESTIONNAIREBEAN_CSVCOLUMN3')
        line << ""
        generic_page.parent_questions.each.with_index do |parent_question, index|
          parent_question.questions.each do |question|
            line << question.content.html_safe
            line << ""
          end
        end
        csv << line

        # ヘッダー
        line = []
        line << I18n.t('common.COMMON_TARGETNAME')
        line << I18n.t('materials_administration.PRE_BEA_MAT_ADM_QUE_ADMINISTRATEQUESTIONNAIREBEAN_CSVCOLUMN6')
        generic_page.parent_questions.each do |parent_question|
          parent_question.questions.each do |question|
            line << I18n.t('materials_administration.PRE_BEA_MAT_ADM_QUE_ADMINISTRATEQUESTIONNAIREBEAN_CSVCOLUMN4')
            line << I18n.t('materials_administration.PRE_BEA_MAT_ADM_QUE_ADMINISTRATEQUESTIONNAIREBEAN_CSVCOLUMN5')
          end
        end
        csv << line

        generic_page.course.enrolled_users.each do |user|
          line = []
          if generic_page.anonymous_flag == Settings.GENERICPAGE_ANONYNOUSFLG_ON
            line << "****"
          else
            line << user.get_name_no_prefix + user.user_name
          end

          answer_date = ""
          answers_data = []
          generic_page.parent_questions.each do |parent_question|
            parent_question.questions.each do |question|

              select_content = ""
              text_answer = ""

              latest_score = generic_page.latest_score(user.id)
              if latest_score && latest_score.total_score > -1
                answers = question.answers.where(:user_id => user.id, :answer_count => latest_score.answer_count)
                if answers.first
                  select_content = get_select_content(question, answers)
                  answers.each do |answer|
                    answer_date = I18n.l(answer.created_at, format: :short) if answer_date.blank? && !answer.created_at.blank?
                    text_answer = answer.text_answer.html_safe unless answer.text_answer.blank?
                  end
                end
              end

              answers_data << select_content
              answers_data << text_answer
            end
          end
          line << answer_date
          line << answers_data

          csv << line.flatten
        end
      end
    end

    send_data csv_data, filename: "questionnaire.csv"
  end

  def outputcsv
    bom = %w(EF BB BF).map { |e| e.hex.chr }.join
    csv_data = CSV.generate(bom) do |csv|
      csv << ["#{I18n.t('materials_administration.MAT_ADM_ASS_ASSIGNMENTESSAYTOTALRESULT_CSVCOLUMN1')}#{@generic_page.course.course_name}"]
      csv << ["#{I18n.t('materials_administration.PRE_BEA_MAT_ADM_QUE_ADMINISTRATEQUESTIONNAIREBEAN_CSVCOLUMN1')}#{@generic_page.generic_page_title}"]
      @generic_page.parent_questions.each do |parent_question|
        csv << ["#{I18n.t('materials_administration.PRE_BEA_MAT_ADM_QUE_ADMINISTRATEQUESTIONNAIREBEAN_CSVCOLUMN2')}#{parent_question.content.html_safe}"]
        parent_question.questions.each do |question|
          csv << ["#{I18n.t('materials_administration.PRE_BEA_MAT_ADM_QUE_ADMINISTRATEQUESTIONNAIREBEAN_CSVCOLUMN3')}#{question.content.html_safe}"]

          @generic_page.course.enrolled_users.each do |user|
            line = []
            line << I18n.t('common.COMMON_TARGETNAME')
            line << I18n.t('materials_administration.PRE_BEA_MAT_ADM_QUE_ADMINISTRATEQUESTIONNAIREBEAN_CSVCOLUMN4')
            line << I18n.t('materials_administration.PRE_BEA_MAT_ADM_QUE_ADMINISTRATEQUESTIONNAIREBEAN_CSVCOLUMN5')
            line << I18n.t('materials_administration.PRE_BEA_MAT_ADM_QUE_ADMINISTRATEQUESTIONNAIREBEAN_CSVCOLUMN6')
            csv << line

            line = []
            if @generic_page.anonymous_flag == Settings.GENERICPAGE_ANONYNOUSFLG_ON
              line << "****"
            else
              line << user.get_name_no_prefix + user.user_name
            end

            answer_date = ""
            select_content = ""
            text_answer = ""

            latest_score = @generic_page.latest_score(user.id)
            if latest_score && latest_score.total_score > -1
              answers = question.answers.where(:user_id => user.id, :answer_count => latest_score.answer_count)
              if answers.first
                select_content = get_select_content(question, answers)
                answers.each do |answer|
                  answer_date = I18n.l(answer.created_at, format: :short) if answer_date.blank? && !answer.created_at.blank?
                  text_answer = answer.text_answer.html_safe unless answer.text_answer.blank?
                end
              end
            end

            line << select_content
            line << text_answer
            line << answer_date

            csv << line
          end
        end
      end
    end

#    send_data csv_data, filename: "#{I18n.t('materials_administration.MAT_ADM_COM_ADMINISTRATECOMPOUND_CSVFILENAME')}.csv"
    send_data csv_data, filename: "questionnaire.csv"
  end

  def outputcsv_user
    bom = %w(EF BB BF).map { |e| e.hex.chr }.join
    csv_data = CSV.generate(bom) do |csv|
      csv << ["#{I18n.t('materials_administration.MAT_ADM_ASS_ASSIGNMENTESSAYTOTALRESULT_CSVCOLUMN1')}#{@generic_page.course.course_name}"]
      csv << ["#{I18n.t('materials_administration.PRE_BEA_MAT_ADM_QUE_ADMINISTRATEQUESTIONNAIREBEAN_CSVCOLUMN1')}#{@generic_page.generic_page_title}"]

      # 大門
      line = []
      line << I18n.t('materials_administration.PRE_BEA_MAT_ADM_QUE_ADMINISTRATEQUESTIONNAIREBEAN_CSVCOLUMN2')
      line << ""
      @generic_page.parent_questions.each do |parent_question|
        line << parent_question.content.html_safe
        line << ""
        parent_question.questions.each.with_index do |question, index|
          if index > 0
            line << ""
            line << ""
          end
        end
      end
      csv << line

      # 設問
      line = []
      line << I18n.t('materials_administration.PRE_BEA_MAT_ADM_QUE_ADMINISTRATEQUESTIONNAIREBEAN_CSVCOLUMN3')
      line << ""
      @generic_page.parent_questions.each.with_index do |parent_question, index|
        parent_question.questions.each do |question|
          line << question.content.html_safe
          line << ""
        end
      end
      csv << line

      # ヘッダー
      line = []
      line << I18n.t('common.COMMON_TARGETNAME')
      line << I18n.t('materials_administration.PRE_BEA_MAT_ADM_QUE_ADMINISTRATEQUESTIONNAIREBEAN_CSVCOLUMN6')
      @generic_page.parent_questions.each do |parent_question|
        parent_question.questions.each do |question|
          line << I18n.t('materials_administration.PRE_BEA_MAT_ADM_QUE_ADMINISTRATEQUESTIONNAIREBEAN_CSVCOLUMN4')
          line << I18n.t('materials_administration.PRE_BEA_MAT_ADM_QUE_ADMINISTRATEQUESTIONNAIREBEAN_CSVCOLUMN5')
        end
      end
      csv << line

      @generic_page.course.enrolled_users.each do |user|
        line = []
        if @generic_page.anonymous_flag == Settings.GENERICPAGE_ANONYNOUSFLG_ON
          line << "****"
        else
          line << user.get_name_no_prefix + user.user_name
        end

        answer_date = ""
        answers_data = []
        @generic_page.parent_questions.each.with_index do |parent_question, index|
          parent_question.questions.each do |question|

            select_content = ""
            text_answer = ""

            latest_score = @generic_page.latest_score(user.id)
            if latest_score && latest_score.total_score > -1
              answers = question.answers.where(:user_id => user.id, :answer_count => latest_score.answer_count)
              if answers.first
                select_content = get_select_content(question, answers)
                answers.each do |answer|
                  answer_date = I18n.l(answer.created_at, format: :short) if answer_date.blank? && !answer.created_at.blank?
                  text_answer = answer.text_answer.html_safe unless answer.text_answer.blank?
                end
              end
            end

            answers_data << select_content
            answers_data << text_answer
          end
        end
        line << answer_date
        line << answers_data

        csv << line.flatten
      end
    end

    send_data csv_data, filename: "questionnaire.csv"
  end

  def get_select_content(question, answers)
    content = ""

    case question.pattern_cd
    when Settings.QUESTION_PATTERNCD_RADIO,
         Settings.QUESTION_PATTERNCD_ONELIST

        answers.each do |answer|
          question.all_quizzes.each.with_index(1) do |quiz, index|
            if quiz.id == answer.select_answer_id
              content = index
              break
            end
          end
        end

    when Settings.QUESTION_PATTERNCD_CHECK
      select_answers = []
      answers.each do |answer|
        question.all_quizzes.each.with_index(1) do |quiz, index|
          if quiz.id == answer.select_answer_id
            select_answers << index
            break
          end
        end
      end
      content = select_answers * " "
    end

    return content
  end

  def get_answer_count(question, user)
    answer = Answer.where(:question_id => question.id, :user_id => user.id).order('answer_count DESC').first
    return answer.answer_count unless answer.nil?
  end

  def detail_outputcsv
    bom = %w(EF BB BF).map { |e| e.hex.chr }.join
    csv_data = CSV.generate(bom) do |csv|
      csv << ["#{I18n.t('materials_administration.MAT_ADM_ASS_ASSIGNMENTESSAYTOTALRESULT_CSVCOLUMN1')}#{@generic_page.course.course_name}"]
      csv << ["#{I18n.t('materials_administration.PRE_BEA_MAT_ADM_QUE_ADMINISTRATEQUESTIONNAIREBEAN_CSVCOLUMN1')}#{@generic_page.generic_page_title}"]

      # 設問
      question = Question.where("id = ?", params[:question_id]).first
      line = []
      line << I18n.t('materials_administration.PRE_BEA_MAT_ADM_QUE_ADMINISTRATEQUESTIONNAIREBEAN_CSVCOLUMN3')
      line << question.content.html_safe
      csv << line

      # ヘッダー
      line = []
      line << I18n.t('common.COMMON_TARGETNAME')
      line << I18n.t('materials_administration.PRE_BEA_MAT_ADM_QUE_ADMINISTRATEQUESTIONNAIREBEAN_CSVCOLUMN5')
      line << I18n.t('materials_administration.PRE_BEA_MAT_ADM_QUE_ADMINISTRATEQUESTIONNAIREBEAN_CSVCOLUMN6')
      csv << line

      question.other_answers.each do |answer|
        line = []
        if @generic_page.anonymous_flag == Settings.GENERICPAGE_ANONYNOUSFLG_ON
          line << "****"
        else
          line << answer.user.get_name_no_prefix + answer.user.user_name
        end

        latest_score = @generic_page.latest_score(answer.user.id)
        if latest_score && latest_score.total_score > -1
          unless answer.text_answer.nil?
            line << answer.text_answer.html_safe
          else
            line << ""
          end
          line << I18n.l(answer.created_at, format: :short) if !answer.created_at.blank?
        else
          line << ""
          line << ""
        end
        csv << line
      end
    end

    send_data csv_data, filename: "questionnaire.csv"
  end

  private
    def set_generic_page
      @generic_page = GenericPage.find(params[:id])
    end
end
