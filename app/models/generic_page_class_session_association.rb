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

class GenericPageClassSessionAssociation < ApplicationRecord
  include CustomValidationModule

  belongs_to  :generic_page
  belongs_to  :class_session

  validate :check_data
  
  def check_data
    validate_numeric(:view_rank_before_type_cast, I18n.t("materials_registration.COMMONMATERIALSREGISTRATION_VIEW_RANK_NUMERIC_ERROR")) if view_rank_before_type_cast.present?
  end

  XML_CONVERT_CEAS10 = {:class_session => {:tag => 'classSessionNo', :field => :class_session_no}, :generic_page_id => :pageId, :view_rank => :viewRank}

  before_save do
    if User.current_user
      if self.new_record?
        self.insert_user_id = User.current_user.id
      end
      self.update_user_id = User.current_user.id
    end
  end

  def get_view_rank
    self.view_rank unless self.view_rank.blank? || self.view_rank == 0
  end
end
