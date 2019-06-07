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

class User < ApplicationRecord
  extend Devise::Models
  include CustomValidationModule

  belongs_to :role
  has_many :user_image
  has_many :course_enrollment_users, :foreign_key => :user_id, :class_name => "CourseEnrollmentUser"
  has_many :enrollment_courses, :through => :course_enrollment_users, :source => 'course'
  has_many :course_assigned_users, :foreign_key => :user_id, :class_name => "CourseAssignedUser"
  has_many :assigned_courses, :through => :course_assigned_users, :source => 'course'
  has_many :answer_scores
  has_many :answer_score_histories
  has_many :open_course_assigned_users, :foreign_key => :user_id

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable, :omniauthable,
         :authentication_keys => [:account]


  UPDATED_TYPE_PASSWORD = 0
  UPDATED_TYPE_EMAIL = 1
  UPDATED_TYPE_EMAIL_MOBILE = 2

  MOVE_LIST = {
    Settings.USR_MOVECD_INDEFINITE => I18n.t("admin.user.COMMON_ADMINISTRATEUSR_DEFAULTMOVECD"),
    Settings.USR_MOVECD_ABSENCEMOVECD => I18n.t("admin.user.COMMON_ADMINISTRATEUSR_MOVECD1"),
    Settings.USR_MOVECD_LEAVEMOVECD => I18n.t("admin.user.COMMON_ADMINISTRATEUSR_MOVECD2"),
    Settings.USR_MOVECD_EXPELMOVECD => I18n.t("admin.user.COMMON_ADMINISTRATEUSR_MOVECD3"),
    Settings.USR_MOVECD_MOVEOUTMOVECD => I18n.t("admin.user.COMMON_ADMINISTRATEUSR_MOVECD4"),
    Settings.USR_MOVECD_GRADUATIONMOVECD => I18n.t("admin.user.COMMON_ADMINISTRATEUSR_MOVECD5")
  }

  attr_accessor :delete_flag, :delete_flag_was, :add_courses, :delete_courses, :new_email, :email_confirmation, :new_email_mobile, :email_mobile_confirmation

  # validates
  validate :check_data

  def check_data
    validate_presence(:user_name, I18n.t("admin.user.PRI_ADM_USR_REGISTERUST_ERROR1"))
    validate_presence(:account, I18n.t("admin.user.PRI_ADM_USR_REGISTERUST_ERROR2"))
    validate_account_name(:account, I18n.t("admin.user.PRI_ADM_USR_REGISTERUST_ERROR4"))
    validate_uniqueness(:account, I18n.t("admin.user.PRI_ADM_USR_REGISTERUST_ERROR9"))
    validate_presence(:password, I18n.t("admin.user.PRI_ADM_USR_REGISTERUST_ERROR3")) if self.new_record?
    validate_length(:password, I18n.t("admin.user.PRI_ADM_USR_REGISTERUST_ERROR6"), 6, 128)
    validate_password(:password, I18n.t("admin.user.PRI_ADM_USR_REGISTERUST_ERROR5")) unless self.password.blank?
    validate_mail_address(:email, I18n.t("admin.user.PRI_ADM_USR_REGISTERUST_ERROR7")) unless self.email.blank?
    validate_date(:birth_date, I18n.t("admin.user.PRI_ADM_USR_REGISTERUST_ERROR8")) unless self.birth_date.blank?
    validate_presence(:sex_cd, I18n.t("admin.user.PRI_ADM_USR_REGISTERUST_ERROR10")) if self.sex_cd.blank?
  end

  after_initialize do
    if self.deleted_at.blank?
      self.delete_flag = "0"
    else
      self.delete_flag = "1"
    end
    self.delete_flag_was = self.delete_flag
  end

  before_save do
    if User.current_user
      if self.new_record?
        self.insert_user_id = User.current_user.id
      end
      self.update_user_id = User.current_user.id
    end

    if self.delete_flag_was != self.delete_flag
      if self.delete_flag == "1"
        self.deleted_at = Time.zone.now
      else
        self.deleted_at = nil
      end
    end
  end

  after_save do
    if self.add_courses
      courses = Course.where("id IN (?)", self.add_courses)
      if self.teacher?
        self.assigned_courses << courses
      elsif self.student?
        self.enrollment_courses << courses
      end
    end
    if self.delete_courses
      if self.teacher?
        self.course_assigned_users.where("course_id IN (?)", self.delete_courses).destroy_all
      else
        self.course_enrollment_users.where("course_id IN (?)", self.delete_courses).destroy_all
      end
    end
  end

  def update_with_password(params, *options)
    current_password = params.delete(:current_password)

    if current_password.blank?
      self.errors[:base] << I18n.t("change_personal_data.PRI_ADM_USR_CHANGEPERSONALDATA_ERRORTYPE1")
    elsif !valid_password?(current_password)
      self.errors[:base] << I18n.t("change_personal_data.PRI_ADM_USR_CHANGEPERSONALDATA_ERRORTYPE9")
    elsif params[:password].blank?
      self.errors[:base] << I18n.t("change_personal_data.PRI_ADM_USR_CHANGEPERSONALDATA_ERRORTYPE2")
    elsif !params[:password].match(/^[ -~。-゜]*$/)
      self.errors[:base] << I18n.t("change_personal_data.PRI_ADM_USR_CHANGEPERSONALDATA_ATTENTION2")
    elsif params[:password].length < 6 || params[:password].length > 256
      self.errors[:base] << I18n.t("change_personal_data.PRI_ADM_USR_CHANGEPERSONALDATA_ERRORTYPE10")
    elsif params[:password_confirmation].blank?
      self.errors[:base] << I18n.t("change_personal_data.PRI_ADM_USR_CHANGEPERSONALDATA_ERRORTYPE3")
    elsif params[:password] != params[:password_confirmation]
      self.errors[:base] << I18n.t("change_personal_data.PRI_ADM_USR_CHANGEPERSONALDATA_ERRORTYPE11")
    end

    if self.errors.messages.count > 0
      result = false
    else
      update_attributes(params, *options)
      result = true
    end

    clean_up_passwords
    result
  end

  def update_with_email(params)
    if params[:new_email].blank?
      self.errors[:base] << I18n.t("change_personal_data.PRI_ADM_USR_CHANGEPERSONALDATA_ERRORTYPE4")
    elsif !params[:new_email].match(/^[ -~。-゜]*$/)
      self.errors[:base] << I18n.t("change_personal_data.PRI_ADM_USR_CHANGEPERSONALDATA_ATTENTION2")
    elsif params[:new_email] !~ VALID_ADDRESS
      self.errors[:base] << I18n.t("change_personal_data.PRI_ADM_USR_CHANGEPERSONALDATA_ERRORTYPE12")
    elsif params[:new_email] != params[:email_confirmation]
      self.errors[:base] << I18n.t("change_personal_data.PRI_ADM_USR_CHANGEPERSONALDATA_ERRORTYPE14")
    end

    if self.errors.messages.count > 0
      assign_attributes(params)
      result = false
    else
      params.delete(:email_confirmation)
      params[:email] = params.delete(:new_email)
      update_attributes(params)
      result = true
    end

    result
  end

  def update_with_email_mobile(params)
    if params[:new_email_mobile].blank?
      self.errors[:base] << I18n.t("change_personal_data.PRI_ADM_USR_CHANGEPERSONALDATA_ERRORTYPE6")
    elsif !params[:new_email_mobile].match(/^[ -~。-゜]*$/)
      self.errors[:base] << I18n.t("change_personal_data.PRI_ADM_USR_CHANGEPERSONALDATA_ATTENTION2")
    elsif params[:new_email_mobile] !~ VALID_ADDRESS
      self.errors[:base] << I18n.t("change_personal_data.PRI_ADM_USR_CHANGEPERSONALDATA_ERRORTYPE13")
    elsif params[:new_email_mobile] != params[:email_mobile_confirmation]
      self.errors[:base] << I18n.t("change_personal_data.PRI_ADM_USR_CHANGEPERSONALDATA_ERRORTYPE15")
    end

    if self.errors.messages.count > 0
      assign_attributes(params)
      result = false
    else
      params.delete(:email_mobile_confirmation)
      params[:email_mobile] = params.delete(:new_email_mobile)
      update_attributes(params)
      result = true
    end

    result
  end

  def update_unset_email(params)
    if params[:new_email].blank?
      self.errors[:base] << I18n.t("login.LOG_REGISTERMAIL_JAVASCRIPT1")
    elsif !params[:new_email].match(/^[ -~。-゜]*$/)
      self.errors[:base] << I18n.t("change_personal_data.PRI_ADM_USR_CHANGEPERSONALDATA_ATTENTION2")
    elsif params[:new_email] !~ VALID_ADDRESS
      self.errors[:base] << I18n.t("login.LOG_REGISTERMAIL_JAVASCRIPT3")
    elsif params[:new_email] != params[:email_confirmation]
      self.errors[:base] << I18n.t("login.LOG_REGISTERMAIL_JAVASCRIPT5")
    end

    if self.errors.messages.count > 0
      assign_attributes(params)
      result = false
    else
      params.delete(:email_confirmation)
      params[:email] = params.delete(:new_email)
      update_attributes(params)
      result = true
    end

    result
  end

  class << self
    def current_user=(user)
      Thread.current[:current_user] = user
    end

    def current_user
      Thread.current[:current_user]
    end

    def find_first_by_auth_conditions(warden_conditions)
      conditions = warden_conditions.dup
      if login = conditions.delete(:login)
        user = where(conditions).where(["account = :value", {:value => account}]).first
      else
        user = where(conditions).first
      end
      user.update(provider: "") if user

      user
    end

    def find_for_omniauth(auth)
      if auth.provider == :cas
        user = User.where(account: auth.uid).first
        user.update(provider: auth.provider) if user
      else
        user = User.where(uid: auth.uid, provider: auth.provider).first
      end

      user
    end
  end

  def password_required?
    false
  end

  def email_required?
    false
  end

  def email_changed?
    false
  end

  def admin?
    if role_id == Settings.USR_AUTHCD_ADMINISTRATOR
      return true
    end

    return false
  end

  def teacher?
    if role_id == Settings.USR_AUTHCD_INSTRUCTOR
      return true
    end

    return false
  end

  def student?
    if role_id == Settings.USR_AUTHCD_STUDENT
      return true
    end

    return false
  end

  def get_user_image(image_type)
    user_image = self.user_image.where(:image_type => image_type).first
    if user_image && user_image.persisted?
      user_image.mount_url.url
    else
      ActionController::Base.helpers.asset_path "no_image.png"
    end
  end

  def has_user_image(image_type)
    user_image = self.user_image.where(:image_type => image_type).uniq

    if user_image.count == 0
      return false
    else
      return true
    end
  end

  def get_email(user_id)
    user = User.find(user_id)
    user.email
  end

  def get_email_mobile(user_id)
    user = User.find(user_id)
    user.email_mobile
  end

  def get_name_no_prefix
    return "" unless self.name_no_prefix

		if (0 < Settings.CUSTOM_NAMENOPREFIXSTARTNO && 0 < Settings.CUSTOM_NAMENOPREFIXENDNO)
			ret = self.name_no_prefix

		elsif (Settings.CUSTOM_NAMENOPREFIXSTARTNO < 0 && Settings.CUSTOM_NAMENOPREFIXENDNO >= 0 && Settings.CUSTOM_NAMENOPREFIXENDNO <= self.name_no_prefix.size)
			ret = self.name_no_prefix[Settings.CUSTOM_NAMENOPREFIXENDNO, self.name_no_prefix.size]

		elsif (Settings.CUSTOM_NAMENOPREFIXSTARTNO < 0 && Settings.CUSTOM_NAMENOPREFIXENDNO > self.name_no_prefix.size)
			ret = self.name_no_prefix;

		elsif (Settings.CUSTOM_NAMENOPREFIXSTARTNO >= 0 && Settings.CUSTOM_NAMENOPREFIXENDNO <= self.name_no_prefix.size && Settings.CUSTOM_NAMENOPREFIXSTARTNO <= Settings.CUSTOM_NAMENOPREFIXENDNO)
			ret = self.name_no_prefix[0, Settings.CUSTOM_NAMENOPREFIXSTARTNO] + self.name_no_prefix[Settings.CUSTOM_NAMENOPREFIXENDNO, self.name_no_prefix.size]

		elsif (Settings.CUSTOM_NAMENOPREFIXSTARTNO >= 0 && Settings.CUSTOM_NAMENOPREFIXSTARTNO <= self.name_no_prefix.size && Settings.CUSTOM_NAMENOPREFIXENDNO > self.name_no_prefix.size)
			ret = self.name_no_prefix[0, Settings.CUSTOM_NAMENOPREFIXSTARTNO]

		else
			ret = self.name_no_prefix
		end

		return ret;
  end

  def assigned?(course_id)
    self.course_assigned_users.where(:course_id => course_id).count == 0 ? false : true
  end
end
