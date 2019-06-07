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

class Admin::SystemUsagesController < ApplicationController
  def index
    status = params["status"].presence || "1"

    sql_texts = []
    sql_params = {}

    if !params[:school_year].blank?
      sql_texts.push("courses.school_year = :school_year")
      sql_params[:school_year] = params[:school_year]
    end

    if !params[:season].blank?
      sql_texts.push("courses.season_cd = :season")
      sql_params[:season] = params[:season]
    end


    ## ステータスによって取得する項目を変えるステータスの内訳は以下の通り
		 # なお、statusが1から6の場合は同じテーブルから取得するのでdefaultにしている
		 # 1:授業資料
		 # 2:URL
		 # 3:複合式テスト
		 # 4:記号入力式テスト
		 # 5:レポート
		 # 6:アンケート
		 # 7:出席情報
		 # 8:お知らせ
		 # 9:Faq
		##
    case status
    when "7"
      order_text = "attendances.created_at"
      if params[:descend].blank?
        order_text += " DESC"
      end
      @logs = Attendance.joins(:course).where(sql_texts.join(" AND "), sql_params).order(order_text).page(params[:page])

    when "8"
      order_text = "announcements.created_at"
      if params[:descend].blank?
        order_text += " DESC"
      end
      @logs = Announcement.joins(:course).where(sql_texts.join(" AND "), sql_params).order(order_text).page(params[:page])

    when "9"
      order_text = "faqs.created_at"
      if params[:descend].blank?
        order_text += " DESC"
      end
      @logs = Faq.joins(:course).where(sql_texts.join(" AND "), sql_params).order(order_text).page(params[:page])

    else
      sql_texts.push("generic_pages.type_cd = :status")
      sql_params[:status] = status
      order_text = "generic_pages.created_at"
      if params[:descend].blank?
        order_text += " DESC"
      end
      @logs = GenericPage.joins(:course).where(sql_texts.join(" AND "), sql_params).order(order_text).page(params[:page])
    end
  end

  def summary
    if !params[:school_year].blank?
      @term1_start_date = get_date(params[:school_year], Settings.TERM1_START);
      @term1_end_date = get_date(params[:school_year], Settings.TERM1_END, @term1_start_date);
      @term2_start_date = get_date(params[:school_year], Settings.TERM2_START, @term1_end_date);
      @term2_end_date = get_date(params[:school_year], Settings.TERM2_END, @term2_start_date);

      # 春学期科目数
      @term1_subjects = CourseAccessLog.joins(:course, :user).
        where("users.role_id = ? AND course_access_logs.created_at >= ? AND course_access_logs.created_at < ?",
        Settings.USR_AUTHCD_INSTRUCTOR, @term1_start_date.strftime("%Y-%m-%d"), (@term1_end_date+1.day).strftime("%Y-%m-%d")).
        select("course_id").distinct

      # 秋学期科目数
      @term2_subjects = CourseAccessLog.joins(:course, :user).
        where("users.role_id = ? AND course_access_logs.created_at >= ? AND course_access_logs.created_at < ?",
        Settings.USR_AUTHCD_INSTRUCTOR, @term2_start_date.strftime("%Y-%m-%d"), (@term2_end_date+1.day).strftime("%Y-%m-%d")).
        select("course_id").distinct

      # 春学期担任者数(TA除く)
      @term1_instructors = SystemLog.joins(:user).
        where("users.role_id = ? AND users.account NOT LIKE ? AND system_logs.created_at >= ? AND system_logs.created_at < ?",
        Settings.USR_AUTHCD_INSTRUCTOR, Settings.TA_ACCOUNT + "%", @term1_start_date.strftime("%Y-%m-%d"), (@term1_end_date+1.day).strftime("%Y-%m-%d")).
        select("users.id").distinct

      # 春学期非常勤講師数
      @term1_parttime_instructors = SystemLog.joins(:user).
        where("users.role_id = ? AND users.account LIKE ? AND system_logs.created_at >= ? AND system_logs.created_at < ?",
        Settings.USR_AUTHCD_INSTRUCTOR, Settings.PARTTIME_ACCOUNT + "%", @term1_start_date.strftime("%Y-%m-%d"), (@term1_end_date+1.day).strftime("%Y-%m-%d")).
        select("users.id").distinct

      # 秋学期担任者数(TA除く)
      @term2_instructors = SystemLog.joins(:user).
        where("users.role_id = ? AND users.account NOT LIKE ? AND system_logs.created_at >= ? AND system_logs.created_at < ?",
        Settings.USR_AUTHCD_INSTRUCTOR, Settings.TA_ACCOUNT + "%", @term2_start_date.strftime("%Y-%m-%d"), (@term2_end_date+1.day).strftime("%Y-%m-%d")).
        select("users.id").distinct

      # 秋学期非常勤講師数
      @term2_parttime_instructors = SystemLog.joins(:user).
        where("users.role_id = ? AND users.account LIKE ? AND system_logs.created_at >= ? AND system_logs.created_at < ?",
        Settings.USR_AUTHCD_INSTRUCTOR, Settings.PARTTIME_ACCOUNT + "%", @term2_start_date.strftime("%Y-%m-%d"), (@term2_end_date+1.day).strftime("%Y-%m-%d")).
        select("users.id").distinct

      # 春学期学生数
      @term1_students = SystemLog.joins(:user).
        where("users.role_id = ? AND system_logs.created_at >= ? AND system_logs.created_at < ?",
        Settings.USR_AUTHCD_STUDENT, @term1_start_date.strftime("%Y-%m-%d"), (@term1_end_date+1.day).strftime("%Y-%m-%d")).
        select("users.id").distinct

      # 秋学期学生数
      @term2_students = SystemLog.joins(:user).
        where("users.role_id = ? AND system_logs.created_at >= ? AND system_logs.created_at < ?",
        Settings.USR_AUTHCD_STUDENT, @term2_start_date.strftime("%Y-%m-%d"), (@term2_end_date+1.day).strftime("%Y-%m-%d")).
        select("users.id").distinct

      # 全学期担任者数(TA除く)
      @whole_instructors = SystemLog.joins(:user).
        where("users.role_id = ? AND users.account NOT LIKE ? AND system_logs.created_at >= ? AND system_logs.created_at < ?",
        Settings.USR_AUTHCD_INSTRUCTOR, Settings.TA_ACCOUNT + "%", @term1_start_date.strftime("%Y-%m-%d"), (@term2_end_date+1.day).strftime("%Y-%m-%d")).
        select("users.id").distinct

      # 全学期担任者数(TA除く)
      @whole_parttime_instructors = SystemLog.joins(:user).
        where("users.role_id = ? AND users.account LIKE ? AND system_logs.created_at >= ? AND system_logs.created_at < ?",
        Settings.USR_AUTHCD_INSTRUCTOR, Settings.PARTTIME_ACCOUNT + "%", @term1_start_date.strftime("%Y-%m-%d"), (@term2_end_date+1.day).strftime("%Y-%m-%d")).
        select("users.id").distinct

      # 全学期学生数
      @whole_students = SystemLog.joins(:user).
        where("users.role_id = ? AND system_logs.created_at >= ? AND system_logs.created_at < ?",
        Settings.USR_AUTHCD_STUDENT, @term1_start_date.strftime("%Y-%m-%d"), (@term2_end_date+1.day).strftime("%Y-%m-%d")).
        select("users.id").distinct
    end
  end

  private
    def get_date(school_year, month_day, previous = nil)
      date = month_day.split("/")
      new_date = Date.new(school_year.to_i, date[0].to_i, date[1].to_i)

      if previous
        new_date += 1.years if previous > new_date
      end

      new_date
    end
end
