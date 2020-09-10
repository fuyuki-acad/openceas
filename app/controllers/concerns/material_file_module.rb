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

require 'builder'
require 'zip'
require "rexml/document"

module MaterialFileModule
  extend ActiveSupport::Concern

  attr_accessor :tmp_dir, :temp_file

  ZIP_FILE_NAME = "material.zip"
  XML_MATERIAL_PATH = "tmp/material"
  FILE_QUESTION_PATH = "questions"
  FILE_EXPLAIN_PATH = "explains"

  def create_xml_and_compress(generic_page)
    @tmp_dir = "#{Rails.root}/tmp/work/#{Time.zone.now.to_f.to_s.sub(".","")}"
    @temp_file = @tmp_dir + "/" + ZIP_FILE_NAME
    FileUtils.mkdir_p(@tmp_dir)

    xml = create_xml(generic_page)
    write_xml(xml)
    copy_files(generic_page)
    compress

    File.read(@temp_file)
  end

  def create_xml(generic_page)
    xml_data = ""

    system_version = I18n.t("login.LOG_LOGIN_FACULTY1")
    xml = Builder::XmlMarkup.new(:target => xml_data)
#    xml.instruct!(:xml, :version => 1.0, :encoding => "Shift_JIS")
    xml.instruct!(:xml, :version => 1.0, :encoding => "UTF-8")
    xml.pages(:ceasVersion => system_version) do |pages|
      pages.page(:courseId => generic_page.course_id, :pageId => generic_page.id) do |xml_page|
        set_page_elements(xml_page, generic_page)

        generic_page.parent_questions.each do |parent|
          xml_page.parentQuestion do |xml_parent|
            xml_parent.content parent.content.html_safe

            parent.questions.each do |data_question|
              xml_parent.question do |xml_question|
                set_question_elements(xml_question, data_question)

                data_question.select_quizzes.each do |quiz|
                  xml_question.sel do |xml_sel|
                    set_sel_elements(xml_sel, quiz)
                  end
                end
              end
            end
          end
        end
      end
    end

    xml.target!
  end

  def set_page_elements(xml_page, generic_page)
    xml_page.typeCd generic_page.type_cd
    xml_page.pageTitle generic_page.generic_page_title
    xml_page.startPass generic_page.start_pass
    xml_page.startTime generic_page.start_time.blank? ? generic_page.start_time : I18n.l(generic_page.start_time)
    xml_page.endTime generic_page.end_time.blank? ? generic_page.end_time : I18n.l(generic_page.end_time)
    xml_page.fileName generic_page.file_name
    xml_page.linkName generic_page.link_name
    xml_page.explanationFileName generic_page.explanation_file_name
    xml_page.maxCount generic_page.max_count
    xml_page.passGrade generic_page.pass_grade
    xml_page.selfFlg generic_page.self_flag
    xml_page.selfPass generic_page.self_pass
    xml_page.editFlg generic_page.edit_flag
    xml_page.anonymousFlg generic_page.anonymous_flag
    xml_page.timelagFlg generic_page.timelag_flag
    xml_page.urlContent generic_page.url_content
    xml_page.preGradingEnableFlg generic_page.pre_grading_enable_flag
    xml_page.assignmentEssayReturnMethodCd generic_page.assignment_essay_return_method_cd
    xml_page.scoreOpenFlg generic_page.score_open_flag
    xml_page.materialMemo generic_page.material_memo
    xml_page.materialMemoClosed generic_page.material_memo_closed
    xml_page.correctAnswerDisplayFlg generic_page.correct_answer_display_flag
  end

  def set_question_elements(xml_question, question)
    xml_question.content question.content
    xml_question.patternCd question.pattern_cd
    xml_question.score question.score
    xml_question.correctAnswerMemo question.correct_answer_memo
    xml_question.wrongAnswerMemo question.wrong_answer_memo
    xml_question.answerMemo question.answer_memo
    xml_question.mustFlg question.must_flag
    xml_question.otherFlg question.text_flag
    xml_question.randomCd question.random_cd
    xml_question.answerInFullCd question.answer_in_full_cd
    xml_question.textRow question.text_row
    xml_question.viewRank question.view_rank
  end

  def set_sel_elements(xml_sel, quiz)
    xml_sel.content quiz.content
    xml_sel.selectCorrectFlg quiz.select_correct_flag
    xml_sel.selectMarkFlg quiz.select_mark_flag
    xml_sel.textRow quiz.text_row
    xml_sel.viewRank quiz.view_rank
  end

  def write_xml(xml)
    xml_file = "material.xml"
    material_dir = "#{@tmp_dir}/#{XML_MATERIAL_PATH}"
    FileUtils.mkdir_p(material_dir)

