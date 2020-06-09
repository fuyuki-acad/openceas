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

class Help < ApplicationRecord
  include UploadFileModule

  DOWNLOAD_PATH = "#{Settings.DOWNLOAD_DIR}/"
  HELP_PATH = "#{Settings.MANUAL_DIR}/"
  MANUAL_FILE_EXTS = [".pdf"]

  attr_accessor :file

  before_save do
    if file
      self.file_name = self.file.original_filename
      throw(:abort) unless check_exist_file
      create_file
    end

    if self.new_record?
      self.answer_count = self.answer_count || 1
      self.insert_user_id = User.current_user.id
    end
    self.update_user_id = User.current_user.id
  end

  validate :check_data

  def check_data
    if file.blank?
      errors.add(:file, I18n.t("helptop.HELPTOP_UPDATE_FAILURE"))
    else
      extname = File.extname(self.file.original_filename)
      if MANUAL_FILE_EXTS.include?(extname.downcase)
        if self.file.size == 0
          errors.add(:file, I18n.t("helptop.HELPTOP_UPDATE_FAILURE"))
        end
      else
        errors.add(:file, I18n.t("helptop.HELPTOP_UPDATE_FILETYPE_ERROR"))
      end
    end
  end

  def create_file
    FileUtils.mkdir_p(get_help_path)
    upload_file = get_help_path + self.link_name
    File.open(upload_file, "wb") {|f|f.write(file.read)}
  end

  def check_exist_file
    file_path = get_help_path + self.link_name
    if File.exist?(file_path)
			## 既存のファイルがある場合はリネームする
      new_file_dir = get_help_path + "bak/"
      check_user_path(new_file_dir)
      if self.file_name_was.blank?
        new_file_path = new_file_dir + self.file_name
      else
        new_file_path = new_file_dir + self.file_name_was
      end
			false unless FileUtils.move(file_path, new_file_path)
		end

    true
  end

  def get_link_url
    DOWNLOAD_PATH + HELP_PATH + self.link_name
  end

  def get_help_path
    path = get_download_path + HELP_PATH
    check_user_path(HELP_PATH)
    path
  end
end
