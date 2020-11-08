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

class Teacher::QuestionnairesController < ApplicationController
  include MaterialFileModule

  before_action :require_assigned, only: [
    :show, :new, :create, :select_course, :select_page, :copy, :select_upload_file, :confirm_upload_file, :upload_file,
    :edit, :update, :destroy_file, :download]
  before_action :set_courses, only: [:index]
  before_action :set_course, only: [:show, :new, :create, :select_course, :select_page, :copy, :select_upload_file, :confirm_upload_file, :upload_file]
  before_action :set_generic_page, only: [:edit, :update, :destroy_file, :download]

  def new
    @generic_page = GenericPage.new()
    @generic_page.course = @course
    @generic_page.type_cd = Settings.GENERICPAGE_TYPECD_QUESTIONNAIRECODE
    @generic_page.edit_flag = 0
    @generic_page.anonymous_flag = 0
  end

  def create
    @generic_page = GenericPage.new(generic_page_params)
    if @generic_page.save
      redirect_to action: :show, :course_id => @generic_page.course
    else
      render action: :new
    end
  end

  def update
    if @generic_page.update(generic_page_params)
      redirect_to action: :show, :course_id => @generic_page.course
    else
      render action: :edit
    end
  end

  def destroy
    items = params[:questionnaire].keys if params[:questionnaire]
    GenericPage.destroy(items)

    redirect_to :action => :show, :course_id => params[:course_id]
  end

  def destroy_file
    @generic_page.destroy_file

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
    if params[:questionnaire] && params[:questionnaire].to_unsafe_h.count > 0
      ActiveRecord::Base.transaction do
        params[:questionnaire].to_unsafe_h.keys.each do |compound|
          old_object = GenericPage.find(compound)
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
    redirect_to teacher_select_page_questionnaire_path(@course.id, params[:origin_id]), notice: e.message
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
        @generic_page = import(@course, session[:material_file_path], Settings.GENERICPAGE_TYPECD_QUESTIONNAIRECODE)
      end
      render :finish_upload_file
    end

    session[:material_file_path] = nil

  rescue => e
    logger.error e.backtrace.join("\n")
    flash[:notice] = I18n.t("materials_registration.COMMONMATERIALSREGISTRATION_ERRORUPLOADQUESTIONNAIRE1") + I18n.t("materials_registration.COMMONMATERIALSREGISTRATION_ERRORUPLOAD1_html")
    render :select_upload_file
  end

  private
    def set_generic_page
      @generic_page = GenericPage.find(params[:id])
    end

    def generic_page_params
      params.require(:generic_page).permit(:course_id, :type_cd, :generic_page_title,
        :file, :start_pass, :start_time, :end_time, :edit_flag,
        :anonymous_flag, :material_memo)
    end

    def material_file_params
      params.require(:material_file).permit(:file)
    end
end
