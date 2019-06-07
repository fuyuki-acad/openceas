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

class GroupFolderMaterial < ApplicationRecord
  include UploadFileModule, CustomValidationModule

  belongs_to  :group_folder
  belongs_to  :user, optional: true

  SEARCH_ALL = "0"
  SEARCH_TITLE = "1"
  SEARCH_USER = "2"

  ORDER_ASC = "0"
  ORDER_DSC = "1"

  TYPE_UPDATE = "0"
  TYPE_DELETE = "1"

  attr_accessor :file

  validate :check_data

  def check_data
    validate_presence(:title, I18n.t("group_folder.PRE_BEA_GRO_GROUPFOLDERBEAN_ERROR4"))
    validate_presence(:display_pass, I18n.t("group_folder.PRE_BEA_GRO_GROUPFOLDERBEAN_ERROR3"))
    if self.file.blank?
      errors.add(:file, I18n.t("group_folder.PRE_BEA_GRO_GROUPFOLDERBEAN_ERROR5")) if new_record?
    else
      extname = File.extname(self.file.original_filename)
      errors.add(:file, I18n.t("group_folder.PRE_BEA_GRO_GROUPFOLDERBEAN_ERROR7")) if extname.blank?
      errors.add(:file, I18n.t("group_folder.PRE_BEA_GRO_GROUPFOLDERBEAN_ERROR1")) if extname.downcase == ".exe"
      errors.add(:file, I18n.t("group_folder.PRE_BEA_GRO_GROUPFOLDERBEAN_ERROR9")) if self.file.size < 0
    end
  end

  before_save do
    if User.current_user
      if self.new_record?
        self.user_id = User.current_user.id
        self.insert_user_id = User.current_user.id
      end
      self.update_user_id = User.current_user.id
    end

    if self.file
      self.file_name = self.file.original_filename
      self.link_name = get_link_name(self.file_name)
      self.file_size = self.file.size
      self.file_type = File.extname(self.file_name)

      upload_file = get_group_folder_path(self.group_folder.course) + self.link_name
      File.open(upload_file, "wb") {|f|f.write(self.file.read)}
    end
  end

  before_destroy do
    delete_file(self.link_name, get_group_folder_path(self.group_folder.course))
  end

  def get_group_folder_path(course)
    path = get_course_base_path(course) + "groupfolder/"
    check_user_path(path)
    path
  end

  def material_file
    get_group_folder_path(self.group_folder.course) + self.link_name
  end

  def owner?(user_id)
    self.user_id == user_id ? true : false
  end
end
