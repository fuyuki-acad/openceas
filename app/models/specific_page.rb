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

class SpecificPage < Course
  include UploadFileModule, CustomValidationModule

  INDEX_FILE = "index.html"
  FILE_PATH = "specificpage/"
  ALPHANUMERIC = /^[0-9A-Za-z._-]+$/

  attr_accessor :file, :target_directory

  validate :check_data

  def check_data
    if file.blank?
      errors.add(:file, I18n.t("specific_page.MAT_ALL_COU_REGISTERSPECIFICPAGE_ERRORTYPE1"))
    else
      extname = File.extname(file.original_filename)
      if EXTRACT_TYPES.include?(extname.downcase)
        if File.size(file.tempfile) == 0
          errors.add(:file, I18n.t("specific_page.MAT_ALL_COU_REGISTERSPECIFICPAGE_ERRORTYPE3"))
        else
          file_name = File.basename(file.original_filename, ".*")
          if file_name.size > 15
            errors.add(:file, I18n.t("specific_page.MAT_ALL_COU_REGISTERSPECIFICPAGE_ERRORTYPE7"))
            return
          end
          if ALPHANUMERIC !~ file_name
            errors.add(:file, I18n.t("specific_page.MAT_ALL_COU_REGISTERSPECIFICPAGE_ERRORTYPE7"))
            return
          end

          errors.add(:file, I18n.t("specific_page.MAT_ALL_COU_REGISTERSPECIFICPAGE_ERRORTYPE5")) unless check_compressed_file(file)

          case exist_index?(file)
          when -1
            errors.add(:file, I18n.t("specific_page.MAT_ALL_COU_REGISTERSPECIFICPAGE_ERRORTYPE3"))
          when 0
            errors.add(:file, I18n.t("specific_page.MAT_ALL_COU_REGISTERSPECIFICPAGE_ERRORTYPE6"))
          end

          case valid_filename_length?(file)
          when 1
            errors.add(:file, I18n.t("specific_page.MAT_ALL_COU_REGISTERSPECIFICPAGE_ERRORTYPE4"))
          when 2
            errors.add(:file, I18n.t("specific_page.MAT_ALL_COU_REGISTERSPECIFICPAGE_ERRORTYPE5"))
          end
        end
      else
        errors.add(:file, I18n.t("specific_page.MAT_ALL_COU_REGISTERSPECIFICPAGE_ERRORTYPE2"))
      end
    end
  end

  def course
    self
  end

  def exist_index?(target_file)
    extname = File.extname(target_file.original_filename)
    case extname.downcase
    when ".zip"
      count = 0
      Zip::File.open(target_file.tempfile) do |zip|
        zip.each do |entry|
          dir_name = File.dirname(entry.name)
          if dir_name == "."
            count = -1
          else
            if INDEX_FILE == File.basename(entry.name.downcase)
              self.target_directory = dir_name
              count = 1
              break
            end
          end
        end
      end
    end

    return count
  end

  def valid_filename_length?(target_file)
    extname = File.extname(target_file.original_filename)
    case extname.downcase
    when ".zip"
      Zip::File.open(target_file.tempfile) do |zip|
        zip.each do |entry|
          entry_name = entry.name.toutf8.gsub("\\", "/")
          file_name = File.basename(entry_name, ".*")
          if file_name.size > 15
            return 1
          elsif (ALPHANUMERIC !~ file_name)
            return 2
          end
          file_path = File.dirname(entry_name)
          file_path.split("/").each do |dir_name|
            if dir_name != "."
              if dir_name.size > 15
                return 1
              elsif (ALPHANUMERIC !~ dir_name)
                return 2
              end
            end
          end
        end
      end
    end

    return 0
  end

  def save_file
    if valid?
      extract_path = get_course_base_path + FILE_PATH
      if Dir.exist?(extract_path)
        FileUtils.rm_r(extract_path)
      end
      FileUtils.mkdir_p(extract_path)
      extract_file_path = extract_path + INDEX_FILE
      extname = File.extname(self.file.original_filename)
      case extname.downcase
      when ".zip"
        Zip::File.open(self.file.tempfile) do |zip|
          zip.each do |entry|
            entry_name = entry.name.toutf8.gsub("\\", "/")
            dir_name = File.dirname(entry_name)
            if dir_name != "."
              if HTML_TYPES.include?(File.extname(entry_name.downcase)) &&
                 (entry_name =~ /^[ -~｡-ﾟ]*$/)
                 dir_name = dir_name.sub(self.target_directory, "")
                 FileUtils.mkdir_p(extract_path + dir_name) unless Dir.exist?(extract_path + dir_name)
                 file_name = File.basename(entry_name)
                 zip.extract(entry, "#{extract_path}#{dir_name}/#{file_name}") {true}
              end
            end
          end
        end
        return true

      else
      end
    end

    return false
  end

  def get_specific_page_url
    extract_file = get_course_base_path + FILE_PATH + INDEX_FILE
    if File.exist?(extract_file)
      get_course_base_url + FILE_PATH + INDEX_FILE
    else
      nil
    end
  end
end
