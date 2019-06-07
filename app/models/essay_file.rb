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

require 'kconv'

class EssayFile
  include ActiveModel::Model, UploadFileModule

  UPLOAD_FILE_TYPES = ['.zip']

  attr_accessor :course_id, :file, :content_type

  def check_data
    if @file.blank?
      errors.add(:file, I18n.t("materials_registration.MAT_COM_MYFOLDER_SELECTFILE"))
    elsif @file.size == 0
      errors.add(:file, I18n.t("materials_registration.MAT_COM_MYFOLDER_NOCONTENTS"))
    else
      errors.add(:file, I18n.t("materials_registration.MAT_COM_MYFOLDER_NOCONTENTS")) unless check_compressed_file(@file)
    end
  end

  def check_compressed_file(compressed_file = @file)
    ret = false

    extname = File.extname(compressed_file.original_filename)
    if EXTRACT_TYPES.include?(extname.downcase)
      count = 0
      Zip::File.open(compressed_file.tempfile) do |zip|
        zip.each do |entry|
          count += 1
        end
      end
      ret = true if count > 0
    end

    ret
  end

  def extract_file(compressed_file = @file)
    extract_file_path = get_extract_path
    self.original_filename = compressed_file.original_filename
    extname = File.extname(compressed_file.original_filename)
    case extname.downcase
    when ".zip"
      Zip::File.open(compressed_file.tempfile) do |zip|
        zip.each do |entry|
          entry_name = entry.name.toutf8.gsub("\\", "/")
          unless File.directory?(entry_name)
            zip.extract(entry, extract_file_path + File.basename(entry_name)) {true}
          end
        end
      end

    else
    end
  end

  def extracted_files
    extract_file_path = get_temporary_path + self.extract_path
    Dir.entries(extract_file_path).delete_if{ |entry| (entry=="." || entry=="..") }
  end

  def extracted_file_path
    get_temporary_path + self.extract_path
  end
end
