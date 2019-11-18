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

class AnnouncementsController < ApplicationController
  def index
    sql_texts = []
    sql_params = {}

    if !params[:keyword].blank?
      case params[:type1]
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

    sql_texts.push("courses.courseware_flag = :courseware_flag")
    sql_params[:courseware_flag] = "0"

    sql_texts.push("announcements.announcement_cd = :announcement_cd")
    sql_params[:announcement_cd] = Settings.ANNOUNCEMENT_ANNOUNCEMENTCD_INFO

    if current_user.admin?
      @announcements = Announcement.eager_load(:course).where(sql_texts.join(" AND "), sql_params).
        order("announcements.updated_at desc").page(params[:page]).page(params[:page])
    elsif current_user.teacher?
      @announcements = Announcement.eager_load(:course).where(sql_texts.join(" AND "), sql_params).
        order("announcements.updated_at desc").joins({:course => :course_assigned_users}).where("user_id = ?", current_user.id).page(params[:page])
    else
      @announcements = Announcement.eager_load(:course).where(sql_texts.join(" AND "), sql_params).
        order("announcements.updated_at desc").joins({:course => :course_enrollment_users}).where("user_id = ?", current_user.id).page(params[:page])
    end
  end

  def show
    @announcement = Announcement.find(params[:id])
  end
end
