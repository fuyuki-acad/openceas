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

class MaterialFile
  include ActiveModel::Model, UploadFileModule

  UPLOAD_FILE_TYPES = ['.xml', '.csv']
  CONTENT_TYPE_XML = "xml"
  CONTENT_TYPE_CSV = "csv"

  attr_accessor :course_id, :file, :content_type

  validate :check_data

  def check_data
    if @file.blank?
      errors.add(:file, I18n.t("common.COMMON_UPLOADFILENULLCHECK"))
    elsif @file.size == 0
      errors.add(:file, I18n.t("page_management.MAT_REG_MAT_PAGEMANAGEMENT_ERRORTYPE3"))
    else
      errors.add(:file, I18n.t("common.COMMON_UPLOADFILECHECK")) unless check_compressed_file(@file)
    end
  end

  def check_compressed_file(compressed_file)
    ret = false

    extname = File.extname(compressed_file.original_filename)
    if EXTRACT_TYPES.include?(extname.downcase)
      count = 0
      Zip::File.open(compressed_file.tempfile) do |zip|
        zip.each do |entry|
          if (entry.name.downcase =~/material[0-9]*.csv/) || (entry.name.downcase =~/material[0-9]*.xml/)
            count += 1
          end
        end
      end
      ret = true if count > 0
    end

    ret
  end

  def file_name
    @file.original_filename
  end

  def file_size
    (@file.size / 1024.0).ceil
  end
end
