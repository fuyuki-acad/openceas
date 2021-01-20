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

class Multiplefib < GenericPage
  include UploadFileModule

  EXT_PDF = ".pdf"

  attr_accessor :explanation_file

  before_save do
    if self.explanation_file
      delete_exist_file unless self.explanation_link_name.blank?
      create_explanation_file
    end
  end

  before_destroy do
    unless self.explanation_link_name.blank?
      delete_file(self.explanation_link_name, get_material_path)
    end
  end

  def delete_explanation_file
    unless self.explanation_link_name.blank?
      delete_exist_file
      self.explanation_link_name = nil
      self.explanation_link_name = nil
      save
    end
  end

  def get_explanation_link_url
    self.get_material_url_path + self.explanation_link_name.to_s
  end

  def edit_file?
    if self.link_name.blank?
      false
    else
      HTML_TYPES.include?(File.extname(self.link_name)) ? true : false
    end
  end

  def pdf?
    if self.link_name.blank?
      false
    else
      EXT_PDF == File.extname(self.link_name) ? true : false
    end
  end

  def copy(course)
    new_object = super(course)
    file_name = copy_explanation_file(new_object)
    if file_name.blank?
      new_object.explanation_file_name = nil
      new_object.explanation_link_name = nil
    else
      new_object.explanation_link_name = file_name
    end
    new_object
  end

  def copy_explanation_file(new_object)
    unless self.explanation_link_name.blank?
      src_file = self.get_material_path + self.explanation_link_name
      dest_file = new_object.get_material_path + new_object.get_link_name(self.explanation_link_name)
      if File.exist?(src_file)
        FileUtils.cp src_file, dest_file
        File.basename(dest_file)
      end
    end
  end

  private
    def create_explanation_file
      self.explanation_file_name = self.explanation_file.original_filename
      self.explanation_link_name = get_link_name(self.explanation_file_name)
      upload_file = get_material_path + self.explanation_link_name
      File.open(upload_file, "wb") {|f|f.write(self.explanation_file.read)}
    end

    def delete_exist_file
      file_path = get_material_path + self.explanation_link_name
      if File.exist?(file_path)
        delete_file(self.explanation_link_name, get_material_path)
  		end
    end
end
