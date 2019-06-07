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

class Course < ApplicationRecord
  has_many  :courses, :foreign_key => :parent_course_id, :class_name => 'Course'
  has_many  :announcements, -> { order('id ASC') }
  has_many  :faqs, -> { order('id ASC') }
  has_many  :course_assigned_users, :foreign_key => :course_id
  has_many  :assigned_users, :through => :course_assigned_users, :source => :user
  has_many  :open_course_assigned_users, :foreign_key => :course_id
  has_many  :course_enrollment_users, :foreign_key => :course_id
  has_many  :enrolled_users, -> { order('users.name_no_prefix ASC') }, :through => :course_enrollment_users, :source => :user

  has_many  :materials, -> { where "type_cd = #{Settings.GENERICPAGE_TYPECD_MATERIALCODE}"}, :class_name => "GenericPage"
  has_many  :urls, -> { where "type_cd = #{Settings.GENERICPAGE_TYPECD_URLCODE}"}, :class_name => "GenericPage"
  has_many  :compounds, -> { where "type_cd = #{Settings.GENERICPAGE_TYPECD_COMPOUNDCODE}"}, :class_name => "Compound"
  has_many  :multiplefibs, -> { where "type_cd = #{Settings.GENERICPAGE_TYPECD_MULTIPLEFIBCODE}"}, :class_name => "GenericPage"
  has_many  :essays, -> { where "type_cd = #{Settings.GENERICPAGE_TYPECD_ASSIGNMENTESSAYCODE}"}, :class_name => "Essay"
  has_many  :questionnaires, -> { where "type_cd = #{Settings.GENERICPAGE_TYPECD_QUESTIONNAIRECODE}"}, :class_name => "GenericPage"
  has_many  :evaluations, -> { where "type_cd = #{Settings.GENERICPAGE_TYPECD_EVALUATIONLISTCODE}"}, :class_name => "GenericPage"
  has_many  :exams, -> { where "type_cd = #{Settings.GENERICPAGE_TYPECD_COMPOUNDCODE} OR type_cd = #{Settings.GENERICPAGE_TYPECD_MULTIPLEFIBCODE}"}, :class_name => "Compound"

  has_many  :class_sessions
  has_many  :attendances

  has_many  :group_folders, -> { order('id ASC') }

  has_many  :unread_assignment_essay_count_views, :class_name => "UnreadAssignmentEssayCountView"
  has_one   :non_answer_faq_count_view

  #  has_many :course_childrens, :class_name => "Course", :foreign_key => "course_id"
  belongs_to  :parent_course, :class_name => 'Course', :foreign_key => :parent_course_id, optional: true

  attr_accessor :attendance_ip1, :attendance_ip2, :attendance_ip3, :attendance_ip4, :delete_flag, :delete_flag_was, :sv_course_cd, :sv_school_year, :sv_season_cd

  class << self
    def get_year_list
      Course.select(:school_year).order("school_year").distinct
    end

    def get_assigned(user_id, page)
      sql_params = {}
      sql_text = "user_id = :user_id AND indirect_use_flag = :indirect_use_flag AND (courses.term_flag = :term_flag OR courseware_flag = :courseware_flag)"
      sql_params[:user_id] = user_id
      sql_params[:indirect_use_flag] = false
      sql_params[:term_flag] = true
      sql_params[:courseware_flag] = true
      Course.joins(:course_assigned_users).where(sql_text, sql_params).order("school_year DESC, day_cd, hour_cd, season_cd").page(page)
    end

    def get_count_not_confirmed(user_id)
      sql_text = "user_id = :user_id AND indirect_use_flag = :indirect_use_flag AND (courses.term_flag = :term_flag OR courseware_flag = :courseware_flag)"
        + " AND "
      sql_params[:user_id] = user_id
      sql_params[:indirect_use_flag] = false
      sql_params[:term_flag] = true
      sql_params[:courseware_flag] = true
      Course.joins(:course_assigned_users, :unread_assignment_essay_count_views).order("school_year DESC, day_cd, hour_cd, season_cd").where(sql_text, sql_params).limit(3)
    end

    def get_enrollment(user_id, page)
      sql_params = {}
      sql_text = "user_id = :user_id AND indirect_use_flag = :indirect_use_flag AND courses.term_flag = :term_flag AND courseware_flag = :courseware_flag"
      sql_params[:user_id] = user_id
      sql_params[:indirect_use_flag] = false
      sql_params[:term_flag] = true
      sql_params[:courseware_flag] = false
      Course.joins(:course_enrollment_users).where(sql_text, sql_params).order("school_year DESC, day_cd, hour_cd, season_cd").page(page)
    end
  end

  after_initialize do
    if self.respond_to?('deleted_at')
      if self.deleted_at.blank?
        self.delete_flag = "0"
      else
        self.delete_flag = "1"
      end
      self.delete_flag_was = self.delete_flag
    end
  end

  after_find do
    if self.has_attribute?('attendance_ip_list')
      if self.attendance_ip_list
        list = attendance_ip_list.split(",")

        self.attendance_ip4 = list[3] if list.count >= 4
        self.attendance_ip3 = list[2] if list.count >= 3
        self.attendance_ip2 = list[1] if list.count >= 2
        self.attendance_ip1 = list[0] if list.count >= 1
      end
    end

    if self.has_attribute?('course_cd')
      self.sv_course_cd = self.course_cd
      self.sv_school_year = self.school_year
      self.sv_season_cd = self.season_cd
    end
  end

  before_save do
    if User.current_user
      if self.new_record?
        self.insert_user_id = User.current_user.id
      end
      self.update_user_id = User.current_user.id
    end

    self.attendance_ip_list = [attendance_ip1, attendance_ip2, attendance_ip3, attendance_ip4].map{|ip| ip if ip}.join(",")

    if self.delete_flag_was != self.delete_flag
      if self.delete_flag == "1"
        self.deleted_at = Time.zone.now
      else
        self.deleted_at = nil
      end
    end
  end

  after_save do
    if self.group_folders.count != self.group_folder_count
      if self.group_folders.count < self.group_folder_count
        start_no = self.group_folders.count + 1
        start_no.upto(self.group_folder_count) do |count|
          self.group_folders << GroupFolder.new(
            :title => I18n.t("group_folder.PRE_BEA_GRO_GROUPFOLDERBEAN_DEFAULTTITLE") + count.to_s,
            :memo => I18n.t("group_folder.PRE_BEA_GRO_GROUPFOLDERBEAN_DEFAULTOVERVIEW"),
            :view_rank => count)
        end
      end
    end
  end

  validate :check_data

  def check_data
    errors.add(:course_name, I18n.t("admin.course.PRI_ADM_COU_REGISTERCOURSE_ERROR1")) if self.course_name.blank?
    errors.add(:overview, I18n.t("admin.course.PRI_ADM_COU_REGISTERCOURSE_ERROR5")) if self.overview.size > 4096
  end

  def parent_course_name
    self.parent_course.course_name + "(#{self.parent_course.course_cd},#{self.parent_course.school_year},#{season_name(self.parent_course.season_cd)})" if self.parent_course
  end

  def season_name(season_cd=self.season_cd)
    case season_cd.to_s
      when Settings.COURSE_SEASONCD_SPRING.to_s then
        return I18n.t("common.COMMON_SEASONCD1")
      when Settings.COURSE_SEASONCD_SUMMER.to_s then
        return I18n.t("common.COMMON_SEASONCD2")
      when Settings.COURSE_SEASONCD_AUTUMN.to_s then
        return I18n.t("common.COMMON_SEASONCD3")
      when Settings.COURSE_SEASONCD_WINTER.to_s then
        return I18n.t("common.COMMON_SEASONCD4")
      when Settings.COURSE_SEASONCD_FIRSTTERM.to_s then
        return I18n.t("common.COMMON_SEASONCD5")
      when Settings.COURSE_SEASONCD_LASTTERM.to_s then
        return I18n.t("common.COMMON_SEASONCD6")
      when Settings.COURSE_SEASONCD_CONCENTRATION.to_s then
        return I18n.t("common.COMMON_SEASONCD7")
      when Settings.COURSE_SEASONCD_OVERYEAR.to_s then
        return I18n.t("common.COMMON_SEASONCD8")
      when Settings.COURSE_SEASONCD_OTHER.to_s then
        return I18n.t("common.COMMON_SEASONCD9")
    end

    return ""
  end

  def assignd_list(user_name = nil)
    sql_texts = ["course_assigned_users.course_id = :course_id"]
    sql_params = {:course_id => self.id}

    if !user_name.blank?
      sql_texts.push("users.user_name like :user_name")
      sql_params[:user_name] = "%" + user_name + "%"
    end

    User.joins(:course_assigned_users => :course).where(sql_texts.join(" AND "), sql_params).order("user_name")
  end

  def class_session(class_session_no)
    ##self.class_sessions.where(class_session_no: class_session_no).first
    @sessions = self.class_sessions if @sessions.nil?
    @sessions.each do |session|
      if session.class_session_no.to_s == class_session_no.to_s
        return session
      end
    end
    nil
  end

  def latest_attendance_date_cd(user)
    get_attendance_information(user) unless @attendance_informations
    @attendance_informations[0].attendance_date_cd if @attendance_informations.count > 0
  end

  def attendance_count_by_attendance(user)
    get_attendance_informations(user) unless @attendance_informations
    @attendance
  end

  def attendance_count_by_late(user)
    get_attendance_informations(user) unless @attendance_informations
    @late
  end

  def attendance_count_by_absent(user)
    get_attendance_informations(user) unless @attendance_informations
    @absent
  end

  def attendance_count_all(user)
    get_attendance_informations(user) unless @attendance_informations
    @attendance + @late + @absent
  end

  def get_attendance_informations(user)
    @attendance_informations = AttendanceInformation.joins(:attendance).
      where("attendances.course_id = ? AND attendance_information.user_id = ?", self.id, user.id).
      order("attendances.class_session_no DESC, attendances.attendance_count DESC")

    keys = []
    @attendance = 0
    @late = 0
    @absent = 0

    @attendance_informations.each do |information|
      unless keys.include?(information.attendance_id)
        case information.attendance_data_cd
        when Settings.ATTENDANCEINFO_ATTENDANCEDATACD_ATTENDANCE
          @attendance += 1
        when Settings.ATTENDANCEINFO_ATTENDANCEDATACD_LATE
          @late += 1
        when Settings.ATTENDANCEINFO_ATTENDANCEDATACD_ABSENT
          @absent += 1
        end

        keys << information.attendance_id
      end
    end
  end

  def faq_answer_count
    self.faqs.where("response_flag != ?", 0).count
  end

  def faq_not_answered_count
    self.faqs.where("response_flag = ?", 0).count
  end

  def assigned?(user)
    if user.student?
      self.course_enrollment_users.where("user_id = ?", user.id).count == 0 ? false : true
    elsif user.teacher?
      self.course_assigned_users.where("user_id = ?", user.id).count == 0 ? false : true
    end
  end
end
