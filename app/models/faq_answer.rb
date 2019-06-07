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

class FaqAnswer < ApplicationRecord
  include CustomValidationModule
  belongs_to  :faq, optional: true
  belongs_to  :answerer, :foreign_key => :insert_user_id, :class_name => 'User', optional: true

  validate :check_data

  def check_data
    validate_presence(:answer_title, I18n.t("faq.FAQ_ANSWERFAQ_SCRIPT1"))
    validate_max_length(:answer_title, I18n.t("faq.FAQ_ANSWERFAQ_SCRIPT2"), 128)
    validate_presence(:answer, I18n.t("faq.FAQ_ANSWERFAQ_SCRIPT3"))
    validate_max_length(:answer, I18n.t("faq.FAQ_ANSWERFAQ_SCRIPT4"), 4096)
    validate_max_length(:open_question, I18n.t("faq.FAQ_ANSWERFAQ_SCRIPT5"), 4096)
    validate_max_length(:open_answer, I18n.t("faq.FAQ_ANSWERFAQ_SCRIPT6"), 4096)
  end

  before_save do
    if User.current_user
      if self.new_record?
        self.insert_user_id = User.current_user.id
      end
      self.update_user_id = User.current_user.id
    end
  end

  def new?
    if self.updated_at + 3.days > Time.zone.now
      return true
    else
      return false
    end
  end
end