#    File.open("#{material_dir}/#{xml_file}", "w:cp932") do |f|
    File.open("#{material_dir}/#{xml_file}", "w") do |f|
      f.print(xml)
    end
  end

  def copy_files(generic_page)
    material_dir = "#{@tmp_dir}/#{XML_MATERIAL_PATH}"
    FileUtils.mkdir_p(material_dir)

    if generic_page.type_cd == Settings.GENERICPAGE_TYPECD_MULTIPLEFIBCODE
      unless generic_page.link_name.blank?
        src_file = generic_page.get_material_path + generic_page.link_name
        if File.exist?(src_file)
          FileUtils.mkdir_p(material_dir + "/#{FILE_QUESTION_PATH}")
          if generic_page.file_name.blank?
            dest_file = material_dir + "/#{FILE_QUESTION_PATH}/" + generic_page.link_name
          else
            dest_file = material_dir + "/#{FILE_QUESTION_PATH}/" + generic_page.file_name
          end
          FileUtils.cp_r(src_file, dest_file)
        end
      end

      unless generic_page.explanation_link_name.blank?
        src_file = generic_page.get_material_path + generic_page.explanation_link_name
        if File.exist?(src_file)
          FileUtils.mkdir_p(material_dir+ "/#{FILE_EXPLAIN_PATH}")
          dest_file = material_dir + "/#{FILE_EXPLAIN_PATH}/" + generic_page.explanation_file_name
          FileUtils.cp_r(src_file, dest_file)
        end
      end

    else
      unless generic_page.link_name.blank?
        src_file = generic_page.get_material_path + generic_page.link_name
        if File.exist?(src_file)
          dest_file = material_dir + "/" + generic_page.file_name
          FileUtils.cp_r(src_file, dest_file)
        end
      end
    end
  end

  def compress
    Zip.unicode_names = true
    Zip::ZipFile.open(@temp_file, 'w') do |zip_file|
      Dir["#{tmp_dir}/**/**"].reject{ |f| f == temp_file }.each do |add_file|
        if File.directory?(add_file)
          zip_file.mkdir(relative(add_file, @tmp_dir))
        elsif File.file?(add_file)
          zip_file.add(relative(add_file, @tmp_dir), add_file)
        end
      end
    end
  end

  def clean_up_data
    FileUtils.rm_r(@tmp_dir) if @tmp_dir && File.exist?(@tmp_dir)
  end

  def extract_file(compress_file)
    tmp_dir = "#{Rails.root}/tmp/work/#{Time.zone.now.to_f.to_s.sub(".","")}/"
    FileUtils.mkdir_p(tmp_dir)

    Zip::File.open(compress_file.tempfile) do |zip|
      zip.each do |entry|
        if (entry.name.downcase =~/material[0-9]*.csv/) || (entry.name.downcase =~/material[0-9]*.xml/)
          zip.extract(entry, tmp_dir + File.basename(entry.name)) {true}
        elsif entry.name.downcase !~ /uploadfiles/
          extract_path = tmp_dir + relative(entry.name, XML_MATERIAL_PATH)
          FileUtils.mkdir_p(File.dirname(extract_path)) unless File.exist?(File.dirname(extract_path))
          zip.extract(entry, extract_path) {true}
        end
      end
    end

    tmp_dir
  end

  def import(course, material_file_path, type)
    generic_page = nil

    begin
      ActiveRecord::Base.transaction do
        attach_files = []
        Dir["#{material_file_path}/**/**"].each do |material_file|
          if File.file?(material_file)
            if material_file.downcase =~/material[0-9]*.xml/
              generic_page = import_xml(course, material_file, type)
            elsif material_file.downcase =~/material[0-9]*.csv/
            elsif material_file.downcase !~ /uploadfiles/
              attach_files << material_file
            end
          end
        end

        move_files(attach_files, generic_page) if attach_files.count > 0 && generic_page
      end

      generic_page
    ensure
      FileUtils.rm_r(material_file_path)
    end
  end

  def import_xml(course, material_file, type)

    generic_page = nil
    xml = REXML::Document.new(File.new(material_file))

    raise "upload file type is not match." if type.to_s != xml.elements['pages/page/typeCd'].text

    xml.elements.each('pages/page') do |xml_page|
      generic_page = set_xml_page(xml_page, course)

      xml_page.elements.each('parentQuestion') do |xml_parent|
        parent = set_xml_parent(xml_parent, generic_page)

        xml_parent.elements.each('question') do |xml_question|
          question = set_xml_question(xml_question, parent)

          xml_question.elements.each('sel') do |xml_sel|
            set_xml_sel(xml_sel, question)
          end
          if xml_question.elements['otherFlg'].text == "1"
            quiz = SelectQuiz.new
            quiz.content = I18n.t("common.COMMON_OTHER")
            quiz.text_row = 1
            question.select_quizzes << quiz
          end
        end
      end
    end

    generic_page
  end

  def set_xml_page(xml_page, course)
    case xml_page.elements['typeCd'].text
    when Settings.GENERICPAGE_TYPECD_COMPOUNDCODE.to_s
      generic_page = Compound.new
    when Settings.GENERICPAGE_TYPECD_MULTIPLEFIBCODE.to_s
      generic_page = Multiplefib.new
    when Settings.GENERICPAGE_TYPECD_ASSIGNMENTESSAYCODE.to_s
      generic_page = Essay.new
    else
      generic_page = GenericPage.new
    end

    generic_page.course = course
    generic_page.type_cd = xml_page.elements['typeCd'].text
    generic_page.generic_page_title = get_xml_value(xml_page.elements['pageTitle'].text)
    generic_page.start_pass = get_xml_value(xml_page.elements['startPass'].text)
    generic_page.start_time = get_xml_value(xml_page.elements['startTime'].text)
    generic_page.end_time = get_xml_value(xml_page.elements['endTime'].text)
    generic_page.file_name = get_xml_value(xml_page.elements['fileName'].text)
    generic_page.link_name = get_xml_value(xml_page.elements['linkName'].text)
    generic_page.explanation_file_name = get_xml_value(xml_page.elements['explanationFileName'].text)
    generic_page.max_count = get_xml_value(xml_page.elements['maxCount'].text)
    generic_page.pass_grade = get_xml_value(xml_page.elements['passGrade'].text)
    generic_page.self_flag = xml_page.elements['selfFlg'].text if set_value?(xml_page.elements['selfFlg'])
    generic_page.self_pass = get_xml_value(xml_page.elements['selfPass'].text)
    generic_page.edit_flag = xml_page.elements['editFlg'].text if set_value?(xml_page.elements['editFlg'])
    generic_page.anonymous_flag = xml_page.elements['anonymousFlg'].text if set_value?(xml_page.elements['anonymousFlg'])
    generic_page.timelag_flag = xml_page.elements['timelagFlg'].text if set_value?(xml_page.elements['timelagFlg'])
    generic_page.url_content = get_xml_value(xml_page.elements['urlContent'].text)
    generic_page.pre_grading_enable_flag = xml_page.elements['preGradingEnableFlg'].text if set_value?(xml_page.elements['preGradingEnableFlg'])
    generic_page.assignment_essay_return_method_cd = get_xml_value(xml_page.elements['assignmentEssayReturnMethodCd'])
    generic_page.score_open_flag = xml_page.elements['scoreOpenFlg'].text if set_value?(xml_page.elements['scoreOpenFlg'])
    generic_page.material_memo = get_xml_value(xml_page.elements['materialMemo'].text)
    generic_page.correct_answer_display_flag = get_xml_value(xml_page.elements['correctAnswerDisplayFlg'].text)
    generic_page.save!

    generic_page
  end

  def set_xml_parent(xml_parent, generic_page)
    parent = Question.new
    parent.content = get_xml_value(xml_parent.elements['content'].text).presence || ""
    parent.pattern_cd = Settings.QUESTION_PATTERNCD_PARENTQUESTION
    parent.save!(validate: false)
    generic_page.questions << parent

    parent
  end

  def set_xml_question(xml_question, parent)
    question = Question.new
    question.parent = parent
    question.content = get_xml_value(xml_question.elements['content'].text).presence || ""
    question.pattern_cd = get_xml_value(xml_question.elements['patternCd'].text)
    question.score = get_xml_value(xml_question.elements['score'].text)
    question.correct_answer_memo = get_xml_value(xml_question.elements['correctAnswerMemo'].text)
    question.wrong_answer_memo = get_xml_value(xml_question.elements['wrongAnswerMemo'].text)
    question.answer_memo = get_xml_value(xml_question.elements['answerMemo'].text)
    question.must_flag = xml_question.elements['mustFlg'].text if set_value?(xml_question.elements['mustFlg'])
    question.random_cd = get_xml_value(xml_question.elements['randomCd'].text)
    question.answer_in_full_cd = get_xml_value(xml_question.elements['answerInFullCd'].text)
    question.text_row = xml_question.elements['textRow'].text if set_value?(xml_question.elements['textRow'])
    question.view_rank = xml_question.elements['viewRank'].text if set_value?(xml_question.elements['viewRank'])
    question.save!(validate: false)

    question
  end

  def set_xml_sel(xml_sel, question)
    quiz = SelectQuiz.new
    quiz.content = get_xml_value(xml_sel.elements['content'].text)
    quiz.question = question
    quiz.select_correct_flag = xml_sel.elements['selectCorrectFlg'].text if set_value?(xml_sel.elements['selectCorrectFlg'])
    quiz.select_mark_flag = xml_sel.elements['selectMarkFlg'].text if set_value?(xml_sel.elements['selectMarkFlg'])
    quiz.text_row = xml_sel.elements['textRow'].text if set_value?(xml_sel.elements['textRow'])
    quiz.view_rank = xml_sel.elements['viewRank'].text if set_value?(xml_sel.elements['viewRank'])
    quiz.save!

    quiz
  end

  def move_files(attach_files, generic_page)
    update_flag = false

    attach_files.each do |attach_file|
      if attach_file.include?("/#{FILE_EXPLAIN_PATH}/")
        unless generic_page.explanation_file_name.blank?
          generic_page.explanation_link_name = generic_page.get_link_name(generic_page.explanation_file_name)
          dest_file = generic_page.get_material_path + generic_page.explanation_link_name
          FileUtils.cp_r(attach_file, dest_file)
          update_flag = true
        end
      else
        unless generic_page.link_name.blank?
          generic_page.link_name = generic_page.get_link_name(generic_page.link_name)
          dest_file = generic_page.get_material_path + generic_page.link_name
          FileUtils.mkdir_p(File.dirname(dest_file))
          FileUtils.cp_r(attach_file, dest_file)
          update_flag = true
        end
      end
    end

    generic_page.save! if update_flag
  end

  private
    def relative(path, base_dir)
      path.index(base_dir) == 0 ? path[base_dir.length() + 1 .. path.length()] : path
    end

    def get_xml_value(value)
      value == "null" ? "" : value
    end

    def set_value?(value)
      value && !value.text.blank? && value != "null" ? true : false
    end
end
