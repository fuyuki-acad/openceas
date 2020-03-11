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

require 'csv'
require 'nkf'

class Admin::CoursesController < ApplicationController
  before_action :set_course_local, only: [:edit, :update, :outputcsv_enrollment]

  def index
    sql_texts = []
    sql_params = {}

    if !params[:keyword].blank?
      case params[:type1]
      when "1"
        sql_texts.push("instructor_name like :keyword")
        sql_params[:keyword] = "%" + params[:keyword] + "%"
      when "2"
        sql_texts.push("course_cd like :keyword")
        sql_params[:keyword] = "%" + params[:keyword] + "%"
      else
        sql_texts.push("course_name like :keyword")
        sql_params[:keyword] = "%" + params[:keyword] + "%"
      end
    end

    if params[:day] && params[:day] != "0"
      sql_texts.push("day_cd = :day")
      sql_params[:day] = params[:day]
    end

    if params[:hour] && params[:hour] != "0"
      sql_texts.push("hour_cd = :hour")
      sql_params[:hour] = params[:hour]
    end

    if params[:school_year] && params[:school_year] != "0"
      sql_texts.push("school_year = :school_year")
      sql_params[:school_year] = params[:school_year]
    end

    if params[:season] && params[:season] != "0"
      sql_texts.push("season_cd = :season")
      sql_params[:season] = params[:season]
    end

    sql_texts.push("courseware_flag = :courseware_flag")
    sql_params[:courseware_flag] = "0"

    @courses = Course.where(sql_texts.join(" AND "), sql_params).order("school_year DESC, day_cd, hour_cd, season_cd").page(params[:page])
  end

  def new
    if params[:back] && session[:course]
      @course = Course.new(session[:course])
      session[:course] = nil
    else
      @course = Course.new
      @course.school_year = Time.zone.now.strftime('%Y')
      @course.season_cd = Settings.COURSE_SEASONCD_SPRING
      @course.day_cd = Settings.COURSE_DAYCD_MON
      @course.hour_cd = Settings.COURSE_HOURCD_FIRST
      @course.indirect_use_flag = Settings.COURSE_INDIRECTUSEFLG_DIRECT
      @course.term_flag = 1
      @course.open_course_flag = Settings.COURSE_OPENCOURSEFLG_PRIVATE
      @course.announcement_cd = 1
      @course.faq_cd = 1
      @course.unread_assignment_display_cd = 0
      @course.unread_faq_display_cd = 0
    end

    parent_course
  end

  def edit
    if params[:back] && session[:course]
      @course.assign_attributes(session[:course])
      session[:course] = nil
    end

    parent_course
  end

  def confirm
    if params[:id]
      set_course_local
      @course.assign_attributes(course_params)
    else
      @course = Course.new(course_params)
    end

    session[:course] = course_params
    unless @course.valid?
      session[:course] = nil
      parent_course
      if @course.new_record?
        render action: :new
      else
        render action: :edit
      end
    end
  end

  def create
    if session[:course]
      begin
        Course.transaction do
          @course = Course.new(session[:course])
          @course.save!
          create_class_sessions
          copy_users(@course, params)

          session[:course] = nil
          redirect_to action: :index
        end
      rescue => e
        logger.error e.backtrace.join("\n")
        flash.now[:notice] = e.message
        parent_course
        render action: :new
      end
    else
      parent_course
      render action: :new
    end
  end

  def update
    if session[:course]
      begin
        Course.transaction do
          @course.update!(session[:course])
          create_class_sessions
          copy_users(@course, params)

          session[:course] = nil
          redirect_to action: :index
        end
      rescue => e
        logger.error e.backtrace.join("\n")
        flash.now[:notice] = e.message
        parent_course
        render action: :edit
      end
    else
      parent_course
      render action: :edit
    end
  end

  def create_class_sessions
    for class_session_count in 0..@course.class_session_count
      unless @course.class_session(class_session_count)
        class_session = ClassSession.new
        class_session.course_id = @course.id
        class_session.class_session_no = class_session_count
        if class_session_count == 0
          class_session.class_session_day = I18n.t("select_class_session.MAT_ALL_SELECTCLASSSESSION_CLASSSESSIONOVERVIEWTEXT1")
        else
          class_session.class_session_day = "#{I18n.t("common.COMMON_NO2")}#{class_session_count}#{I18n.t("common.COMMON_COUNT2")}"
        end
        class_session.save!
      end
    end
  end

  def copy_users(course, form_params)
    if course.parent_course
      if form_params["form_copy_assigned"] == "true"
        if course.indirect_use_flag == Settings.COURSE_INDIRECTUSEFLG_DIRECT
          course.parent_course.assigned_users.each do |user|
            course.parent_course.enrolled_users.each do |user|
              if !CourseAssignedUser.exists?(course_id: course.id, user_id: user.id)
                course.assigned_users << user
              end
            end
          end
        else
          course.assigned_users.each do |user|
            if !CourseAssignedUser.exists?(course_id: course.parent_course.id, user_id: user.id)
              course.parent_course.assigned_users << user
            end
          end
        end
      end

      if form_params["form_copy_enrollment"] == "true"
        if course.indirect_use_flag == Settings.COURSE_INDIRECTUSEFLG_DIRECT
          course.parent_course.enrolled_users.each do |user|
            if !CourseEnrollmentUser.exists?(course_id: course.id, user_id: user.id)
              course.enrolled_users << user
            end
          end
        else
          course.enrolled_users.each do |user|
            if !CourseEnrollmentUser.exists?(course_id: course.parent_course.id, user_id: user.id)
              course.parent_course.enrolled_users << user
            end
          end
        end
      end
    end
  end

  def bulk_update_search
    @courses = get_bulk_courses(true)
  end

  def bulk_update
    @courses = get_bulk_courses(false)

    if @courses && @courses.count > 0
      ActiveRecord::Base.transaction do
        @courses.each do |course|
          course = Course.find(course.id)
          course.term_flag = params[:term_flag]
          course.unread_assignment_display_cd = params[:unread_assignment_display_cd]
          course.unread_faq_display_cd = params[:unread_faq_display_cd]
          course.save!
        end
      end
    else
      raise I18n.t("admin.course.PRI_ADM_COU_BATCHUPDATE_NOTFOUND")
    end

  rescue => e
    logger.error e.backtrace.join("\n")
    flash.now[:notice] = e.message
    bulk_update_search
    render :bulk_update_search
  end

  def bulk_delete_search
    sql_texts = []
    sql_params = {}

    if params[:day] != "0"
      sql_texts.push("day_cd = :day")
      sql_params[:day] = params[:day]
    end

    if params[:hour] != "0"
      sql_texts.push("hour_cd = :hour")
      sql_params[:hour] = params[:hour]
    end

    if params[:school_year] != "0"
      sql_texts.push("school_year = :school_year")
      sql_params[:school_year] = params[:school_year]
    end

    if params[:season] != "0"
      sql_texts.push("season_cd = :season")
      sql_params[:season] = params[:season]
    end
    @courses = Course.where(sql_texts.join(" AND "), sql_params).page(params[:page]) if sql_texts.count > 0
  end

  def outputcsv
    courses = Course.where("deleted_at IS NOT NULL")

    bom = %w(EF BB BF).map { |e| e.hex.chr }.join
    csv_data = CSV.generate(bom) do |csv|
      line = []
      line << I18n.t('common.COMMON_NO1')
      line << I18n.t('common.COMMON_COURSECD')
      line << I18n.t('common.COMMON_COURSENAME')
      line << I18n.t('common.COMMON_SCHOOLYEAR')
      line << I18n.t('common.COMMON_SEASON')
      line << I18n.t('common.COMMON_INSTRUCTORNAME')
      csv << line

      courses.each.with_index(1) do |course, index|
        line = []
        line << index
        line << course.id
        line << course.course_name
        line << course.school_year
        case course.season_cd
        when Settings.COURSE_SEASONCD_SPRING then
          line << I18n.t("common.COMMON_SEASONCD1")
        when Settings.COURSE_SEASONCD_SUMMER then
          line << I18n.t("common.COMMON_SEASONCD2")
        when Settings.COURSE_SEASONCD_AUTUMN then
          line << I18n.t("common.COMMON_SEASONCD3")
        when Settings.COURSE_SEASONCD_WINTER then
          line << I18n.t("common.COMMON_SEASONCD4")
        when Settings.COURSE_SEASONCD_FIRSTTERM then
          line << I18n.t("common.COMMON_SEASONCD5")
        when Settings.COURSE_SEASONCD_LASTTERM then
          line << I18n.t("common.COMMON_SEASONCD6")
        when Settings.COURSE_SEASONCD_CONCENTRATION then
          line << I18n.t("common.COMMON_SEASONCD7")
        when Settings.COURSE_SEASONCD_OVERYEAR then
          line << I18n.t("common.COMMON_SEASONCD8")
        when Settings.COURSE_SEASONCD_OTHER then
          line << I18n.t("common.COMMON_SEASONCD9")
        end
        line << course.instructor_name
        csv << line
      end
    end

    send_data csv_data, filename: "deleteList.csv"
  end

  def outputcsv_enrollment
    bom = %w(EF BB BF).map { |e| e.hex.chr }.join
    csv_data = CSV.generate(bom) do |csv|
      # 設問

      @course.enrolled_users.each do |user|
        line = []
        line << "ks"
        line << user.term_flag
        line << user.account
        line << user.get_name_no_prefix + user.user_name
        csv << line
      end
    end

    send_data csv_data, filename: "enrollmentList.csv"
  end

  def destroy
    ActiveRecord::Base.transaction do
      if params[:course]
        params[:course].each do |key, value|
          destroy_course(value)
        end
      end
    end
  ensure
    redirect_to :action => :index
  end

  def destroy_course(course_id)
    Announcement.where(["course_id = ?", course_id]).delete_all()
    Attendance.where(["course_id = ?", course_id]).delete_all()
    ClassSession.where(["course_id = ?", course_id]).delete_all()
    Course.where(["id = ?", course_id]).delete_all()
    CourseAccessLog.where(["course_id = ?", course_id]).delete_all()
    CourseAssignedUser.where(["course_id = ?", course_id]).delete_all()
    CourseEnrollmentUser.where(["course_id = ?", course_id]).delete_all()
    Faq.where(["course_id = ?", course_id]).delete_all()
    GenericPage.where(["course_id = ?", course_id]).delete_all()
    OpenCourseAssignedUser.where(["course_id = ?", course_id]).delete_all()
  rescue => e
    logger.error e.backtrace.join("\n")
    flash[:notice] = e.message
  end

  def create_delete_list
    file_name = "courseDeleteList.csv"
    if params[:course] == "1"
      courses = Course.joins("LEFT JOIN class_sessions ON courses.id = class_sessions.course_id").where("courses.school_year = #{params[:school_year].to_i} AND class_sessions.id IS NULL")
    else
      courses = Course.where("courses.school_year = #{params[:school_year].to_i}")
    end

    bom = "\uFEFF"
    csv_data = CSV.generate(bom) do |csv|
      line = []
      line << I18n.t('common.COMMON_NO1')
      line << I18n.t('common.COMMON_COURSECD')
      line << I18n.t('common.COMMON_COURSENAME')
      line << I18n.t('common.COMMON_SCHOOLYEAR')
      line << I18n.t('common.COMMON_SEASON')
      line << I18n.t('common.COMMON_INSTRUCTORNAME')
      csv << line

      courses.each.with_index(1) do |course, index|
        line = []
        line << index
        line << course.course_cd
        line << course.course_name
        line << course.school_year
        line << course.season_cd
        line << course.instructor_name
        csv << line
      end
    end

    send_data csv_data, filename: file_name
  end

  def upload_confirm
    begin
      @delete_count = 0
      @delete_dir_count = 0
      @delete_error_count = 0

      @csv = CsvDeleteCourse.new(csv_params)

      if @csv.valid?
        FileUtils.mkdir_p(@csv.tmp_dir)
        File.open(@csv.temp_file, 'w+b') do |fp|
          fp.write @csv.file.read
        end
        session[:csv_delete_course] = @csv.temp_file

        @courses = delete_course_csv_to_hash(@csv.temp_file)
      else
        @messages = I18n.t('registerList.PRI_REG_RESULTLIST_NOSELECTERROR')
      end

    rescue => e
      logger.error e.backtrace.join("\n")
      @messages = I18n.t('registerList.PRI_REG_RESULTLIST_NOSELECTERROR')
      redirect_to :action => :bulk_delete_search
    end
  end

  def upload_error
    upload_file = "#{session[:csv_delete_course]}"
    @courses = delete_course_csv_to_hash(upload_file)
  end

  def upload_destroy
    begin
      @delete_count = 0
      @delete_dir_count = 0
      @delete_error_count = 0

      upload_file = "#{session[:csv_delete_course]}"
      @courses = delete_course_csv_to_hash(upload_file)

      if @errors.count == 0

        delete_courses
      else
        @error_code = 2
        @messages = I18n.t('registerList.PRI_REG_IMPORTRESUL_ERROR_html')
      end
    rescue => e
      logger.error e.backtrace.join("\n")
      @messages = e.message
    end
      render :upload_result
  end

  def parent_course
    key_word = params[:course_name].presence || ""
    @courses = Course.where("course_name like ? AND courseware_flag = 0", "%" + key_word + "%").order("school_year DESC, day_cd, hour_cd, season_cd").page(params[:page])
    if request.xhr?
      respond_to do |format|
        format.html
        format.js { render 'course' }
      end
    end
  end

  def delete_course_csv_to_hash(upload_file)
    lineno = 0
    courses = []
    course_keys = []
    @errors = {}

    csv_data = CSV.parse(File.new(upload_file)) do |csv_row|
      line = {}

      if lineno == 0
        lineno += 1
        next
      end

      line["id"] = csv_row[0]
      line["course_cd"] = csv_row[1]
      line["course_name"] = csv_row[2]
      line["school_year"] = csv_row[3]
      line["season_cd"] = csv_row[4]
      line["instructor_name"] = csv_row[5]
      courses << line
      lineno += 1

      # キー項目のバリデーション
      # 項目数が正しくない場合
      if line.count != CsvDeleteCourse::BUS_UTI_CSV_COLUMNCOUNT
        @errors[lineno] = I18n.t('registerList.PRI_REG_RESULTLIST_COLUMNCOUNTERROR')
        next
      end

      # 科目IDが入力されていない場合
      if line["id"].blank?
        @errors[lineno] = I18n.t("admin.course.CHECK_CSV_ITEM_REQUIRED", :param0 => I18n.t('admin.course.CHECK_CSV_ITEMNAME_COURSEID'))
        next
      end

      # 科目ID
      if line["id"].to_i.to_s != line["id"].to_s
        @errors[lineno] = I18n.t("admin.course.CHECK_CSV_ITEM_TYPE", :param0 => I18n.t('admin.course.CHECK_CSV_ITEMNAME_COURSEID'))
        next
      end

      # 科目CDが入力されていない場合
      if line["course_cd"].blank?
        @errors[lineno] = I18n.t("admin.course.CHECK_CSV_ITEM_REQUIRED", :param0 => I18n.t('admin.course.CHECK_CSV_ITEMNAME_COURSECD'))
        next
      end

      # 科目CD
      if line["course_cd"].to_i.to_s != line["course_cd"].to_s
        @errors[lineno] = I18n.t("admin.course.CHECK_CSV_ITEM_TYPE", :param0 => I18n.t('admin.course.CHECK_CSV_ITEMNAME_COURSECD'))
        next
      end

      # 年度が入力されていない場合
      if line["school_year"].blank?
        @errors[lineno] = I18n.t("admin.course.CHECK_CSV_ITEM_REQUIRED", :param0 => I18n.t('admin.course.CHECK_CSV_ITEMNAME_SCHOOLYEAR'))
        next
      end

      # 年度
      if line["school_year"].to_i.to_s != line["school_year"].to_s
        @errors[lineno] = I18n.t("admin.course.CHECK_CSV_ITEM_TYPE", :param0 => I18n.t('admin.course.CHECK_CSV_ITEMNAME_SCHOOLYEAR'))
        next
      end

      # 科目情報取得
      find_course = Course.find_by(:course_cd => line["course_cd"],
                                   :school_year => line["school_year"],
                                   :season_cd => line["season_cd"])
      # 科目情報なしまたは科目ID不一致の場合はエラー
      unless find_course
        @errors[lineno] = I18n.t('admin.course.CHECK_CSV_NODATA')
        next
      end
    end

    courses
  end

  def delete_courses
    Course.transaction do
      begin
        @courses.each do |course|
