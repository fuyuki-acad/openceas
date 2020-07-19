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

class Teacher::MaterialsController < ApplicationController
  before_action :require_assigned, only: [
    :show, :new, :create, :new_url, :select_course, :select_page, :copy, :select_url_course, :select_url_page, :url_copy,
    :edit, :edit_url, :update, :download, :select_copy_to, :copy_to]
  before_action :set_courses, only: [:index]
  before_action :set_course, only: [:show, :new, :create, :new_url, :select_course, :select_page, :copy, :select_url_course, :select_url_page, :url_copy]
  before_action :set_generic_page, only: [:edit, :edit_url, :update, :download, :select_copy_to, :copy_to]

  def index
  end

  def show
  end

  def new
    @generic_page = GenericPage.new()
    @generic_page.course = @course
    @generic_page.type_cd = Settings.GENERICPAGE_TYPECD_MATERIALCODE
  end

  def new_url
    new
    @generic_page.type_cd = Settings.GENERICPAGE_TYPECD_URLCODE
  end

  def create
    begin
      @generic_page = GenericPage.new(generic_page_params)
      raise unless @generic_page.valid?

      case @generic_page.upload_flag
      when GenericPage::TYPE_FILEUPLOAD
        if @generic_page.extract_flag == 'true'
          @generic_page.extract_file(@generic_page.file)
          @generic_page.file_name = @generic_page.original_filename
          render action: :select_file
          return
        end

      when GenericPage::TYPE_CREATEHTML
        render action: :create_html
        return
      end

      unless params[:generic_page][:file].blank?
        @generic_page.file = params[:generic_page][:file]
      end
      raise unless @generic_page.save

      redirect_to action: :show, :course_id => @course

    rescue => e
      logger.error e.backtrace.join("\n")
      flash.now[:notice] = e.message unless e.message.blank?
      if params[:generic_page][:type_cd] == Settings.GENERICPAGE_TYPECD_URLCODE.to_s
        render action: :new_url
      else
        render action: :new
      end
    end
  end

  def select_file
    @generic_page = GenericPage.new(generic_page_params)
    if @generic_page.link_name.blank?
      flash.now[:notice] = I18n.t("page_management.MAT_REG_MAT_PAGEMANAGEMENT_ERRORTYPE2")
    else
      @generic_page.link_name = @generic_page.extract_path + @generic_page.link_name
      if @generic_page.save(validate: false)
        redirect_to action: :show, :course_id => @generic_page.course
      end
    end
  end

  def create_html
    @generic_page = GenericPage.new(generic_page_params)
    if @generic_page.html_text.blank?
      flash[:notice] = I18n.t("page_management.MAT_REG_MAT_CREATEPAGEMANAGEMENT_ERRORTYPE1")
    else
      flash[:notice] = nil
      if @generic_page.save
        redirect_to action: :show, :course_id => @generic_page.course
      end
    end
  end

  def update
    begin
      current_file = @generic_page.link_name
      unless params[:generic_page][:file].blank?
        @generic_page.file = params[:generic_page][:file]
      end
      raise unless @generic_page.update(generic_page_params)

      redirect_to action: :show, :course_id => @generic_page.course

    rescue => e
      logger.error e.backtrace.join("\n")
      flash.now[:notice] = e.message unless e.message.blank?
      if params[:generic_page][:type_cd] == Settings.GENERICPAGE_TYPECD_URLCODE.to_s
        render action: :edit_url
      else
        render action: :edit
      end
    end
  end

  def destroy
    items = params[:material].keys if params[:material]
    items = params[:url].keys if params[:url]
    GenericPage.destroy(items) if items.count > 0

    redirect_to :action => :show, :course_id => params[:course_id]
  end

  def download
    file_path = @generic_page.get_material_path + @generic_page.link_name
    if File.exist?(file_path)
      file_stat = File::stat(file_path)
      send_file(file_path, :filename => @generic_page.file_name, :length => file_stat.size)
    else
      render text: t("page_management.MAT_COM_MYFOLDER_NOCONTENTS")
    end
  end

  def help2
    render layout: false
  end

  def select_course
    if current_user.admin?
      @other_courses = Course.order("school_year DESC, day_cd, hour_cd, season_cd").
        where("courses.id != ? AND course_name LIKE ?", params[:course_id], "%#{params[:course_name]}%").
        page(params[:page])
    else
      @other_courses = Course.order("school_year DESC, day_cd, hour_cd, season_cd").
        joins(:course_assigned_users).
        where("user_id = ? AND courses.id != ? AND course_name LIKE ?", current_user.id, params[:course_id], "%#{params[:course_name]}%").
        page(params[:page])
    end
  end

  def select_page
    @origin = Course.find(params[:origin_id])
  end

  def copy
    if params[:material] && params[:material].to_unsafe_h.count > 0
      ActiveRecord::Base.transaction do
        params[:material].to_unsafe_h.keys.each do |material|
          old_object = GenericPage.find(material)
          new_object = old_object.copy(@course)
          new_object.save!
        end
      end

      redirect_to :action => :show, :course_id => params[:course_id]
    else
      redirect_to :action => :select_page, :course_id => params[:course_id], :origin_id => params[:origin_id]
    end

  rescue => e
    logger.error e.backtrace.join("\n")
    redirect_to teacher_select_page_material_path(@course.id, params[:origin_id]), notice: e.message
  end

  def select_url_course
    select_course
  end

  def select_url_page
    select_page
  end

  def url_copy
    if params[:url] && params[:url].to_unsafe_h.count > 0
      ActiveRecord::Base.transaction do
        params[:url].to_unsafe_h.keys.each do |url|
          old_object = GenericPage.find(url)
          new_object = old_object.copy(@course)
          new_object.save!
        end
      end

      redirect_to :action => :show, :course_id => params[:course_id]
    else
      redirect_to :action => :select_url_page, :course_id => params[:course_id], :origin_id => params[:origin_id]
    end

  rescue => e
    logger.error e.backtrace.join("\n")
    redirect_to teacher_select_url_page_material_path(@course.id, params[:origin_id]), notice: e.message
  end

  def select_copy_to
    if current_user.admin?
      @other_courses = Course.order("school_year DESC, day_cd, hour_cd, season_cd").
        where("courses.id != ? AND course_name LIKE ?", @generic_page.course.id, "%#{params[:course_name]}%").
        page(params[:page])
    else
      @other_courses = Course.order("school_year DESC, day_cd, hour_cd, season_cd").
        joins(:course_assigned_users).
        where("user_id = ? AND courses.id != ? AND course_name LIKE ?", current_user.id, @generic_page.course.id, "%#{params[:course_name]}%").
        page(params[:page])
    end
  end

  def copy_to
    if params[:dest] && params[:dest].to_unsafe_h.count > 0
      ActiveRecord::Base.transaction do
        params[:dest].to_unsafe_h.keys.each do |dest|
          dest_course = Course.find(dest)
          new_object = @generic_page.copy(dest_course)
          new_object.save!
        end
      end

      redirect_to :action => :show, :course_id => @generic_page.course.id
    else
      redirect_to :action => :select_copy_to, :id => @generic_page.id
    end

  rescue => e
    logger.error e.backtrace.join("\n")
    redirect_to teacher_select_copy_to_material_path(@generic_page.id), notice: e.message
  end

  private
    def set_generic_page
      @generic_page = GenericPage.find(params[:id])
    end

    def generic_page_params
      params.require(:generic_page).permit(:course_id, :type_cd, :generic_page_title, :upload_flag,
        :file, :file_name, :extract_flag, :link_name, :url_content, :material_memo_closed, :material_memo,
        :extract_path, :html_text, :content)
    end
end
