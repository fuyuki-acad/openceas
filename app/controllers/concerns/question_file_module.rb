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

require "rexml/document"
require "csv"

module QuestionFileModule
  extend ActiveSupport::Concern

  SAMPLE_XML_FILE_NAME = "question.xml"
  SAMPLE_CSV_FILE_NAME = "question.csv"
  BOM = "\uFEFF"
  CRLF = "\r\n"
  CSV_HEADER_ROW = 23
  STATUS_OK = "OK"
  STATUS_NG = "NG"

  CSV_FIELDS = {
    :parent_question_num => I18n.t("materials_administration.MAT_ADM_COMPOUND_CSV_DOWNLOAD_HEADER2"),
    :parent_content => I18n.t("materials_administration.MAT_ADM_COMPOUND_CSV_DOWNLOAD_HEADER3"),
    :question_num => I18n.t("materials_administration.MAT_ADM_COMPOUND_CSV_DOWNLOAD_HEADER4"),
    :content => I18n.t("materials_administration.MAT_ADM_COMPOUND_CSV_DOWNLOAD_HEADER5"),
    :must_flg => I18n.t("materials_administration.MAT_ADM_COMPOUND_CSV_DOWNLOAD_HEADER6"),
    :score => I18n.t("materials_administration.MAT_ADM_COMPOUND_CSV_DOWNLOAD_HEADER7"),
    :view_rank => I18n.t("materials_administration.MAT_ADM_COMPOUND_CSV_DOWNLOAD_HEADER8"),
    :pattern_cd => I18n.t("materials_administration.MAT_ADM_COMPOUND_CSV_DOWNLOAD_HEADER9"),
    :text_row => I18n.t("materials_administration.MAT_ADM_COMPOUND_CSV_DOWNLOAD_HEADER10"),
    :answer_memo => I18n.t("materials_administration.MAT_ADM_COMPOUND_CSV_DOWNLOAD_HEADER11"),
    :correct_answer_memo => I18n.t("materials_administration.MAT_ADM_COMPOUND_CSV_DOWNLOAD_HEADER12"),
    :wrong_answer_memo => I18n.t("materials_administration.MAT_ADM_COMPOUND_CSV_DOWNLOAD_HEADER13"),
    :sel1_content => I18n.t("materials_administration.MAT_ADM_COMPOUND_CSV_DOWNLOAD_HEADER14"),
    :sel1_select_correct_flg => I18n.t("materials_administration.MAT_ADM_COMPOUND_CSV_DOWNLOAD_HEADER18"),
    :sel1_select_mark_flg => I18n.t("materials_administration.MAT_ADM_COMPOUND_CSV_DOWNLOAD_HEADER19"),
    :sel2_content => I18n.t("materials_administration.MAT_ADM_COMPOUND_CSV_DOWNLOAD_HEADER15"),
    :sel2_select_correct_flg => I18n.t("materials_administration.MAT_ADM_COMPOUND_CSV_DOWNLOAD_HEADER18"),
    :sel2_select_mark_flg => I18n.t("materials_administration.MAT_ADM_COMPOUND_CSV_DOWNLOAD_HEADER19"),
    :sel3_content => I18n.t("materials_administration.MAT_ADM_COMPOUND_CSV_DOWNLOAD_HEADER16"),
    :sel3_select_correct_flg => I18n.t("materials_administration.MAT_ADM_COMPOUND_CSV_DOWNLOAD_HEADER18"),
    :sel3_select_mark_flg => I18n.t("materials_administration.MAT_ADM_COMPOUND_CSV_DOWNLOAD_HEADER19"),
    :sel4_content => I18n.t("materials_administration.MAT_ADM_COMPOUND_CSV_DOWNLOAD_HEADER17"),
    :sel4_select_correct_flg => I18n.t("materials_administration.MAT_ADM_COMPOUND_CSV_DOWNLOAD_HEADER18"),
    :sel4_select_mark_flg => I18n.t("materials_administration.MAT_ADM_COMPOUND_CSV_DOWNLOAD_HEADER19")
  }

  attr_accessor :errors

  def xml_to_hash(generic_page, file)
    xml = REXML::Document.new(File.new(file.tempfile))

    questions = []
    parent_id = nil
    parent = nil

    xml.elements.each('Root/Row') do |row|
      next if row.elements['parent_question_num'].text !~ /^[0-9]+$/

      if parent_id != row.elements['parent_question_num'].text
        questions << parent unless parent.blank?

        parent_id = row.elements['parent_question_num'].text
        parent = {}
        parent['id'] = row.elements['parent_question_num'].text
        parent['content'] = row.elements['parent_content'].text
        parent['questions'] = []
      end

      question = {}
      question['content'] = row.elements['content'].text
      question['must_flag'] = row.elements['must_flg'].text
      question['score'] = row.elements['score'].text
      question['view_rank'] = row.elements['view_rank'].text
      case row.elements['pattern_cd'].text
      when "R"
        question['pattern_cd'] = Settings.QUESTION_PATTERNCD_RADIO
      when "L"
        question['pattern_cd'] = Settings.QUESTION_PATTERNCD_ONELIST
      when "M"
        question['pattern_cd'] = Settings.QUESTION_PATTERNCD_CHECK
      when "T"
        question['pattern_cd'] = Settings.QUESTION_PATTERNCD_ESSAY
      end
      question['text_row'] = row.elements['text_row'].text
      question['answer_memo'] = row.elements['answer_memo'].text
      question['correct_answer_memo'] = row.elements['correct_answer_memo'].text
      question['wrong_answer_memo'] = row.elements['wrong_answer_memo'].text
      question['sels'] = []

      1.upto(100).each do |index|
        break if row.elements["sel#{index}_content"].nil?

        sel = {}
        sel['content'] = row.elements["sel#{index}_content"].text
        sel['select_correct_flag'] = row.elements["sel#{index}_select_correct_flg"].text if generic_page.type_cd == Settings.GENERICPAGE_TYPECD_COMPOUNDCODE
        sel['select_mark_flag'] = row.elements["sel#{index}_select_mark_flg"].text if generic_page.type_cd == Settings.GENERICPAGE_TYPECD_QUESTIONNAIRECODE
        question['sels'] << sel
      end

      if generic_page.type_cd == Settings.GENERICPAGE_TYPECD_COMPOUNDCODE
        check_compound_data(row.elements['parent_question_num'].text, row.elements['question_num'].text, row.elements['parent_content'].text, question)
      else
        check_questionarie_data(row.elements['parent_question_num'].text, row.elements['question_num'].text, row.elements['parent_content'].text, question)
      end

      parent['questions'] << question
    end

    questions << parent unless parent.blank?
    questions
  end

  def csv_to_hash(generic_page, file)
    line = 0
    questions = []
    parent_id = nil
    parent = nil

    csv_data = CSV.parse(File.new(file.tempfile)) do |csv_row|
      line += 1
      next if line <= CSV_HEADER_ROW

      if parent_id != csv_row[0]
        questions << parent unless parent.blank?

        parent_id = csv_row[0]
        parent = {}
        parent['id'] = csv_row[0]
        parent['content'] = csv_row[1]
        parent['questions'] = []
      end

      question = {}
      question['content'] = csv_row[3]
      question['must_flag'] = csv_row[4]
      question['score'] = csv_row[5]
      question['view_rank'] = csv_row[6]
      case csv_row[7]
      when "R"
        question['pattern_cd'] = Settings.QUESTION_PATTERNCD_RADIO
      when "L"
        question['pattern_cd'] = Settings.QUESTION_PATTERNCD_ONELIST
      when "M"
        question['pattern_cd'] = Settings.QUESTION_PATTERNCD_CHECK
      when "T"
        question['pattern_cd'] = Settings.QUESTION_PATTERNCD_ESSAY
      end
      question['text_row'] = csv_row[8]
      question['answer_memo'] = csv_row[9]
      question['correct_answer_memo'] = csv_row[10]
      question['wrong_answer_memo'] = csv_row[11]
      question['sels'] = []

      1.upto(100).each do |index|
        cell_no = (index - 1) * 3 + 12
        break if csv_row[cell_no].nil?

        sel = {}
        sel['content'] = csv_row[cell_no]
        sel['select_correct_flag'] = csv_row[cell_no + 1] if generic_page.type_cd == Settings.GENERICPAGE_TYPECD_COMPOUNDCODE
        sel['select_mark_flag'] = csv_row[cell_no + 2] if generic_page.type_cd == Settings.GENERICPAGE_TYPECD_QUESTIONNAIRECODE
        question['sels'] << sel
      end

      if generic_page.type_cd == Settings.GENERICPAGE_TYPECD_COMPOUNDCODE
        check_compound_data(csv_row[0], csv_row[2], csv_row[1], question)
      else
        check_questionarie_data(csv_row[0], csv_row[2], csv_row[1], question)
      end

      parent['questions'] << question
    end

    questions << parent unless parent.blank?
    questions
  end

  def check_compound_data(parent_id, question_id, parent_content, question)
    error_flag = false
    message = ""
    @errors = [] if @errors.nil?

    if parent_id.blank?
      error_flag = true
      message = I18n.t("materials_registration.ERROR_PARENT_QUESTION_NUM")
    elsif parent_content.blank?
      error_flag = true
      message = I18n.t("materials_registration.ERROR_PARENT_CONTENT")
    elsif question_id.blank?
      error_flag = true
      message = I18n.t("materials_registration.ERROR_QUESTION_NUM")
    elsif question['content'].blank?
      error_flag = true
      message = I18n.t("materials_registration.ERROR_CONTENT")
    elsif question['score'].blank? || question['score'].to_i == 0
      error_flag = true
      message = I18n.t("materials_registration.ERROR_SCORE")
    elsif question['pattern_cd'].blank?
      error_flag = true
      message = I18n.t("materials_registration.ERROR_PATTERN_CD")
    else
      if question['pattern_cd'] == Settings.QUESTION_PATTERNCD_ESSAY
        if question['answer_memo'].blank?
          error_flag = true
          message = I18n.t("materials_registration.ERROR_NO_CORRECT_SEL")
        end

      elsif question['sels'].blank? || question['sels'].count == 0
        error_flag = true
        message = I18n.t("materials_registration.ERROR_NO_SEL")

      else
        collect_count = 0
        question['sels'].each do |sel|
          if sel['content'].blank?
            error_flag = true
            message = I18n.t("materials_registration.ERROR_NO_SEL")
            break
          end

          collect_count += 1 if sel['select_correct_flag'] == "1"
        end

        if collect_count == 0
          error_flag = true
          message = I18n.t("materials_registration.ERROR_NO_CORRECT_SEL")
        elsif question['pattern_cd'] != Settings.QUESTION_PATTERNCD_CHECK && collect_count > 1
          error_flag = true
          message = I18n.t("materials_registration.ERROR_MORE_CORRECT_SEL")
        end
      end
    end

    @errors << {:parent_question_num => parent_id, :question_num => question_id, :status => error_flag ? STATUS_NG : STATUS_OK, :message => message}
  end

  def check_questionarie_data(parent_id, question_id, parent_content, question)
    error_flag = false
    message = ""
    @errors = [] if @errors.nil?

    if parent_id.blank?
      error_flag = true
      message = I18n.t("materials_registration.ERROR_PARENT_QUESTION_NUM")
    elsif parent_content.blank?
      error_flag = true
      message = I18n.t("materials_registration.ERROR_PARENT_CONTENT")
    elsif question_id.blank?
      error_flag = true
      message = I18n.t("materials_registration.ERROR_QUESTION_NUM")
    elsif question['content'].blank?
      error_flag = true
      message = I18n.t("materials_registration.ERROR_CONTENT")
    elsif question['pattern_cd'].blank?
      error_flag = true
      message = I18n.t("materials_registration.ERROR_PATTERN_CD")
    elsif question['pattern_cd'] != Settings.QUESTION_PATTERNCD_ESSAY
      if question['sels'].blank? || question['sels'].count == 0
        error_flag = true
        message = I18n.t("materials_registration.ERROR_NO_SEL")
      else
        collect_count = 0
        question['sels'].each do |sel|
          if sel['content'].blank?
            error_flag = true
            message = I18n.t("materials_registration.ERROR_NO_SEL")
            break
          end
        end
      end
    end

    @errors << {:parent_question_num => parent_id, :question_num => question_id, :status => error_flag ? STATUS_NG : STATUS_OK, :message => message}
  end

  def has_upload_error?
    @errors.each do |error|
      return true if error[:status] == STATUS_NG
    end

    false
  end

  def import_questoins(generic_page, questions)
    questions.each do |data_parent|
      parent = set_data_parent(data_parent, generic_page)

      data_parent['questions'].each do |data_question|
        question = set_data_question(data_question, parent)

        data_question['sels'].each do |data_sel|
          set_data_sel(data_sel, question)
        end
      end
    end
  end

  def set_data_parent(data_parent, generic_page)
    parent = Question.new
    parent.content = data_parent['content']
    parent.pattern_cd = Settings.QUESTION_PATTERNCD_PARENTQUESTION
    parent.save!(validate: false)
    generic_page.questions << parent

    parent
  end

  def set_data_question(data_question, parent)
    question = Question.new
    question.parent = parent
    question.content = data_question['content']
    question.pattern_cd = data_question['pattern_cd']
    question.score = data_question['score'].to_i
    question.correct_answer_memo = data_question['correct_answer_memo']
    question.wrong_answer_memo = data_question['wrong_answer_memo']
    question.answer_memo = data_question['answer_memo']
    question.must_flag = data_question['must_flag'] unless data_question['must_flag'].blank?
    question.text_row = data_question['text_row'] unless data_question['text_row'].blank?
    question.view_rank = data_question['view_rank'] unless data_question['view_rank'].blank?
    question.save!(validate: false)

    question
  end

  def set_data_sel(data_sel, question)
    quiz = SelectQuiz.new
    quiz.content = data_sel['content']
    quiz.question = question
    quiz.select_correct_flag = get_flag(data_sel['select_correct_flag']) unless data_sel['select_correct_flag'].blank?
    quiz.select_mark_flag = get_flag(data_sel['select_mark_flag']) unless data_sel['select_mark_flag'].blank?
    quiz.save!

    quiz
  end

  def get_flag(value)
    value.to_s == "1" ? 1 : 0
  end

  def get_xml_questions(generic_page)
    make_xml_file(generic_page) do |doc|
      generic_page.parent_questions.each do |parent|
        parent.questions.each do |data_question|
          doc.Row do |xml_row|
            # parent question
            xml_row.parent_question_num parent.id
            xml_row.parent_content parent.content.html_safe

            #question
            xml_row.question_num data_question.id
            xml_row.content data_question.content.html_safe
            xml_row.must_flg data_question.must_flag
            xml_row.score data_question.score
            xml_row.view_rank data_question.view_rank

            case data_question.pattern_cd
            when Settings.QUESTION_PATTERNCD_RADIO
              xml_row.pattern_cd "R"
            when Settings.QUESTION_PATTERNCD_ONELIST
              xml_row.pattern_cd "L"
            when Settings.QUESTION_PATTERNCD_CHECK
              xml_row.pattern_cd "M"
            when Settings.QUESTION_PATTERNCD_ESSAY
              xml_row.pattern_cd "T"
            end

            xml_row.text_row data_question.text_row
            xml_row.answer_memo data_question.answer_memo
            xml_row.correct_answer_memo data_question.correct_answer_memo
            xml_row.wrong_answer_memo data_question.wrong_answer_memo

            data_question.all_quizzes.each.with_index(1) do |quiz, index|
              xml_row.tag! "sel#{index}_content", quiz.content
              xml_row.tag! "sel#{index}_select_correct_flg", quiz.select_correct_flag
              xml_row.tag! "sel#{index}_select_mark_flg", quiz.select_mark_flag
            end
          end
        end
      end
    end
  end

  def sample_xml_file(generic_page)
    make_xml_file(generic_page) do |doc|
      doc.Row do |xml_row|
        xml_row.parent_question_num ''
        xml_row.parent_content ''

        xml_row.question_num ''
        xml_row.content ''
        xml_row.must_flg ''
        xml_row.score ''
        xml_row.view_rank ''
        xml_row.pattern_cd ''
        xml_row.text_row ''
        xml_row.answer_memo ''
        xml_row.correct_answer_memo ''
        xml_row.wrong_answer_memo ''

        xml_row.sel1_content ''
        xml_row.sel1_select_correct_flg ''
        xml_row.sel1_select_mark_flg ''

        xml_row.sel2_content ''
        xml_row.sel2_select_correct_flg ''
        xml_row.sel2_select_mark_flg ''

        xml_row.sel3_content ''
        xml_row.sel3_select_correct_flg ''
        xml_row.sel3_select_mark_flg ''

        xml_row.sel4_content ''
        xml_row.sel4_select_correct_flg ''
        xml_row.sel4_select_mark_flg ''
      end
    end
  end

  def make_xml_file(generic_page)
    xml_data = ""

    xml = Builder::XmlMarkup.new(:target => xml_data, :indent => 2)
