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

class Teacher::MultiplefibsController < ApplicationController
  include MaterialFileModule

  before_action :require_assigned, only: [
    :show, :new, :create, :destroy, :select_course, :select_page, :copy, :select_upload_file, :confirm_upload_file, :upload_file,
    :edit, :update, :edit_html, :update_html, :destory, :destroy_file, :download]
  before_action :set_courses, only: [:index]
  before_action :set_course, only: [:show, :new, :create, :destroy, :select_course, :select_page, :copy, :select_upload_file, :confirm_upload_file, :upload_file]
  before_action :set_generic_page, only: [:edit, :update, :edit_html, :update_html, :destory, :destroy_file, :download]

  def index
  end

  def new
    @generic_page = Multiplefib.new
    @generic_page.course = @course
    @generic_page.type_cd = Settings.GENERICPAGE_TYPECD_MULTIPLEFIBCODE
    @generic_page.pass_grade = 60

    @azure_video = AzureVideo.new
    @azure_explanation = AzureVideo.new
  end

  def create
    begin
      @generic_page = Multiplefib.new(generic_page_params)
      @azure_video = AzureVideo.new(azure_question_params[:azure_video][:question])
      @azure_explanation = AzureVideo.new(azure_explanation_params[:azure_video][:explanation])
      @generic_page.azure_video = @azure_video
      @generic_page.azure_explanation = @azure_explanation
      raise unless @generic_page.valid?

      @generic_page.azure_video = nil unless @generic_page.upload_flag == Multiplefib::TYPE_AZURE_VIDEO
      @generic_page.azure_explanation = nil unless @generic_page.explanation_flag == Multiplefib::TYPE_AZURE_VIDEO

      if @generic_page.upload_flag == Multiplefib::TYPE_CREATEHTML
        @course = Course.find(@generic_page.course_id)
        render action: :create_html
        return
      end

      unless params[:generic_page][:file].blank?
        @generic_page.file = params[:generic_page][:file]
      end

      @generic_page.transaction do
        raise unless @generic_page.save
      end

      redirect_to action: :show, :course_id => @generic_page.course

    rescue => e
      logger.error e.backtrace.join("\n")
      flash.now[:notice] = e.message unless e.message.blank?
      render action: :new
    end
  end

  def edit
    if @generic_page.azure_video
      @generic_page.upload_flag = Multiplefib::TYPE_AZURE_VIDEO
      @azure_video = @generic_page.azure_video
    end
    if @generic_page.azure_explanation
      @generic_page.explanation_flag = Multiplefib::TYPE_AZURE_VIDEO
      @azure_explanation = @generic_page.azure_explanation
    end
  end

  def update
    if @generic_page.azure_video
      @generic_page.upload_flag = Multiplefib::TYPE_AZURE_VIDEO
      azure_video = azure_question_params[:azure_video][:question]
      @generic_page.azure_video.video_url = azure_video[:video_url]
      @generic_page.azure_video.forwarding = azure_video[:forwarding]
      @generic_page.azure_video.forwarding_url = azure_video[:forwarding_url]
      @generic_page.azure_video.init_message = azure_video[:init_message]
      @generic_page.azure_video.firstquartile_message = azure_video[:firstquartile_message]
      @generic_page.azure_video.midpoint_message = azure_video[:midpoint_message]
      @generic_page.azure_video.thirdquartile_message = azure_video[:thirdquartile_message]
      @generic_page.azure_video.ended_message = azure_video[:ended_message]
      @generic_page.azure_video.panel_display = azure_video[:panel_display]
    end
    if @generic_page.azure_explanation
      @generic_page.explanation_flag = Multiplefib::TYPE_AZURE_VIDEO
      azure_explanation = azure_explanation_params[:azure_video][:explanation]
      @generic_page.azure_explanation.video_url = azure_explanation[:video_url]
      @generic_page.azure_explanation.forwarding = azure_explanation[:forwarding]
      @generic_page.azure_explanation.forwarding_url = azure_explanation[:forwarding_url]
      @generic_page.azure_explanation.init_message = azure_explanation[:init_message]
      @generic_page.azure_explanation.firstquartile_message = azure_explanation[:firstquartile_message]
      @generic_page.azure_explanation.midpoint_message = azure_explanation[:midpoint_message]
      @generic_page.azure_explanation.thirdquartile_message = azure_explanation[:thirdquartile_message]
      @generic_page.azure_explanation.ended_message = azure_explanation[:ended_message]
      @generic_page.azure_explanation.panel_display = azure_explanation[:panel_display]
    end
    begin
      AzureVideo.transaction do
        if @generic_page.update(generic_page_params)
          if @generic_page.azure_video
            @generic_page.azure_video.update(azure_question_params[:azure_video][:question])
          end
          if @generic_page.azure_explanation
            @generic_page.azure_explanation.update(azure_explanation_params[:azure_video][:explanation])
          end
        else
          raise
        end
      end
      redirect_to action: :show, :course_id => @generic_page.course

    rescue => e
      if @generic_page.azure_video
        @azure_video = AzureVideo.new(azure_question_params[:azure_video][:question])
      end
      if @generic_page.azure_explanation
        @azure_explanation = AzureVideo.new(azure_explanation_params[:azure_video][:explanation])
      end
      render action: :edit
    end
  end

  def create_html
    @generic_page = Multiplefib.new(generic_page_params)
    if @generic_page.save
      redirect_to action: :show, :course_id => @generic_page.course
    end
  end

  def edit_html
    @generic_page.html_text = @generic_page.get_html_file
    @course = @generic_page.course
  end

  def update_html
    if @generic_page.update(generic_page_params)
      redirect_to action: :show, :course_id => @generic_page.course
    else
      render action: :edit_html
    end
  end

  def destroy
    items = params[:multiplefib].keys if params[:multiplefib]
    Multiplefib.destroy(items) if items.count > 0

    redirect_to :action => :show, :course_id => params[:course_id]
  end

  def destroy_file
    @generic_page.delete_explanation_file

    redirect_to :action => :edit, :id => @generic_page
  end

  def select_course
    if current_user.admin?
      @other_courses = Course.order(VIEW_COUSE_ORER).
        where("courses.id != ? AND course_name LIKE ?", params[:course_id], "%#{params[:course_name]}%").
        page(params[:page])
    else
      @other_courses = Course.order(VIEW_COUSE_ORER).
        joins(:course_assigned_users).
        where("user_id = ? AND courses.id != ? AND course_name LIKE ?", current_user.id, params[:course_id], "%#{params[:course_name]}%").
        page(params[:page])
    end
  end

  def select_page
    @origin = Course.find(params[:origin_id])
  end

  def copy
    if params[:multiplefib] && params[:multiplefib].to_unsafe_h.count > 0
      ActiveRecord::Base.transaction do
        params[:multiplefib].to_unsafe_h.keys.each do |multiplefib|
          old_object = Multiplefib.find(multiplefib)
          new_object = old_object.copy(@course)
          new_object.save!

          new_object.copy_questions(old_object)
        end
      end

      redirect_to :action => :show, :course_id => params[:course_id]
    else
      redirect_to :action => :select_page, :course_id => params[:course_id], :origin_id => params[:origin_id]
    end

  rescue => e
    logger.error e.backtrace.join("\n")
    redirect_to teacher_select_page_multiplefib_path(@generic_page.id, params[:origin_id]), notice: e.message
  end

  def download
    begin
      zip_data = create_xml_and_compress(@generic_page)
      send_data(zip_data, :type => 'application/zip', :dispositon => 'attachment', :filename => ZIP_FILE_NAME)
    ensure
      clean_up_data
    end
  end

  def select_upload_file
    @material = MaterialFile.new()
  end

  def confirm_upload_file
    @material = MaterialFile.new(material_file_params)
    if @material.valid?
      extract_path = extract_file(@material.file)
      session[:material_file_path] = extract_path
    else
      render :select_upload_file
    end
  end

  def upload_file
    if session[:material_file_path].blank?
      render :select_upload_file
    else
      ActiveRecord::Base.transaction do
        @generic_page = import(@course, session[:material_file_path], Settings.GENERICPAGE_TYPECD_MULTIPLEFIBCODE)
      end
      render :finish_upload_file
    end

    session[:material_file_path] = nil

  rescue => e
    logger.error e.backtrace.join("\n")
    flash[:notice] = I18n.t("materials_registration.COMMONMATERIALSREGISTRATION_ERRORUPLOADMULTIPLEFIB1") + I18n.t("materials_registration.COMMONMATERIALSREGISTRATION_ERRORUPLOAD1_html")
    render :select_upload_file
  end

  private
    def set_generic_page
      @generic_page = Multiplefib.find(params[:id])
    end

    def generic_page_params
      params.require(:generic_page).permit(:course_id, :type_cd, :generic_page_title, :upload_flag, :explanation_flag,
        :max_count, :pass_grade, :file, :explanation_file, :start_pass, :start_time, :end_time, :material_memo, :html_text)
    end

    def azure_question_params
      params.require("generic_page").permit(azure_video: [question: [:video_type, :video_url, :forwarding, :forwarding_url, :init_message, :firstquartile_message, :midpoint_message, :thirdquartile_message, :ended_message, :panel_display]])
    end

    def azure_explanation_params
      params.require("generic_page").permit(azure_video: [explanation: [:video_type, :video_url, :forwarding, :forwarding_url, :init_message, :firstquartile_message, :midpoint_message, :thirdquartile_message, :ended_message, :panel_display]])
    end

    def material_file_params
      params.require(:material_file).permit(:file)
    end
end
