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

class AssignmentEssayComment < ApplicationRecord
  include UploadFileModule

  belongs_to  :answer_score, optional: true
  belongs_to  :answer_score_history, primary_key: :answer_score_id , foreign_key: :answer_score_id

  before_save do
    throw(:abort) unless create_historty
  end

  def create_historty
    if self.new_record?
      self.insert_user_id = User.current_user.id
    end
    self.update_user_id = User.current_user.id

    if self.answer_score.latest_history
      history = self.answer_score.latest_history.latest_comment
      history = AssignmentEssayCommentHistory.new(answer_score_history_id: self.answer_score.latest_history.id) unless history

      history.memo = self.memo
      history.mail_flag = self.mail_flag
      history.mailsend_date = self.mailsend_date
      history.return_flag = self.return_flag
      history.processed_file_name = self.processed_file_name
      history.processed_link_name = self.processed_link_name
      history.return_file_name = self.return_file_name
      history.return_link_name = self.return_link_name
      history.effective_date = self.effective_date
      history.effective_memo = self.effective_memo
      history.insert_memo = self.insert_memo
      history.insert_user_id = self.insert_user_id
      history.update_memo = self.update_memo
      history.update_user_id = self.update_user_id

      return history.save
    end
  end

  def set_return_file(new_file)
    self.processed_file_name = File.basename(new_file)
    self.processed_link_name = get_link_name(self.processed_file_name)
    essay_path = self.get_essay_path(self.answer_score.generic_page.course) + self.processed_link_name
    FileUtils.mv(new_file, essay_path, {:force => true})
  end

  def get_link_url
    essay_url = self.get_essay_url_path(self.answer_score.generic_page.course)
    essay_url + self.processed_link_name.to_s
  end

  def get_file_path
    essay_path = self.get_essay_path(self.answer_score.generic_page.course)
    essay_path + self.processed_link_name.to_s
  end
end