#          find_course = Course.where("courses.course_cd = #{line["course_cd"].to_i} AND courses.school_year = #{line["school_year"].to_i}").first

          find_course = Course.find_by(:course_cd => course["course_cd"],
                                       :school_year => course["school_year"],
                                       :season_cd => course["season_cd"])
          find_course.destroy
        end
      rescue => e
        logger.error e.backtrace.join("\n")
        raise ActiveRecord::Rollback
        @messages = e.message
      end
    end
  end

  private
    def set_course_local
      @course = Course.find(params[:id])
    end

    def course_params
      params.require(:course).permit(
        :course_name, :course_cd, :indirect_use_flag, :parent_course_id,
        :overview, :school_year, :season_cd, :day_cd, :hour_cd, :instructor_name,
        :major, :term_flag, :class_session_count, :group_folder_count, :open_course_flag,
        :open_course_pass, :announcement_cd, :open_course_announcement_flag, :faq_cd,
        :open_course_faq_flag, :unread_assignment_display_cd, :unread_faq_display_cd,
        :attendance_ip1, :attendance_ip2, :attendance_ip3, :attendance_ip4, :delete_flag
      )
    end

    def csv_params
      params.require(:upload).permit(:file)
    end

    def get_bulk_courses(is_paginate)
      sql_texts = []
      sql_params = {}

      if params[:day] != "0"
        sql_texts.push("day_cd = :day")
        sql_params[:day] = params[:day]
      end

      if params[:hour] != "0"
        sql_texts.push("hour_cd = :hour")
        sql_params[:hour] = params[:hour]
      end

      if params[:school_year] != "0"
        sql_texts.push("school_year = :school_year")
        sql_params[:school_year] = params[:school_year]
      end

      if params[:season] != "0"
        sql_texts.push("season_cd = :season")
        sql_params[:season] = params[:season]
      end

      params[:term_flag] = Settings.COURSE_TERMFLG_INVALIDITY
      params[:unread_assignment_display_cd] = Settings.UNREAD_DISPLAYFLG_ON
      params[:unread_faq_display_cd] = Settings.UNREAD_DISPLAYFLG_ON

      if is_paginate
        courses = Course.where(sql_texts.join(" AND "), sql_params).page(params[:page])
      else
        courses = Course.where(sql_texts.join(" AND "), sql_params)
      end

      courses
    end
end