#    xml.instruct!(:xml, :version => 1.0, :encoding => "Shift_JIS")
    xml.instruct!(:xml, :version => 1.0, :encoding => "UTF-8", :standalone => "yes")
    xml.tag!('Root', {"xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance"}) do
      xml_header(generic_page, xml)

      yield xml
    end

    xml.target!
  end

  def xml_header(generic_page, doc)
    doc.Row do |xml_row|
      if generic_page.type_cd == Settings.GENERICPAGE_TYPECD_COMPOUNDCODE
        # parent question
        xml_row.parent_question_num I18n.t("materials_administration.MAT_ADM_COMPOUND_CSV_DOWNLOAD_HEADER2")
        xml_row.parent_content I18n.t("materials_administration.MAT_ADM_COMPOUND_CSV_DOWNLOAD_HEADER3")

        #question
        xml_row.question_num I18n.t("materials_administration.MAT_ADM_COMPOUND_CSV_DOWNLOAD_HEADER4")
        xml_row.content I18n.t("materials_administration.MAT_ADM_COMPOUND_CSV_DOWNLOAD_HEADER5")
        xml_row.must_flg I18n.t("materials_administration.MAT_ADM_COMPOUND_CSV_DOWNLOAD_HEADER6")
        xml_row.score I18n.t("materials_administration.MAT_ADM_COMPOUND_CSV_DOWNLOAD_HEADER7")
        xml_row.view_rank I18n.t("materials_administration.MAT_ADM_COMPOUND_CSV_DOWNLOAD_HEADER8")
        xml_row.pattern_cd I18n.t("materials_administration.MAT_ADM_COMPOUND_CSV_DOWNLOAD_HEADER9")
        xml_row.text_row I18n.t("materials_administration.MAT_ADM_COMPOUND_CSV_DOWNLOAD_HEADER10")
        xml_row.answer_memo I18n.t("materials_administration.MAT_ADM_COMPOUND_CSV_DOWNLOAD_HEADER11")
        xml_row.correct_answer_memo I18n.t("materials_administration.MAT_ADM_COMPOUND_CSV_DOWNLOAD_HEADER12")
        xml_row.wrong_answer_memo I18n.t("materials_administration.MAT_ADM_COMPOUND_CSV_DOWNLOAD_HEADER13")

        xml_row.sel1_content I18n.t("materials_administration.MAT_ADM_COMPOUND_CSV_DOWNLOAD_HEADER14")
        xml_row.sel1_select_correct_flg I18n.t("materials_administration.MAT_ADM_COMPOUND_CSV_DOWNLOAD_HEADER18")
        xml_row.sel1_select_mark_flg I18n.t("materials_administration.MAT_ADM_COMPOUND_CSV_DOWNLOAD_HEADER19")

        xml_row.sel1_content I18n.t("materials_administration.MAT_ADM_COMPOUND_CSV_DOWNLOAD_HEADER15")
        xml_row.sel1_select_correct_flg I18n.t("materials_administration.MAT_ADM_COMPOUND_CSV_DOWNLOAD_HEADER18")
        xml_row.sel1_select_mark_flg I18n.t("materials_administration.MAT_ADM_COMPOUND_CSV_DOWNLOAD_HEADER19")

        xml_row.sel1_content I18n.t("materials_administration.MAT_ADM_COMPOUND_CSV_DOWNLOAD_HEADER16")
        xml_row.sel1_select_correct_flg I18n.t("materials_administration.MAT_ADM_COMPOUND_CSV_DOWNLOAD_HEADER18")
        xml_row.sel1_select_mark_flg I18n.t("materials_administration.MAT_ADM_COMPOUND_CSV_DOWNLOAD_HEADER19")

        xml_row.sel1_content I18n.t("materials_administration.MAT_ADM_COMPOUND_CSV_DOWNLOAD_HEADER17")
        xml_row.sel1_select_correct_flg I18n.t("materials_administration.MAT_ADM_COMPOUND_CSV_DOWNLOAD_HEADER18")
        xml_row.sel1_select_mark_flg I18n.t("materials_administration.MAT_ADM_COMPOUND_CSV_DOWNLOAD_HEADER19")
      else
        # parent question
        xml_row.parent_question_num I18n.t("materials_administration.MAT_ADM__QUESTIONNAIRE_CSV_DOWNLOAD_HEADER2")
        xml_row.parent_content I18n.t("materials_administration.MAT_ADM_QUESTIONNAIRE_CSV_DOWNLOAD_HEADER3")

        #question
        xml_row.question_num I18n.t("materials_administration.MAT_ADM_QUESTIONNAIRE_CSV_DOWNLOAD_HEADER4")
        xml_row.content I18n.t("materials_administration.MAT_ADM_QUESTIONNAIRE_CSV_DOWNLOAD_HEADER5")
        xml_row.must_flg I18n.t("materials_administration.MAT_ADM_QUESTIONNAIRE_CSV_DOWNLOAD_HEADER6")
        xml_row.score I18n.t("materials_administration.MAT_ADM_QUESTIONNAIRE_CSV_DOWNLOAD_HEADER7")
        xml_row.view_rank I18n.t("materials_administration.MAT_ADM_QUESTIONNAIRE_CSV_DOWNLOAD_HEADER8")
        xml_row.pattern_cd I18n.t("materials_administration.MAT_ADM_QUESTIONNAIRE_CSV_DOWNLOAD_HEADER9")
        xml_row.text_row I18n.t("materials_administration.MAT_ADM_QUESTIONNAIRE_CSV_DOWNLOAD_HEADER10")
        xml_row.answer_memo I18n.t("materials_administration.MAT_ADM_QUESTIONNAIRE_CSV_DOWNLOAD_HEADER11")
        xml_row.correct_answer_memo I18n.t("materials_administration.MAT_ADM_QUESTIONNAIRE_CSV_DOWNLOAD_HEADER12")
        xml_row.wrong_answer_memo I18n.t("materials_administration.MAT_ADM_QUESTIONNAIRE_CSV_DOWNLOAD_HEADER13")

        xml_row.sel1_content I18n.t("materials_administration.MAT_ADM_QUESTIONNAIRE_CSV_DOWNLOAD_HEADER14")
        xml_row.sel1_select_correct_flg I18n.t("materials_administration.MAT_ADM_QUESTIONNAIRE_CSV_DOWNLOAD_HEADER18")
        xml_row.sel1_select_mark_flg I18n.t("materials_administration.MAT_ADM_QUESTIONNAIRE_CSV_DOWNLOAD_HEADER19")

        xml_row.sel1_content I18n.t("materials_administration.MAT_ADM_QUESTIONNAIRE_CSV_DOWNLOAD_HEADER15")
        xml_row.sel1_select_correct_flg I18n.t("materials_administration.MAT_ADM_QUESTIONNAIRE_CSV_DOWNLOAD_HEADER18")
        xml_row.sel1_select_mark_flg I18n.t("materials_administration.MAT_ADM_QUESTIONNAIRE_CSV_DOWNLOAD_HEADER19")

        xml_row.sel1_content I18n.t("materials_administration.MAT_ADM_QUESTIONNAIRE_CSV_DOWNLOAD_HEADER16")
        xml_row.sel1_select_correct_flg I18n.t("materials_administration.MAT_ADM_QUESTIONNAIRE_CSV_DOWNLOAD_HEADER18")
        xml_row.sel1_select_mark_flg I18n.t("materials_administration.MAT_ADM_QUESTIONNAIRE_CSV_DOWNLOAD_HEADER19")

        xml_row.sel1_content I18n.t("materials_administration.MAT_ADM_QUESTIONNAIRE_CSV_DOWNLOAD_HEADER17")
        xml_row.sel1_select_correct_flg I18n.t("materials_administration.MAT_ADM_QUESTIONNAIRE_CSV_DOWNLOAD_HEADER18")
        xml_row.sel1_select_mark_flg I18n.t("materials_administration.MAT_ADM_QUESTIONNAIRE_CSV_DOWNLOAD_HEADER19")
      end
    end
  end

  def sample_csv_file(generic_page)
    bom = %w(EF BB BF).map { |e| e.hex.chr }.join
    csv_data = CSV.generate(bom) do |csv|
      if generic_page.type_cd == Settings.GENERICPAGE_TYPECD_COMPOUNDCODE
        csv << [I18n.t("materials_administration.MAT_ADM_COMPOUND_CSV_DOWNLOAD_HEADER1")]
        csv << [""]
        csv << [I18n.t("materials_administration.MAT_ADM_COMPOUND_CSV_DOWNLOAD_HEADER_EXPLANATION1")]
        csv << [I18n.t("materials_administration.MAT_ADM_COMPOUND_CSV_DOWNLOAD_HEADER_EXPLANATION2")]
        csv << [I18n.t("materials_administration.MAT_ADM_COMPOUND_CSV_DOWNLOAD_HEADER_EXPLANATION3")]
        csv << [I18n.t("materials_administration.MAT_ADM_COMPOUND_CSV_DOWNLOAD_HEADER_EXPLANATION4")]
        csv << [I18n.t("materials_administration.MAT_ADM_COMPOUND_CSV_DOWNLOAD_HEADER_EXPLANATION5")]
        csv << [I18n.t("materials_administration.MAT_ADM_COMPOUND_CSV_DOWNLOAD_HEADER_EXPLANATION6")]
        csv << [I18n.t("materials_administration.MAT_ADM_COMPOUND_CSV_DOWNLOAD_HEADER_EXPLANATION7")]
        csv << [I18n.t("materials_administration.MAT_ADM_COMPOUND_CSV_DOWNLOAD_HEADER_EXPLANATION8")]
        csv << [I18n.t("materials_administration.MAT_ADM_COMPOUND_CSV_DOWNLOAD_HEADER_EXPLANATION9")]
        csv << [I18n.t("materials_administration.MAT_ADM_COMPOUND_CSV_DOWNLOAD_HEADER_EXPLANATION10")]
        csv << [I18n.t("materials_administration.MAT_ADM_COMPOUND_CSV_DOWNLOAD_HEADER_EXPLANATION11")]
        csv << [I18n.t("materials_administration.MAT_ADM_COMPOUND_CSV_DOWNLOAD_HEADER_EXPLANATION12")]
        csv << [I18n.t("materials_administration.MAT_ADM_COMPOUND_CSV_DOWNLOAD_HEADER_EXPLANATION13")]
        csv << [I18n.t("materials_administration.MAT_ADM_COMPOUND_CSV_DOWNLOAD_HEADER_EXPLANATION14")]
        csv << [I18n.t("materials_administration.MAT_ADM_COMPOUND_CSV_DOWNLOAD_HEADER_EXPLANATION15")]
        csv << [I18n.t("materials_administration.MAT_ADM_COMPOUND_CSV_DOWNLOAD_HEADER_EXPLANATION16")]
        csv << [I18n.t("materials_administration.MAT_ADM_COMPOUND_CSV_DOWNLOAD_HEADER_EXPLANATION17")]
        csv << [I18n.t("materials_administration.MAT_ADM_COMPOUND_CSV_DOWNLOAD_HEADER_EXPLANATION18")]
        csv << [""]
      else
        csv << ["#{I18n.t('materials_administration.MAT_ADM_QUESTIONNAIRE_CSV_DOWNLOAD_HEADER1')}"]
        csv << []
        csv << ["#{I18n.t('materials_administration.MAT_ADM_QUESTIONNAIRE_CSV_DOWNLOAD_HEADER_EXPLANATION1')}"]
        csv << ["#{I18n.t('materials_administration.MAT_ADM_QUESTIONNAIRE_CSV_DOWNLOAD_HEADER_EXPLANATION2')}"]
        csv << ["#{I18n.t('materials_administration.MAT_ADM_QUESTIONNAIRE_CSV_DOWNLOAD_HEADER_EXPLANATION3')}"]
        csv << ["#{I18n.t('materials_administration.MAT_ADM_QUESTIONNAIRE_CSV_DOWNLOAD_HEADER_EXPLANATION4')}"]
        csv << ["#{I18n.t('materials_administration.MAT_ADM_QUESTIONNAIRE_CSV_DOWNLOAD_HEADER_EXPLANATION5')}"]
        csv << ["#{I18n.t('materials_administration.MAT_ADM_QUESTIONNAIRE_CSV_DOWNLOAD_HEADER_EXPLANATION6')}"]
        csv << ["#{I18n.t('materials_administration.MAT_ADM_QUESTIONNAIRE_CSV_DOWNLOAD_HEADER_EXPLANATION7')}"]
        csv << ["#{I18n.t('materials_administration.MAT_ADM_QUESTIONNAIRE_CSV_DOWNLOAD_HEADER_EXPLANATION8')}"]
        csv << ["#{I18n.t('materials_administration.MAT_ADM_QUESTIONNAIRE_CSV_DOWNLOAD_HEADER_EXPLANATION9')}"]
        csv << ["#{I18n.t('materials_administration.MAT_ADM_QUESTIONNAIRE_CSV_DOWNLOAD_HEADER_EXPLANATION10')}"]
        csv << ["#{I18n.t('materials_administration.MAT_ADM_QUESTIONNAIRE_CSV_DOWNLOAD_HEADER_EXPLANATION11')}"]
        csv << ["#{I18n.t('materials_administration.MAT_ADM_QUESTIONNAIRE_CSV_DOWNLOAD_HEADER_EXPLANATION12')}"]
        csv << ["#{I18n.t('materials_administration.MAT_ADM_QUESTIONNAIRE_CSV_DOWNLOAD_HEADER_EXPLANATION13')}"]
        csv << ["#{I18n.t('materials_administration.MAT_ADM_QUESTIONNAIRE_CSV_DOWNLOAD_HEADER_EXPLANATION14')}"]
        csv << ["#{I18n.t('materials_administration.MAT_ADM_QUESTIONNAIRE_CSV_DOWNLOAD_HEADER_EXPLANATION15')}"]
        csv << ["#{I18n.t('materials_administration.MAT_ADM_QUESTIONNAIRE_CSV_DOWNLOAD_HEADER_EXPLANATION16')}"]
        csv << ["#{I18n.t('materials_administration.MAT_ADM_QUESTIONNAIRE_CSV_DOWNLOAD_HEADER_EXPLANATION17')}"]
        csv << ["#{I18n.t('materials_administration.MAT_ADM_QUESTIONNAIRE_CSV_DOWNLOAD_HEADER_EXPLANATION18')}"]
        csv << []
      end
      line_head = []
      line = []
      CSV_FIELDS.each do |key, value|
        line_head << key
        line << value
      end
      csv << line_head
      csv << line
    end

    send_data csv_data, filename: SAMPLE_CSV_FILE_NAME
  end
end
