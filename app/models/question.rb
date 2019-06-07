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

class Question < ApplicationRecord
  include CustomValidationModule

  has_and_belongs_to_many :generic_pages, :join_table => :generic_page_question_associations
  has_many  :questions, -> { order('view_rank') }, :join_table => :questions, :foreign_key => :parent_question_id, :dependent => :destroy
  has_many  :essays, -> { where "pattern_cd = ?", Settings.QUESTION_PATTERNCD_ESSAY },
            :class_name => 'Question', :join_table => :questions, :foreign_key => :parent_question_id
  has_many  :answers
  has_many  :other_answers, -> { where "select_answer_id = ?", Answer::OTHER_ANSWER_ID}, :class_name => 'Answer'
  has_many  :answer_histories
  has_many  :select_quizzes, -> { where "text_row = 0" }
  has_many  :select_ohters, -> { where "text_row = 1" },
            :class_name => 'SelectQuiz', :join_table => :select_quizzes, :foreign_key => :question_id
  has_many  :all_quizzes, :dependent => :destroy,
            :class_name => 'SelectQuiz', :join_table => :select_quizzes, :foreign_key => :question_id
  has_many  :correct_values, -> { where "select_correct_flag = ?", Settings.SELECT_SELECTCORRECTFLG_CORRECT}, :class_name => 'SelectQuiz'
  belongs_to  :parent, :class_name => 'Question', :foreign_key => :parent_question_id, optional: true

  attr_accessor :text_count, :quizzes_attributes, :generic_page_type_cd, :correct_flag, :text_flag, :summary

  DEFAULT_SELECT_COUNT = 4
  MAX_SELECT_COUNT = 100
  MAX_ROWS = 60

  after_initialize do
    self.text_count = self.select_quizzes.count if self.text_count.blank?
    if self.select_ohters.count == 0
      self.text_flag = 0
    else
      self.text_flag = 1
    end
  end

  before_save do
    if self.new_record?
      self.insert_user_id = User.current_user.id
    end
    self.update_user_id = User.current_user.id
  end

  after_save do
    case self.pattern_cd
    when Settings.QUESTION_PATTERNCD_RADIO, Settings.QUESTION_PATTERNCD_ONELIST, Settings.QUESTION_PATTERNCD_CHECK
      ##self.select_quizzes.destroy_all if self.select_quizzes.count > 0

      if answers.count == 0
        if self.quizzes_attributes
          self.quizzes_attributes.each do |key, sel|
            if sel[:id].blank?
              quiz = SelectQuiz.new(sel)
            else
              quiz = SelectQuiz.find(sel[:id])
              quiz.assign_attributes(sel)
            end
            unless quiz && quiz.content.blank?
              self.select_quizzes << quiz
              throw(:abort) unless quiz.save
            end
          end

          #その他
          if self.text_flag.to_i == 1
            if self.select_ohters.count == 0
              quiz = SelectQuiz.new(:content => I18n.t("common.COMMON_OTHER"), :text_row => 1)
              self.select_quizzes << quiz
              throw(:abort) unless quiz.save
            end
          else
            if self.select_ohters.count > 0
              self.select_ohters.first.destroy
            end
          end
        end
      end
    end
  end

  before_destroy do
    if answers.count > 0
      raise I18n.t("materials_registration.COMMONMATERIALSREGISTRATION_CANNOTDELETEEXAMINATION")
    end

    generic_pages.clear
  end

  validate :check_data

  def check_data
    case self.pattern_cd
    when Settings.QUESTION_PATTERNCD_PARENTQUESTION
      validate_presence(:content, I18n.t("materials_registration.MAT_REG_REGISTERPARENTQUESTION_ERROR1"))

    when Settings.QUESTION_PATTERNCD_RADIO, Settings.QUESTION_PATTERNCD_ONELIST
      validate_presence(:content, I18n.t("materials_registration.MAT_REG_REGISTERQUESTION_ERROR4"))

      checked_items = []
      self.quizzes_attributes.each do |key, quiz|
        checked_items.push(key) if quiz['select_correct_flag'] == '1' || quiz['select_mark_flag'] == '1'
      end
      if checked_items.count == 0
        if self.generic_page_type_cd == Settings.GENERICPAGE_TYPECD_COMPOUNDCODE
          errors[:base] << I18n.t("materials_registration.MAT_REG_REGISTERQUESTION_ERROR3")
        end
      elsif checked_items.count == 1
        errors[:base] << I18n.t("materials_registration.MAT_REG_REGISTERQUESTION_ERROR6") if self.quizzes_attributes[checked_items[0]]['content'].blank?
      else
        errors[:base] << I18n.t("materials_registration.MAT_REG_REGISTERQUESTION_ERROR2")
      end

    when Settings.QUESTION_PATTERNCD_CHECK
      validate_presence(:content, I18n.t("common.COMMON_CONTENTCHECK"))

      if self.generic_page_type_cd == Settings.GENERICPAGE_TYPECD_COMPOUNDCODE
        checked_count = 0
        self.quizzes_attributes.each do |key, quiz|
          if quiz['select_correct_flag'] == '1'
            checked_count += 1
            if quiz['content'].blank?
              errors[:base] << I18n.t("materials_registration.MAT_REG_REGISTERQUESTION_ERROR6")
              break
            end
          end
        end
        if checked_count == 0
          errors[:base] << I18n.t("materials_registration.MAT_REG_REGISTERQUESTION_ERROR3")
        end
      end

    when Settings.QUESTION_PATTERNCD_ESSAY
      validate_presence(:content, I18n.t("common.COMMON_CONTENTCHECK"))
      if self.parent.generic_pages.first.type_cd != Settings.GENERICPAGE_TYPECD_QUESTIONNAIRECODE
        validate_presence(:answer_memo, I18n.t("materials_registration.MAT_REG_REGISTERQUESTION_ERROR5"))
      end

    when Settings.QUESTION_PATTERNCD_ASSIGNMENTESSAY
      validate_presence(:content, I18n.t("common.COMMON_CONTENTCHECK"))
    end
  end

  def answer(user)
    self.answers.where(:user_id => user.id).first
  end

  def pattern_name
    case self.pattern_cd
    when Settings.QUESTION_PATTERNCD_RADIO
      I18n.t("materials_registration.MAT_REG_REGISTERQUESTION_SELECTTYPE1")

    when Settings.QUESTION_PATTERNCD_ONELIST
      I18n.t("materials_registration.MAT_REG_REGISTERQUESTION_SELECTTYPE2")

    when Settings.QUESTION_PATTERNCD_CHECK
      I18n.t("materials_registration.MAT_REG_REGISTERQUESTION_SELECTTYPE3")

    when Settings.QUESTION_PATTERNCD_ESSAY
      I18n.t("materials_registration.MAT_REG_REGISTERQUESTION_SELECTTYPE4")
    end
  end

  def chart_data(page_id)
    self.summary if self.summary

    return self.summary if self.pattern_cd == Settings.QUESTION_PATTERNCD_ESSAY
    self.summary = {}

    users = User.joins(:enrollment_courses => :questionnaires).where("generic_pages.id = ?", page_id)
    titles = {}
    counts = {}

    self.select_quizzes.each.with_index(1) do |quiz, index|
      titles[quiz.id] = index
      counts[quiz.id] = 0
    end

    if self.select_ohters.count > 0
      titles[Answer::OTHER_ANSWER_ID] = self.select_quizzes.count + 1
      counts[Answer::OTHER_ANSWER_ID] = 0
    end

    users.each do |user|
      score = AnswerScore.where("page_id = ? AND user_id = ?", page_id, user.id).order("answer_count DESC").first
      if score && score.total_score > -1
        answers = self.answers.where("user_id = ? AND answer_count = ?", user.id, score.answer_count)
        answers.each do |answer|
          if answer.select_answer_id
            if counts[answer.select_answer_id]
              counts[answer.select_answer_id] += 1
            else
              counts[Answer::OTHER_ANSWER_ID] += 1
            end
          end
        end
      end
    end



    titles.each do |key, value|
      self.summary["#{value}\n(#{counts[key]}#{I18n.t("common.COMMON_BARCHARTPEOPLE")})"] = counts[key]
    end

    self.summary
  end

  def compound_chart_data
    data = {}
    titles = {}
    users = {}

    if self.pattern_cd == Settings.QUESTION_PATTERNCD_RADIO ||
       self.pattern_cd == Settings.QUESTION_PATTERNCD_ONELIST
      self.select_quizzes.each do |quiz|
        data[quiz.content] = 0
        titles[quiz.id] = quiz.content
      end

    elsif self.score <= 10
      0.upto(self.score).each do |index|
        data[index] = 0
      end

    else
      0.upto(4).each do |index|
        key = self.score.quo(5) * (index + 1)
        data[key] = 0
      end

    end

    self.answers.order("user_id ASC, answer_count DESC").each do |answer|
      next if users.key?(answer.user_id)

      users[answer.user_id] = answer

      if self.pattern_cd == Settings.QUESTION_PATTERNCD_RADIO ||
         self.pattern_cd == Settings.QUESTION_PATTERNCD_ONELIST
        data[titles[answer.select_answer_id]] += 1

      elsif self.score <= 10
        data[answer.score] += 1

      else
        val = answer.score
        if data.keys[1] > val
          data[data.keys[0]] += 1
        elsif data.keys[2] > val
          data[data.keys[1]] += 1
        elsif data.keys[3] > val
          data[data.keys[2]] += 1
        elsif data.keys[4] > val
          data[data.keys[3]] += 1
        else
          data[data.keys[4]] += 1
        end
      end

    end

    data
  end

  def correct?(answers)
    if answers.kind_of?(Array)
      if answers[self.id.to_s] && answers[self.id.to_s][:score] > 0
        return true
      end
    end

    false
  end
end
