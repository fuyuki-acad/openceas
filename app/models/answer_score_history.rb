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

class AnswerScoreHistory < ApplicationRecord
  include UploadFileModule

  belongs_to  :generic_page,  :foreign_key => :page_id
  belongs_to  :answer_score
  has_many    :answer_histories, primary_key: :answer_score_id , foreign_key: :answer_score_id
  has_one     :latest_comment, -> { order('id DESC') }, class_name: "AssignmentEssayCommentHistory"
  belongs_to  :user

  attr_accessor :rank

  def get_file_path
    case self.generic_page.type_cd
    when Settings.GENERICPAGE_TYPECD_ASSIGNMENTESSAYCODE
      self.get_essay_path(self.generic_page.course) + self.link_name.to_s
    end
  end
end
