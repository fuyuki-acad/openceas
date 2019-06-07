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

class Teacher::QuestionsController < ApplicationController
  include QuestionFileModule

  before_action :set_generic_page, only: [:show, :create_parent, :edit_parent, :update_parent,
    :new, :create, :edit, :update, :confirm, :destroy, :select_upload, :confirm_upload, :upload, :download, :sample_xml, :sample_csv]
  before_action :set_question, only: [:edit_parent, :update_parent, :edit, :update]

  MAX_VIEW_RANK = 2147483647

  def show
    @question = Question.new
  end

  def create_parent
    @question = Question.new(question_params)
    @question.pattern_cd = Settings.QUESTION_PATTERNCD_PARENTQUESTION
    @question.shuffle_flag = Settings.QUESTION_SHUFFLEFLG_OFF
    @question.answer_in_full_cd = Settings.QUESTION_ANSWERINFULLCD_NOTANSWERINFULL
    Question.transaction do
      @question.save!
      @generic_page.questions << @question

      redirect_to action: :show, :generic_page_id => @generic_page
    end

  rescue => e
    logger.error e.backtrace.join("\n")
    render action: :show
  end

  def edit_parent
  end

  def update_parent
    if @question.update(question_params)
      redirect_to action: :show, :generic_page_id => @generic_page
    else
      render action: :edit_parent
    end
  end

  def new
    parent = Question.find(params[:parent_id])
    @question = Question.new
    @question.parent = parent
    @question.pattern_cd = Settings.QUESTION_PATTERNCD_RADIO
    @question.text_count = Question::DEFAULT_SELECT_COUNT
    @question.text_flag = Settings.SELECT_TEXTROW_TEXT
  end

  def edit
  end

  def create
    @question = Question.new(question_params)
    @question.parent_question_id = params[:parent_id]
    @question.generic_page_type_cd = @generic_page.type_cd
    @question.text_flag = question_params[:text_flag]
    max_rank = Question.where(:parent_question_id => params[:parent_id]).maximum(:view_rank)
    if max_rank.blank?
      @question.view_rank = 1
    elsif max_rank < MAX_VIEW_RANK
      @question.view_rank = max_rank + 1
    else
      @question.view_rank = MAX_VIEW_RANK
    end
    if @question.save
      redirect_to action: :show, :generic_page_id => @generic_page
    else
      render action: :new
    end
  end

  def update
    @question.generic_page_type_cd = @generic_page.type_cd
    quiz_ids = []
    params[:question][:quizzes_attributes].each do |key, value|
      unless value[:id].blank?
        quiz_ids << value[:id]
        params[:question][:quizzes_attributes][key][:select_correct_flag] = false unless params[:question][:quizzes_attributes][key][:select_correct_flag]
        params[:question][:quizzes_attributes][key][:select_mark_flag] = false unless params[:question][:quizzes_attributes][key][:select_mark_flag]
      end
    end
    @question.all_quizzes.each do |quiz|
      quiz.destroy unless quiz_ids.include?(quiz.id.to_s)
    end

    if @question.update(question_params)
      redirect_to action: :show, :generic_page_id => @generic_page
    else
      render action: :edit
    end
  end

  def destroy
    if params[:question].blank?
      items = [params[:parent_id]]
    else
      items = params[:question][params[:parent_id]].keys
    end
    Question.destroy(items) if items.count > 0

    redirect_to :action => :show, :generic_page_id => params[:generic_page_id]

  rescue => e
    logger.error e.backtrace.join("\n")
    flash[:notice] = e.message
    render :show
  end

  def update_order
    ActiveRecord::Base.transaction do
      params[:question].each.with_index(1) do |id, index|
        question = Question.find(id)
        question.update_attribute(:view_rank, index)
      end
    end

    redirect_to :action => :show, :generic_page_id => params[:generic_page_id]
  end

  def confirm
    @answers = {}
    if @generic_page.type_cd == Settings.GENERICPAGE_TYPECD_COMPOUNDCODE
      render "compounds/show"
    elsif @generic_page.type_cd == Settings.GENERICPAGE_TYPECD_QUESTIONNAIRECODE
      @is_view_only = true
      render "questionnaires/show"
    end
  end

  def download
    question_xml = get_xml_questions(@generic_page)
    if @generic_page.type_cd == Settings.GENERICPAGE_TYPECD_COMPOUNDCODE
      file_name = "compound_" + SAMPLE_XML_FILE_NAME
    else
      file_name = "questionnaire_" + SAMPLE_XML_FILE_NAME
    end
    send_data(question_xml, type: 'text/xml', disposition: 'attachment', :filename => file_name)
  end

  def select_upload
    question_file = QuestionFile.new
  end

  def confirm_upload
    @question_file = QuestionFile.new(question_file_params)
    if @question_file.valid?
      if @question_file.xml?
        @questions = xml_to_hash(@generic_page, @question_file.file)
      else
        @questions = csv_to_hash(@generic_page, @question_file.file)
      end

      raise I18n.t("materials_registration.ERROR_NO_QUESTION") if @questions.count == 0

      if has_upload_error?
        render :upload_error
      else
        session[:question_data] = @questions
      end
    else
      render :select_upload
    end

  rescue => e
    logger.error e.backtrace.join("\n")
    flash[:notice] = e.message
    render :select_upload
  end

  def upload
    if session[:question_data].blank?
      render :select_upload
    else
      ActiveRecord::Base.transaction do
        import_questoins(@generic_page, session[:question_data])
      end

      render :finish_upload
    end

    session[:question_data] = nil

  rescue => e
    logger.error e.backtrace.join("\n")
    flash[:notice] = I18n.t("materials_registration.COMMONMATERIALSREGISTRATION_ERRORUPLOADCOMPOUND1") + I18n.t("materials_registration.COMMONMATERIALSREGISTRATION_ERRORUPLOAD1_html")
    render :select_upload
  end

  def sample_xml
    send_data(sample_xml_file(@generic_page), type: 'text/xml', disposition: 'attachment', :filename => SAMPLE_XML_FILE_NAME)
  end

  def sample_csv
    sample_csv_file(@generic_page)
  end

  private
    def set_generic_page
      @generic_page = GenericPage.find(params[:generic_page_id])
    end

    def set_question
      @question = Question.find(params[:id])
    end

    def question_params
      params.require(:question).permit(:parent_id, :content, :text_count, :score, :must_flag,
      :pattern_cd, :correct_answer_memo, :wrong_answer_memo, :answer_memo, :text_row, :text_flag,
      :quizzes_attributes => [:id, :content, :select_correct_flag, :select_mark_flag])
    end

    def question_file_params
      params.require(:question_file).permit(:file)
    end
end
