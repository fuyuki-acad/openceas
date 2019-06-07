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

class Admin::AccessLogsController < ApplicationController
  before_action :set_courses, only: [:index]

  def index
    flash[:notice] = nil
    sql_texts = []
    sql_params = {}

    if params.has_key?('type')
      raise I18n.t("access_log.ACC_ACCESSLOG_ERROR1") if params[:type].blank?
      raise I18n.t("access_log.ACC_ACCESSLOG_ERROR2") if !params[:start_date].blank? && !date_valid?(params[:start_date])
      raise I18n.t("access_log.ACC_ACCESSLOG_ERROR2") if !params[:end_date].blank? && !date_valid?(params[:end_date])

      if params[:type] == "0"
        if !params[:start_date].blank?
          sql_texts.push("system_logs.created_at >= :start_date")
          sql_params[:start_date] = params[:start_date] + " 00:00:00"
        end
        if !params[:end_date].blank?
          sql_texts.push("system_logs.created_at <= :end_date")
          sql_params[:end_date] = params[:end_date] + " 23:59:59"
        end
        if !params[:access_ip].blank?
          sql_texts.push("system_logs.ip like :access_ip")
          sql_params[:access_ip] = params[:access_ip] + "%"
        end

      else
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

        if !params[:keyword].blank?
          case params[:search_type]
          when "1"
            sql_texts.push("courses.instructor_name like :keyword")
            sql_params[:keyword] = "%" + params[:keyword] + "%"
          when "2"
            sql_texts.push("courses.course_cd like :keyword")
            sql_params[:keyword] = "%" + params[:keyword] + "%"
          else
            sql_texts.push("courses.course_name like :keyword")
            sql_params[:keyword] = "%" + params[:keyword] + "%"
          end
        end

        if params[:day] && params[:day] != "0"
          sql_texts.push("courses.day_cd = :day")
          sql_params[:day] = params[:day]
        end

        if params[:hour] && params[:hour] != "0"
          sql_texts.push("courses.hour_cd = :hour")
          sql_params[:hour] = params[:hour]
        end

        if params[:school_year] && params[:school_year] != "0"
          sql_texts.push("courses.school_year = :school_year")
          sql_params[:school_year] = params[:school_year]
        end

        if params[:season] && params[:season] != "0"
          sql_texts.push("courses.season_cd = :season")
          sql_params[:season] = params[:season]
        end
      end

      if !params[:role].blank?
        sql_texts.push("users.role_id = :role")
        sql_params[:role] = params[:role]
      end

      if params[:output] == "csv"
        if params[:type] == "0"
          @logs = SystemLog.joins(:user).preload(:user).where(sql_texts.join(" AND "), sql_params).order("system_logs.created_at DESC")
          filename = "syslog.csv"
        else
          @logs = CourseAccessLog.joins(:user, :course).preload(:user, :course).where(sql_texts.join(" AND "), sql_params).order("course_access_logs.created_at DESC")
          filename = "semlog.csv"
        end

        if @logs && @logs.count > 0
          bom = %w(EF BB BF).map { |e| e.hex.chr }.join
          csv_data = CSV.generate(bom) do |csv|
            @logs.each.with_index(1) do |log, index|
              line = []
              if params[:type] == "0"
                line << index
                line << log.user.get_name_no_prefix.to_s + log.user.user_name
                line << Role.role_name(log.user.role_id)
                line << I18n.l(log.created_at)
                line << log.ip
                line << ""
                line << ""
                if log.result_flag == Settings.SYSTEMLOG_RESULTFLG_SUCCESS
                  line << I18n.t('access_log.ACC_ACCESSLOG_SEARCHRESULTTABLE5')
                else
                  line << I18n.t('access_log.ACC_ACCESSLOG_SEARCHRESULTTABLE6')
                end
              else
                line << index
                line << log.user.get_name_no_prefix.to_s + log.user.user_name
                line << I18n.l(log.created_at)
                line << log.ip
              end
              csv << line
            end
          end
        end

        send_data csv_data, filename: filename

      else
        if params[:type] == "0"
          @logs = SystemLog.joins(:user).preload(:user).where(sql_texts.join(" AND "), sql_params).order("system_logs.created_at DESC").page(params[:page])
        else
          @logs = CourseAccessLog.joins(:user, :course).preload(:user).where(sql_texts.join(" AND "), sql_params).order("course_access_logs.created_at DESC").page(params[:page])
        end
      end
    end

  rescue => e
    logger.error e.backtrace.join("\n")
    @logs = nil
    flash[:notice] = e.message
  end

  def destroy
    ActiveRecord::Base.transaction do
      if params[:log]
        params[:log].each do |key, value|
          if params[:type].blank?
          elsif params[:type] == "0"
            SystemLog.destroy(value)
          else
            CourseAccessLog.destroy(value)
          end
        end
      end
    end
  ensure
    redirect_to :action => :index,
      :type => params[:type], :start_date => params[:start_date], :end_date => params[:end_date],
      :access_ip => params[:access_ip], :role => params[:role]
  end

  private
    def date_valid?(date)
      is_valid = false

      unless date.blank?
        date_ary = date.split("/")
        if date_ary.count == 3
          is_valid = true if Date.valid_date?(date_ary[0].to_i, date_ary[1].to_i, date_ary[2].to_i)
        end
      end

      is_valid

    rescue => e
      false
    end
end
