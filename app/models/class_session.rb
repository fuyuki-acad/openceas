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

class ClassSession < ApplicationRecord
  belongs_to  :course
  has_and_belongs_to_many :generic_pages, :class_name => "GenericPage",
    :join_table => :generic_page_class_session_associations, :foreign_key => :class_session_id, :association_foreign_key => :generic_page_id
  has_many    :attendances, :foreign_key => [:course_id, :class_session_no]
  has_many  :generic_page_class_session_associations,  dependent: :delete_all

  XML_CONVERT_CEAS10 = {:class_session_no => :classSessionNo, :class_session_title => :classSessionTitle, :overview => :overview,
    :class_session_day => :classSessionDay, :class_session_memo => :classSessionMemoOpen, :class_session_memo_closed => :classSessionMemo}

  before_save do
    if User.current_user
      if self.new_record?
        self.insert_user_id = User.current_user.id
      end
      self.update_user_id = User.current_user.id
    end
  end

  def assigned_materials?
    self.generic_pages.where(type_cd: Settings.GENERICPAGE_TYPECD_MATERIALCODE).first
  end

  def materials
    self.generic_pages.where(type_cd: Settings.GENERICPAGE_TYPECD_MATERIALCODE).order("view_rank")
  end

  def assigned_urls?
    self.generic_pages.where(type_cd: Settings.GENERICPAGE_TYPECD_URLCODE).first
  end

  def urls
    self.generic_pages.where(type_cd: Settings.GENERICPAGE_TYPECD_URLCODE).order("view_rank")
  end

  def assigned_componds?
    self.generic_pages.where(type_cd: Settings.GENERICPAGE_TYPECD_COMPOUNDCODE).first
  end

  def componds
    self.generic_pages.where(type_cd: Settings.GENERICPAGE_TYPECD_COMPOUNDCODE).order("view_rank")
  end

  def assigned_multiplefibs?
    self.generic_pages.where(type_cd: Settings.GENERICPAGE_TYPECD_MULTIPLEFIBCODE).first
  end

  def multiplefibs
    self.generic_pages.where(type_cd: Settings.GENERICPAGE_TYPECD_MULTIPLEFIBCODE).order("view_rank")
  end

  def assigned_essays?
    self.generic_pages.where(type_cd: Settings.GENERICPAGE_TYPECD_ASSIGNMENTESSAYCODE).first
  end

  def essays
    self.generic_pages.where(type_cd: Settings.GENERICPAGE_TYPECD_ASSIGNMENTESSAYCODE).order("view_rank")
  end

  def assigned_questionnaires?
    self.generic_pages.where(type_cd: Settings.GENERICPAGE_TYPECD_QUESTIONNAIRECODE).first
  end

  def questionnaires
    self.generic_pages.where(type_cd: Settings.GENERICPAGE_TYPECD_QUESTIONNAIRECODE).order("view_rank")
  end

  def assigned_evaluations?
    self.generic_pages.where(type_cd: Settings.GENERICPAGE_TYPECD_EVALUATIONLISTCODE).first
  end

  def evaluations
    self.generic_pages.where(type_cd: Settings.GENERICPAGE_TYPECD_EVALUATIONLISTCODE).order("view_rank")
  end

  def assigned_generic_pages
    self.generic_pages.where("type_cd IN (?)",
      [Settings.GENERICPAGE_TYPECD_MATERIALCODE, Settings.GENERICPAGE_TYPECD_URLCODE,
       Settings.GENERICPAGE_TYPECD_COMPOUNDCODE, Settings.GENERICPAGE_TYPECD_MULTIPLEFIBCODE,
       Settings.GENERICPAGE_TYPECD_ASSIGNMENTESSAYCODE, Settings.GENERICPAGE_TYPECD_QUESTIONNAIRECODE,
       Settings.GENERICPAGE_TYPECD_EVALUATIONLISTCODE]).
      order("type_cd")
  end
end
