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

class Teacher::CoursesController < ApplicationController
  before_action :require_assigned, only: [:show, :outputcsv, :confirm, :update]
  before_action :set_course, only: [:show, :outputcsv]
  before_action :set_course_local, only: [:confirm, :update]

  def index
    if current_user.admin?
      @courses = Course.order(VIEW_COUSE_ORER).
        where("indirect_use_flag = ? AND (courses.term_flag = ? OR courseware_flag = ?) AND course_name LIKE ?", 0, Settings.COURSE_SELFSTUDY_INVALIDITY, 0, "%#{params[:course_name]}%").page(params[:page])
    else
      @courses = Course.order(VIEW_COUSE_ORER).
        joins(:course_assigned_users).
        where("user_id = ? AND indirect_use_flag = ? AND (courses.term_flag = ? OR courseware_flag = ?) AND course_name LIKE ?", current_user.id, 0, Settings.COURSE_SELFSTUDY_INVALIDITY, 0, "%#{params[:course_name]}%").page(params[:page])
    end
  end

  def show
    if params[:back] && session[:course]
      @course.assign_attributes(session[:course])
      session[:course] = nil
    end
  end

  def confirm
    @course.assign_attributes(course_params)

    session[:course] = course_params
    unless @course.valid?
      session[:course] = nil
      render action: :show
    end
  end

  def update
    if session[:course]
      begin
        Course.transaction do
          @course.update!(session[:course])
          create_class_sessions

          session[:course] = nil
          redirect_to action: :index
        end
      rescue => e
        logger.error e.backtrace.join("\n")
        flash.now[:notice] = e.message
        render action: :show
      end
    else
      render action: :show
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

  def outputcsv
    bom = %w(EF BB BF).map { |e| e.hex.chr }.join
    csv_data = CSV.generate(bom) do |csv|
      # 設問

      @course.enrolled_users.each do |user|
        line = []
        line << "ks"
        line << user.term_flag
        line << user.account
        line << user.user_name
        csv << line
      end
    end

    send_data csv_data, filename: "enrollmentList.csv"
  end

  def destroy
    ActiveRecord::Base.transaction do
      if params[:course]
        params[:course].each do |key, value|
          Announcement.where(["course_id = ?", value]).delete_all
          Attendance.where(["course_id = ?", value]).delete_all
#          attendance_keys.delete_all(["course_id = ?", value])
          ClassSession.where(["course_id = ?", value]).delete_all
#          combined_record_show_flags.delete_all(["course_id = ?", value])
          Course.where(["id = ?", value]).delete_all
          CourseAccessLog.where(["course_id = ?", value]).delete_all
          CourseAssignedUser.where(["course_id = ?", value]).delete_all
          CourseEnrollmentUser.where(["course_id = ?", value]).delete_all
#          courseware_course_associations.delete_all(["course_id = ?", value])
#          courseware_user_associations.delete_all(["course_id = ?", value])
          Faq.where(["course_id = ?", value]).delete_all
          GenericPage.where(["course_id = ?", value]).delete_all
          OpenCourseAssignedUser.where(["course_id = ?", value]).delete_all
#          self_study_course_associations.delete_all(["course_id = ?", value])
#          sorts.delete_all(["course_id = ?", value])
#          students.delete_all(["course_id = ?", value])
#          sub_attendances.delete_all(["course_id = ?", value])
#          teachers.delete_all(["course_id = ?", value])
#          threads.delete_all(["course_id = ?", value])
#          weekly_classes.delete_all(["course_id = ?", value])
        end
      end
    end

  rescue => e
    logger.error e.backtrace.join("\n")
    flash[:notice] = e.message
  ensure
    redirect_to :action => :index
  end

  private
    def set_course_local
      @course = Course.find(params[:id])
    end

    def course_params
      params.require(:course).permit(
        :course_name, :overview, :day_cd, :hour_cd, :instructor_name,
        :major, :term_flag, :class_session_count, :group_folder_count, :open_course_flag,
        :open_course_pass, :announcement_cd, :open_course_announcement_flag, :faq_cd,
        :open_course_faq_flag, :unread_assignment_display_cd, :unread_faq_display_cd
      )
    end
end
