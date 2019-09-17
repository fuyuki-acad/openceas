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

class Faq < ApplicationRecord
  include CustomValidationModule

  belongs_to  :course
  belongs_to  :user, optional: true
  has_many  :faq_answers, -> { order('id DESC') }
  has_one   :faq_answer, -> { order('id DESC') }

  attr_accessor :faq_answer_attributes

  validate :check_data

  XML_CONVERT_CEAS10 = {:user_id => :usrId, :faq_title => :faqTitle, :question => :question,
    :open_flag => :openFlg, :response_flag => :responseFlg, :created_at => :insertDate,
    :faq_answer => {:tag => :faqAnswer, :xml_convertor => FaqAnswer::XML_CONVERT_CEAS10}}

  def check_data
    validate_presence(:faq_title, I18n.t("common.COMMON_SUBJECTCHECK"))
    validate_max_length(:faq_title, I18n.t("common.COMMON_SUBJECTLENGTHCHECK"), 100)
    validate_presence(:question, I18n.t("common.COMMON_CONTENTCHECK"))
    validate_max_length(:question, I18n.t("faq.FAQ_REGISTERFAQQUESTION_SCRIPT1"), 4096)

    if self.faq_answer_attributes
      if self.faq_answer_attributes[:id].blank?
        answer = FaqAnswer.new(self.faq_answer_attributes)
      else
        answer = FaqAnswer.find(self.faq_answer_attributes[:id])
        answer.assign_attributes(self.faq_answer_attributes)
      end
      unless answer.valid?
        answer.errors.messages.each do |key, msg|
          errors.add(key, msg)
        end
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

    if self.faq_answer_attributes
      if self.faq_answer_attributes["id"].blank?
        answer = FaqAnswer.new(self.faq_answer_attributes)
        answer.faq_id = self.id
        throw(:abort) unless answer.save
      else
        answer = FaqAnswer.find(self.faq_answer_attributes["id"])
        throw(:abort) unless answer.update(self.faq_answer_attributes)
      end
    end
  end

  def get_title
    self.faq_title
  end

  def faq_answerer
    if self.faq_answer
      self.faq_answer.answerer.user_name
    else
      I18n.t("faq.COMMONFAQ_ANOTHERINSTRUCTOR") if self.response_flag == Settings.FAQ_RESPONSEFLG_REPLIED
    end
  end

  def response_flag_view
    if self.response_flag == Settings.FAQ_RESPONSEFLG_UNREPLY
      "×"
    elsif self.response_flag == Settings.FAQ_RESPONSEFLG_REPLIED
      "○"
    end
  end

  def open_flag_view
    if self.open_flag == Settings.FAQ_OPENFLG_PRIVATE
      "×"
    elsif self.open_flag == Settings.FAQ_OPENFLG_PUBLIC
      "○"
    end
  end

  def open_flag_title
    if self.open_flag == Settings.FAQ_OPENFLG_PRIVATE
      I18n.t("converter.PRE_CON_OPENFAQCONVERTER_CLOSED")
    elsif self.open_flag == Settings.FAQ_OPENFLG_PUBLIC
      I18n.t("converter.PRE_CON_OPENFAQCONVERTER_OPEN")
    end
  end
end
