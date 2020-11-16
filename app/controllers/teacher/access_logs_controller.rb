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

class Teacher::AccessLogsController < ApplicationController
  before_action :set_courses, only: [:index]

  def index
    redirect_to admin_access_logs_path if current_user.admin?

    flash[:notice] = nil
    raise I18n.t("access_log.ACC_ACCESSLOG_ERROR1") if params[:type].blank?
    raise I18n.t("access_log.ACC_ACCESSLOG_ERROR2") if !params[:start_date].blank? && !date_valid?(params[:start_date])
    raise I18n.t("access_log.ACC_ACCESSLOG_ERROR2") if !params[:end_date].blank? && !date_valid?(params[:end_date])

    if params[:type]
      sql_texts = []
      sql_params = {}

      course = Course.where("id = ?", params[:type]).first
      if course.open_course_flag ==  Settings.COURSE_OPENCOURSEFLG_PUBLIC
        assigned = course.open_course_assigned_users.where(user_id: current_user.id).first
      else
        assigned = course.course_assigned_users.where(user_id: current_user.id).first
      end
      raise Forbidden if assigned.blank?

      sql_texts.push("course_access_logs.course_id = :course_id")
      sql_params[:course_id] = params[:type]

      if !params[:start_date].blank?
        sql_texts.push("course_access_logs.created_at >= :start_date")
        sql_params[:start_date] = params[:start_date] + " 00:00:00"
      end
      if !params[:end_date].blank?
        sql_texts.push("course_access_logs.created_at <= :end_date")
        sql_params[:end_date] = params[:end_date] + " 23:59:59"
      end
      if !params[:access_ip].blank?
        sql_texts.push("course_access_logs.ip like :access_ip")
        sql_params[:access_ip] = params[:access_ip] + "%"
      end
    end

    if params[:output] == "csv"
      @logs = CourseAccessLog.joins(:user).preload(:user).where(sql_texts.join(" AND "), sql_params).order("course_access_logs.created_at DESC")

      if @logs && @logs.count > 0
        bom = %w(EF BB BF).map { |e| e.hex.chr }.join
        csv_data = CSV.generate(bom) do |csv|
          @logs.each.with_index(1) do |log, index|
            line = []
            line << index
            line << log.user.get_name_no_prefix.to_s + log.user.user_name
            line << I18n.l(log.created_at)
            line << log.ip
            csv << line
          end
        end
      end

      filename = "semlog.csv"
      send_data csv_data, filename: filename

    else
      @logs = CourseAccessLog.joins(:user).preload(:user).where(sql_texts.join(" AND "), sql_params).order("course_access_logs.created_at DESC").page(params[:page])

    end

  rescue Forbidden => e
    raise e

  rescue => e
    logger.error e.backtrace.join("\n")
    @logs = nil
    flash[:notice] = e.message

  end

  def date_valid?(date)
    is_valid = false

    unless date.blank?
      date_ary = date.split("/")
      if date_ary.count == 3
        is_valid = true if Date.valid_date?(date_ary[0].to_i, date_ary[1].to_i, date_ary[2].to_i)
      end
    end

    is_valid
  end
end
