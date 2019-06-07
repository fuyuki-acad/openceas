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

require 'active_support/concern'
require 'zip'
require 'kconv'

module UploadFileModule
  extend ActiveSupport::Concern

  included do
    EXTRACT_TYPES = ['.zip']
    HTML_TYPES = ['.html', '.htm']

    attr_accessor :file, :extract_flag, :original_filename, :store_filename, :extract_path
  end

  def get_upload_path
    Rails.root.join("public", "#{Settings.UPLOAD_DIR}").to_s + "/"
  end

  def get_download_path
    Rails.root.join("public", "#{Settings.DOWNLOAD_DIR}").to_s + "/"
  end

  def get_course_base_path(link_course = self.course)
    path = get_upload_path + "course/course" + format("%08d", link_course.id) + "/"
  end

  def get_material_path(link_course = self.course)
    path = get_course_base_path(link_course) + "materials/"
    check_user_path(path)
    path
  end

  def get_essay_path(link_course = self.course)
    path = get_material_path(link_course) + "assignmentessay/"
    check_user_path(path)
    path
  end

  def get_base_url
    path = "/#{Settings.UPLOAD_DIR}/"
  end

  def get_course_base_url(link_course = self.course)
    path = get_base_url + "course/course" + format("%08d", link_course.id) + "/"
  end

  def get_material_url_path(link_course = self.course)
    get_course_base_url(link_course) + "materials/"
  end

  def get_essay_url_path(link_course = self.course)
    get_material_url_path(link_course) + "assignmentessay/"
  end

  def check_user_path(path_name)
    FileUtils.mkdir_p(path_name) unless Dir.exist?(path_name)
  end

  def get_link_name(file_name)
    extname = File.extname(file_name)
    Time.zone.now.to_f.to_s.sub(".","") + extname
  end

  def get_temporary_path
    Rails.root.join("tmp", "#{Settings.UPLOAD_DIR}", User::current_user.id.to_s).to_s
  end

  def get_extract_path
    self.extract_path = Time.zone.now.to_f.to_s.sub(".","") + "/"
    extract_file_path = get_temporary_path + self.extract_path
    check_user_path(extract_file_path)
    extract_file_path
  end

  def check_compressed_file(compressed_file)
    ret = false

    extname = File.extname(compressed_file.original_filename)
    case extname.downcase
    when ".zip"
      count = 0
      Zip::File.open(compressed_file.tempfile) do |zip|
        zip.each do |entry|
          entry_name = entry.name.toutf8.gsub("\\", "/")
          if HTML_TYPES.include?(File.extname(entry_name.downcase)) &&
             (entry_name =~/^[ -~｡-ﾟ]*$/)
            count += 1
          end
        end
      end
      ret = true if count > 0

    else
    end

    ret
  end

  def create_file(file_path)
    unless self.extract_flag == 'true'
      self.original_filename = self.file.original_filename
      self.store_filename = get_link_name(self.file.original_filename)
      upload_file = file_path + self.store_filename
      File.open(upload_file, "wb") {|f|f.write(file.read)}
    end
  end

  def create_html_file(text)
    if self.file_name.blank?
      self.store_filename = get_link_name("dummy.html")
    else
      self.file_name = self.file_name + ".html"
      self.store_filename = get_link_name(self.file_name)
    end
    html_file = get_material_path + self.store_filename
    File.open(html_file, "wb") {|f|f.write(text)}
  end

  def extract_file(compressed_file)
    extract_file_path = get_extract_path
    self.original_filename = compressed_file.original_filename
    extname = File.extname(compressed_file.original_filename)
    case extname.downcase
    when ".zip"
      Zip::File.open(compressed_file.tempfile) do |zip|
        zip.each do |entry|
          entry_name = entry.name.toutf8.gsub("\\", "/")
          if HTML_TYPES.include?(File.extname(entry_name.downcase)) &&
             (entry_name =~/^[ -~｡-ﾟ]*$/)
             entry_path = File.dirname(entry_name)
             if entry_path != "."
               FileUtils.mkdir_p(extract_file_path + entry_path) unless Dir.exist?(extract_file_path + entry_path)
             end
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

  def move_extracted_files
    src_path = get_temporary_path + self.extract_path
    dest_path = get_material_path + self.extract_path
    FileUtils.move(src_path, dest_path)
  end

  def delete_file(target_file_name, path)
    if target_file_name.include?("/")
      delete_path = "#{path}/" + File.dirname(target_file_name)
      FileUtils.rm_r(delete_path) if Dir.exist?(delete_path)
    else
      delete_f =  "#{path}/#{target_file_name}"
      File.delete(delete_f) if File.exist?(delete_f)
    end
  end

  def load_file(target_file_name, path)
    target_file =  "#{path}/#{target_file_name}"
    File.read(target_file) if File.exist?(target_file)
  end
end
