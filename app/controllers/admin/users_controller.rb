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

class Admin::UsersController < ApplicationController
  before_action :set_user, only: [:edit, :update, :destroy]

  def index
    set_users
  end

  def new
    if params[:back] && session[:user]
      @user = User.new(session[:user])
      session[:user] = nil
    else
      @user = User.new
      @user.role_id = Settings.USR_AUTHCD_STUDENT
      @user.term_flag = Settings.USR_TERMFLG_EFFECTIVE
    end
    get_unassigned_courses(@user.role_id)
  end

  def edit
    if params[:back] && session[:user]
      @user.assign_attributes(session[:user])
      session[:user] = nil
    end
    get_unassigned_courses(@user.role_id)
  end

  def confirm
    @delete_courses = Course.where("id IN (?)", params[:user][:delete_courses]) if params[:user][:delete_courses]
    @add_courses = Course.where("id IN (?)", params[:user][:add_courses]) if params[:user][:add_courses]
    if params[:id]
      set_user
      @user.assign_attributes(user_params)
      if @user.valid?
        session[:user] = user_params
      else
        get_unassigned_courses(@user.role_id)
        render action: :edit
      end
    else
      @user = User.new(user_params)
      if @user.valid?
        session[:user] = user_params
      else
        get_unassigned_courses(@user.role_id)
        render action: :new
      end
    end
  end

  def create
    @user = User.new(session[:user])
    if @user.save
      session[:user] = nil
      redirect_to action: :index
    else
      render action: :new
    end
  end

  def update
    if @user.update(session[:user])
      session[:user] = nil
      redirect_to action: :index
    else
      render action: :edit
    end
  end

  def delete
    ActiveRecord::Base.transaction do
      if params[:check_delete]
        params[:check_delete].each do |key, value|
          User.where(["id = ?", key.to_i]).delete_all()
        end
      end
    end

  rescue => e
    logger.error e.backtrace.join("\n")
    flash[:notice] = e.message

  ensure
    set_users
    render :index
  end

  def outputcsv
    users = User.where("deleted_at IS NOT NULL AND deleted_res_at IS NOT NULL")

    bom = %w(EF BB BF).map { |e| e.hex.chr }.join
    csv_data = CSV.generate(bom) do |csv|
      line = []
      line << I18n.t('common.COMMON_NO1')
      line << I18n.t('common.COMMON_ID')
      line << I18n.t('common.COMMON_USRNAME')
      line << I18n.t('common.COMMON_ACCOUNT')
      line << I18n.t('common.COMMON_PASSWORD')
      line << I18n.t('common.COMMON_AUTHCD2')
      line << I18n.t('common.COMMON_MAIL2')
      line << I18n.t('common.COMMON_MOVECD')
      line << I18n.t('common.COMMON_MOVEDATE')
      csv << line

      users.each.with_index(1) do |user, index|
        line = []
        line << index
        line << user.id
        line << user.user_name
        line << user.account
        line << user.encrypted_password
        line << user.role_id
        line << user.email
        line << user.move_cd
        line << user.move_date
        csv << line
      end
    end

    send_data csv_data, filename: "#{I18n.t('admin.user.COMMON_ADMINISTRATEUSR_CSVNAME')}.csv"
  end

  def course
    set_user if params[:id]
    if params[:type] == "unassign"
      get_unassigned_courses(@user ? @user.role_id : nil)
    else
      get_assigned_courses(@user)
    end
    render :layout => false
  end

  private
    def set_user
      @user = User.find(params[:id])
    end

    def set_users
      sql_texts = []
      sql_params = {}

      sql_texts.push("role_id IN (:roles)")
      sql_params[:roles] = Role.all.map { |role| role.id }

      if !params[:keyword].blank?
        if params[:type] == "0"
          sql_texts.push("user_name like :keyword")
          sql_params[:keyword] = "%" + params[:keyword] + "%"
        else
          sql_texts.push("account like :keyword")
          sql_params[:keyword] = "%" + params[:keyword] + "%"
        end
      end

      if !params[:role].blank?
        sql_texts.push("role_id = :role")
        sql_params[:role] = params[:role]
      end

      @users = User.where(sql_texts.join(" AND "), sql_params).page(params[:page])
    end

    def user_params
      params.require(:user).permit(
        :user_name, :kana_name, :email, :email_mobile, :sex_cd, :birth_date, :account,
        :password, :name_no_prefix, :role_id, :term_flag, :delete_flag, :move_cd,
        :add_courses => [], :delete_courses => [])
    end

    def get_unassigned_courses(role_id)
      sql_params = {}
      sql_texts = []

      if role_id == Settings.USR_AUTHCD_INSTRUCTOR
        sql_texts.push('courses.id NOT IN (' + CourseAssignedUser.where(user_id: @user.id).select(:course_id).to_sql + ')') if @user
      elsif role_id == Settings.USR_AUTHCD_STUDENT
        sql_texts.push('courses.id NOT IN (' + CourseEnrollmentUser.where(user_id: @user.id).select(:course_id).to_sql + ')') if @user

        sql_texts.push('courses.open_course_flag = :open_course_flag')
        sql_params[:open_course_flag] = Settings.COURSE_OPENCOURSEFLG_PRIVATE
      end

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

      @courses = Course.where(sql_texts.join(" AND "), sql_params).
        order(VIEW_COUSE_ORER)
    end

    def get_assigned_courses(user)
      sql_params = {}
      sql_texts = []

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

      if user.teacher?
        @courses = user.assigned_courses.where(sql_texts.join(" AND "), sql_params).
          order(VIEW_COUSE_ORER).page(params[:page])
      elsif @user.student?
        @courses = user.enrollment_courses.where(sql_texts.join(" AND "), sql_params).
          order(VIEW_COUSE_ORER).page(params[:page])
      end
    end
end
