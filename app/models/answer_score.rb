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

class AnswerScore < ApplicationRecord
  include UploadFileModule, CustomValidationModule

  belongs_to  :generic_page,  :foreign_key => :page_id
  belongs_to  :user
  belongs_to  :self_user, :class_name => 'User', :foreign_key => :self_user_id, optional: true
  has_many    :assignment_essay_comments
  has_one     :latest_comment, -> { order('id DESC') }, :class_name => "AssignmentEssayComment", :foreign_key => :answer_score_id
  accepts_nested_attributes_for :assignment_essay_comments
  has_many    :answers
  has_one     :latest_history, -> { order('answer_count DESC') }, :class_name => "AnswerScoreHistory", :foreign_key => :answer_score_id

  attr_accessor :course, :rank, :average, :max_score, :view_total_score, :comment_attributes

  DEFAULTSCORE = -1

  before_save do
    case self.generic_page.type_cd
    when Settings.GENERICPAGE_TYPECD_ASSIGNMENTESSAYCODE
      self.course = self.generic_page.course

      if file
        create_file(get_essay_path)
        count = self.answer_count.to_i == 0 ? 1 : self.answer_count
        self.file_name = self.original_filename
        self.link_name = self.store_filename

        if self.latest_history && self.latest_history.file_name && self.answer_count == self.latest_history.answer_count
          delete_file(self.latest_history.file_name, get_essay_path)
        end
      end
    end

    if self.new_record?
      self.answer_count = 1 if self.answer_count.nil? || self.answer_count == 0
      self.insert_user_id = User.current_user.id
    end
    self.update_user_id = User.current_user.id
  end

  after_save do
    throw(:abort) unless create_historty
  end

  validate :check_data

  def check_data
    case self.generic_page.type_cd
    when Settings.GENERICPAGE_TYPECD_ASSIGNMENTESSAYCODE
      if file.blank?
        errors.add(:file_name, I18n.t("execution.MAT_EXE_ASS_EXECUTEASSIGNMENTESSAY_ERRORTYPE1"))
      else
        extname = File.extname(file.original_filename)
        errors.add(:file_name, I18n.t("page_management.MAT_REG_MAT_PAGEMANAGEMENT_ERRORTYPE3")) if extname.blank?
        errors.add(:file_name, I18n.t("page_management.MAT_REG_MAT_PAGEMANAGEMENT_ERRORTYPE8")) if extname.downcase == ".exe"
      end
    end
  end

  def create_historty
    history = AnswerScoreHistory.where(answer_score_id: self.id, answer_count: self.answer_count).first
    if history.blank?
      history = AnswerScoreHistory.new(answer_score_id: self.id, page_id: self.page_id, user_id: self.user_id, answer_count: self.answer_count)
    end

    history.total_score = self.total_score
    history.total_raw_score = self.total_raw_score
    history.self_total_score = self.self_total_score
    history.assignment_essay_score = self.assignment_essay_score
    history.pass_cd = self.pass_cd
    history.file_name = self.file_name
    history.link_name = self.link_name
    history.effective_date = self.effective_date
    history.effective_memo = self.effective_memo
    history.insert_memo = self.insert_memo
    history.insert_user_id = self.insert_user_id
    history.update_memo = self.update_memo
    history.update_user_id = self.update_user_id

    return history.save
  end

  def get_link_url
    case self.generic_page.type_cd
    when Settings.GENERICPAGE_TYPECD_ASSIGNMENTESSAYCODE
      self.get_essay_url_path(self.generic_page.course) + self.link_name.to_s
    end
  end

  def get_file_path
    case self.generic_page.type_cd
    when Settings.GENERICPAGE_TYPECD_ASSIGNMENTESSAYCODE
      self.get_essay_path(self.generic_page.course) + self.link_name.to_s
    end
  end

  def saved?
    if self.total_score == Settings.ANSWERSCORE_TMP_SAVED_SCORE
      true
    else
      false
    end
  end
end
