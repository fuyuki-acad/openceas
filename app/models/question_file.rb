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

class QuestionFile
  include ActiveModel::Model, ErrorMessageModule

  CONTENT_TYPE_XML = ".xml"
  CONTENT_TYPE_CSV = ".csv"
  UPLOAD_FILE_TYPES = [CONTENT_TYPE_XML, CONTENT_TYPE_CSV]

  attr_accessor :generic_page_id, :file

  validate :check_data

  def check_data
    if @file.blank?
      errors.add(:file, I18n.t("common.COMMON_UPLOADFILENULLCHECK"))
    elsif File.extname(@file.original_filename).length == 0
      errors.add(:file, I18n.t("page_management.MAT_REG_MAT_PAGEMANAGEMENT_ERRORTYPE3"))
    else
      errors.add(:file, I18n.t("materials_registration.COMMONMATERIALSREGISTRATION_QUESTION_UPLOAD_FILECHECK")) unless UPLOAD_FILE_TYPES.include?(File.extname(@file.original_filename))
    end
  end

  def xml?
    File.extname(@file.original_filename) == CONTENT_TYPE_XML
  end

  def csv?
    File.extname(@file.original_filename) == CONTENT_TYPE_CSV
  end
end
