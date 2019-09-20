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

require 'builder/xmlmarkup'
require 'zip'
require 'kconv'

module XmlConvertorModule
  extend ActiveSupport::Concern

  VER_CEAS10 = "CEAS 10"
  VER_OPENCEAS = "Open CEAS 1.0"
  ZIP_FILE_NAME = "material.zip"

  BASE_DIR = "tmp/material"
  MANIFEST_FILE = "manifest.xml"
  COURSE_FILE = "course.xml"
  CLASS_SESSION_FILE = "classSession.xml"
  ALLOCATION_FILE = "allocation.xml"
  ANNOUNCEMENT_FILE = "announcement/material.xml"
  FAQ_FILE = "faq/material.xml"
  MATERIAL_PATH = "material"
  MATERIAL_FILE = "#{MATERIAL_PATH}/material.xml"
  URL_FILE = "url/material.xml"
  COMPOUND_PATH = "compound"
  COMPOUND_FILE = "#{COMPOUND_PATH}/material.xml"
  MULTIPLEFIB_PATH = "multipleFib"
  MULTIPLEFIB_FILE = "#{MULTIPLEFIB_PATH}/material.xml"
  ASSIGNMNENT_ESSAY_PATH = "assignmentEssay"
  ASSIGNMNENT_ESSAY_FILE = "#{ASSIGNMNENT_ESSAY_PATH}/material.xml"
  QUESTIONNAIRE_PATH = "questionnaire"
  QUESTIONNAIRE_FILE = "#{QUESTIONNAIRE_PATH}/material.xml"
  EVALUATIONLIST_FILE = "evaluationlist/material.xml"
  MULTIPLEFIB_EXPPLANATION_PATH = "explains"
  MULTIPLEFIB_LINK_PATH = "questions"

  protected
  def create_xml_and_compress
    tmp_dir = "#{Rails.root}/tmp/work/#{Time.zone.now.to_f.to_s.sub(".","")}"
    temp_file = tmp_dir + "/" + ZIP_FILE_NAME
    FileUtils.mkdir_p(tmp_dir)

    yield tmp_dir

    compress(temp_file)

    temp_file
  end

  def compress(compress_file)
    compress_dir = File.dirname(compress_file)
    Zip::ZipFile.open(compress_file, 'w') do |zip_file|
      Dir["#{compress_dir}/**/**"].reject{ |f| f == compress_file }.each do |add_file|
        if File.directory?(add_file)
          zip_file.mkdir(relative(add_file, compress_dir))
        elsif File.file?(add_file)
          zip_file.add(relative(add_file, compress_dir), add_file)
        end
      end
    end
  end

  def create_xml_file(data, opt = {}, file_path)
    xml_data = ""
    tag_name = ""
    is_single = false

    if opt.kind_of?(Hash)
      opt[:version] = VER_CEAS10 unless opt.key?(:version)
      tag_name = opt[:tag_name] if opt.key?(:tag_name)
      is_single = true if opt[:single_record] === true
    end

    if is_single
      tag_name = data.class.name.downcase if tag_name.blank?
    else
      tag_name = data[0].class.name.downcase if tag_name.blank? && data.count > 0
    end

    xml = Builder::XmlMarkup.new(:target => xml_data)
    xml.instruct!(:xml, :version => 1.0, :encoding => "UTF-8")
    set_xml_elements(tag_name, data, xml, opt[:version], opt[:convertor], is_single)

    content = xml.target!
    write_file(content, file_path)
  end

  def set_xml_elements(tag_name, data, xml, version, convertor, is_single)
    if is_single
      xml.tag!(tag_name, {:ceasVersion => version}) do |xml_element|
        set_xml_tag(data, xml_element, convertor)
      end
    else
      xml.tag!(tag_name.pluralize, {:ceasVersion => version}) do |xml_element|
        set_xml_element(tag_name, data, xml_element, convertor)
      end
    end
  end

  def set_xml_element(tag_name, data, xml, convertor)
    tag_convertor = convertor.dup if convertor

    data.each do |record|
      if !convertor.blank? && convertor.key?(:tag_attributes)
        tag_attributes = {}
        convertor[:tag_attributes].each do |key, value|
          tag_attributes[value] = record[key.to_s] unless record[key.to_s].blank?
        end

        tag_convertor.delete(:tag_attributes)
      end

      xml.tag!(tag_name, tag_attributes) do |xml_item|
        set_xml_tag(record, xml_item, tag_convertor)
      end
    end
  end

  def set_xml_tag(record, xml_item, convertor)
    if convertor.blank?
      record.attributes.keys.each do |key|
        xml_item.tag!(key, record.attributes[key])
      end

    else
      convertor.each do |key, value|
        if value.class.name == 'Hash'
          sub_data = record.send(key.to_s)
          if sub_data
            if sub_data.class.name == 'ActiveRecord::Associations::CollectionProxy'
              sub_data.each do |sub_datum|
                xml_item.tag!(value[:tag]) do |xml_tag|
                  set_xml_tag(sub_datum, xml_tag, value[:xml_convertor])
                end
              end
            else
              if value[:field]
                xml_item.tag!(value[:tag], sub_data.attributes[value[:field].to_s])
              else
                xml_item.tag!(value[:tag]) do |xml_tag|
                  set_xml_tag(sub_data, xml_tag, value[:xml_convertor])
                end
              end
            end
          end
        else
          xml_item.tag!(value, record.attributes[key.to_s])
        end
      end
    end
  end

  def export_material_file(data, path)
    data.each do |generic_page|
      dest = ""
      if generic_page.multiplefib?
        if generic_page.explanation_link_name
          link_paths = generic_page.explanation_link_name.split("/")
          if link_paths.size < 2
            dest = path + "/#{generic_page.id}/#{MULTIPLEFIB_EXPPLANATION_PATH}/"
          else
            dest = path + "/#{generic_page.id}/#{MULTIPLEFIB_EXPPLANATION_PATH}/#{paths[0]}/"
          end

          if FileTest.exist?(generic_page.get_explanation_file_path)
            FileUtils.mkdir_p(dest)
            FileUtils.cp_r generic_page.get_explanation_file_path, dest
          end
        end

        if generic_page.link_name
          link_paths = generic_page.link_name.split("/")
          if link_paths.size < 2
            dest = path + "/#{generic_page.id}/#{MULTIPLEFIB_LINK_PATH}/"
          else
            dest = path + "/#{generic_page.id}/#{MULTIPLEFIB_LINK_PATH}/#{paths[0]}/"
          end

          if FileTest.exist?(generic_page.get_material_file_path)
            FileUtils.mkdir_p(dest)
            FileUtils.cp_r generic_page.get_material_file_path, dest
          end
        end

      else
        if generic_page.link_name
          dest = path + "/#{generic_page.id}/"
          if generic_page.material?
            link_paths = generic_page.link_name.split("/")
            dest = path + "/#{generic_page.id}/"
            if link_paths.size < 2
              src = generic_page.get_material_file_path
            else
              src = generic_page.get_material_path + "#{link_paths[0]}/#{link_paths[1]}"
            end
          else
            link_paths = generic_page.link_name.split("/")
            if link_paths.size < 2
              dest = path + "/#{generic_page.id}/"
            else
              dest = path + "/#{generic_page.id}/#{link_paths[0]}/"
            end
            src = generic_page.get_material_file_path
          end

          if FileTest.exist?(src)
            FileUtils.mkdir_p(dest)
            FileUtils.cp_r src, dest
          end
        end
      end
    end
  end

  def import_material_file(generic_page, orginal_page_id, extract_file_path, category_path)
    if generic_page.multiplefib?
      explain = extract_file_path + BASE_DIR + "/" + category_path + "/" + orginal_page_id + "/#{MULTIPLEFIB_EXPPLANATION_PATH}/*"
      question = extract_file_path + BASE_DIR + "/" + category_path + "/" + orginal_page_id + "/#{MULTIPLEFIB_LINK_PATH}/*"
      dest = generic_page.get_material_path
      FileUtils.rm_rf(dest + "*", :secure => true) unless Dir.glob(dest + "*").empty?
      FileUtils.mkdir(dest) unless FileTest.exist?(dest)

      Dir.glob(explain).each do |file|
        generic_page.explanation_link_name = generic_page.get_link_name(file)
        explain_file = dest + generic_page.explanation_link_name
        FileUtils.cp(file, explain_file)
        generic_page.save!
      end

      Dir.glob(question).each do |file|
        FileUtils.cp_r(file, dest)
      end

    else
      dirs = generic_page.link_name.split('/')
      if dirs.size < 2
        dest = generic_page.get_material_path
      else
        dest = generic_page.get_material_path + dirs[0] + "/"
      end
      FileUtils.rm_rf(dest + "*", :secure => true) unless Dir.glob(dest + "*").empty?
      FileUtils.mkdir(dest) unless FileTest.exist?(dest)

      if generic_page.material?
        src = extract_file_path + BASE_DIR + "/" + category_path + "/" + orginal_page_id + "/*"
        Dir.glob(src).each do |file|
          FileUtils.cp_r(file, dest)
        end
      else
        src = extract_file_path + BASE_DIR + "/" + category_path + "/" + orginal_page_id + "/" + generic_page.link_name
        FileUtils.cp_r(src, dest) if FileTest.exist?(src)
      end
    end
  end

  def load_xml_file_as_hash(extract_file_path, file_name)
    xml_file = read_xml_file(extract_file_path + BASE_DIR + "/" + file_name)
    Hash.from_xml(xml_file)
  end

  def write_file(xml, file_path)
    dir = File.dirname(file_path)
    FileUtils.mkdir_p(dir)

    File.open(file_path, "w") do |f|
      f.print(xml)
    end
  end

  def extract_file(course, compressed_file)
    extract_file_path = get_temporary_path(course)

    FileUtils.rm(Dir.glob("#{extract_file_path}*.*")) if Dir.exist?(extract_file_path)

    extname = File.extname(compressed_file.original_filename)
    case extname.downcase
    when ".zip"
      Zip::File.open(compressed_file.tempfile) do |zip|
        zip.each do |entry|
          entry_name = entry.name.toutf8.gsub("\\", "/")
          entry_path = File.dirname(entry_name)
          if entry_path != "."
            FileUtils.mkdir_p(extract_file_path + entry_path) unless Dir.exist?(extract_file_path + entry_path)
          end
          p entry_name
          zip.extract(entry, extract_file_path + entry_name) {true}
          #ext = File.extname(entry.name).downcase
          #if ext == ".txt" || ext == ".html" || ext == ".htm"
          #  file_convert_to_utf8(extract_file_path + entry_name)
          #end
        end
      end

    else
    end

    extract_file_path
  end

  def get_temporary_path(course)
    Rails.root.join("tmp", "#{Settings.UPLOAD_DIR}", User::current_user.id.to_s, course.id.to_s).to_s + '/'
  end

  def read_xml_file(filename)
    contents = ""

    if File.exist?(filename)
      File.open(filename) do |file|
        contents = NKF.nkf('-w',file.read)
        contents.gsub!('Shift_JIS','UTF-8')
        contents.gsub!('shift_jis','UTF-8')
      end
    end

    contents
  end

  def file_convert_to_utf8(filename)
    content = File.read(filename)
    if NKF.guess(content).to_s == "Shift_JIS"
      content = File.read(f, :encoding => Encoding::Shift_JIS).encode(Encoding::UTF_8)
      File.open(filename, "w") { |f| f.puts(content) }
    end
  end

  def remove_temporary_files(course)
    extract_file_path = get_temporary_path(course)
    FileUtils.rm_r(extract_file_path)
  end

  private
  def relative(path, base_dir)
    path.index(base_dir) == 0 ? path[base_dir.length() + 1 .. path.length()] : path
  end

  def null?(value)
    if value == "null"
      true
    else
      false
    end
  end

  def null_convert(value)
    if value == "null"
      ''
    else
      value
    end
  end

end
