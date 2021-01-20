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

class Answer < ApplicationRecord
  include CustomValidationModule

  belongs_to  :question
  belongs_to  :select_quiz,  :foreign_key => :select_answer_id, optional: true
  belongs_to  :user
  belongs_to  :answer_score, optional: true

  OTHER_ANSWER_ID = "0"

  validate :check_data

  def check_data
    if self.question.must_flag == Settings.QUESTION_MUSTFLG_MUST
      if question.pattern_cd == Settings.QUESTION_PATTERNCD_ESSAY
        validate_presence(:text_answer, '"' + question.content.html_safe + '"' + I18n.t("execution.MAT_EXE_QUE_EXECUTEQUESTIONNAIRE_ERROR1"))
      elsif question.pattern_cd != Settings.QUESTION_PATTERNCD_CHECK
        validate_presence(:select_answer_id, '"' + question.content.html_safe + '"' + I18n.t("execution.MAT_EXE_QUE_EXECUTEQUESTIONNAIRE_ERROR1"))
      end
    end
  end

  before_save do
    if User.current_user
      if self.new_record?
        self.insert_user_id = User.current_user.id
      end
      self.update_user_id = User.current_user.id
    end
    self.effective_date = Time.zone.now
  end

  after_save do
    throw(:abort) unless create_historty
  end

  def destroy_historty(answer_count)
    AnswerHistory.where(answer_id: self.id, answer_count: answer_count).delete_all
  end

  def create_historty
    history = AnswerHistory.where(question_id: self.question_id, user_id: self.user_id, answer_count: self.answer_count).first
    if history.blank?
      history = AnswerHistory.new(
        answer_id: self.id,
        question_id: self.question_id,
        user_id: self.user_id,
        answer_count: self.answer_count,
        answer_score_id: self.answer_score_id)
    end

    history.select_answer_id = self.select_answer_id
    history.text_answer = self.text_answer
    history.score = self.score
    history.self_score = self.self_score
    history.effective_date = self.effective_date
    history.effective_memo = self.effective_memo
    history.insert_memo = self.insert_memo
    history.insert_user_id = self.insert_user_id
    history.update_memo = self.update_memo
    history.update_user_id = self.update_user_id

    return history.save
  end
end
