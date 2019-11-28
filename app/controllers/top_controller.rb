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

class TopController < ApplicationController
  OPEN_ANNOUNCEMENT_COUNT_LIMIT = 5
  OPEN_FAQ_COUNT_LIMIT = 5
  MAX_UNREAD_COUNT = 3

  def index
    if current_user.admin?
      sql_texts = []
      sql_params = {}

      if !params[:suggest].blank?
        if params[:type] == "0"
          sql_texts.push("course_name like :suggest")
          sql_params[:suggest] = "%" + params[:suggest] + "%"
        else
          sql_texts.push("instructor_name like :suggest")
          sql_params[:suggest] = "%" + params[:suggest] + "%"
        end
      end

      @announcements = Announcement.eager_load(:course)
        .where("announcements.announcement_cd = ? AND courses.term_flag = ? AND courses.announcement_cd = ?", Settings.ANNOUNCEMENT_ANNOUNCEMENTCD_INFO, true, true)
        .order("announcements.updated_at desc").page(params[:page])
        .limit(OPEN_ANNOUNCEMENT_COUNT_LIMIT)
      @faq_answers = FaqAnswer.order("faq_answers.updated_at desc")
        .joins({:faq => :course})
        .where("open_flag = ? AND courses.term_flag = ? AND courses.faq_cd = ?", true, true, true).limit(OPEN_FAQ_COUNT_LIMIT)
      @courses = Course.order("school_year DESC, day_cd, hour_cd, season_cd")
        .where(sql_texts.join(" AND "), sql_params).page(params[:page])

    elsif current_user.teacher?
      @announcements = Announcement.eager_load(:course)
        .where("announcements.announcement_cd = ? AND courses.term_flag = ? AND courses.announcement_cd = ?", Settings.ANNOUNCEMENT_ANNOUNCEMENTCD_INFO, true, true)
        .order("announcements.updated_at desc")
        .joins({:course => :course_assigned_users})
        .where("user_id = ?", current_user.id)
        .limit(OPEN_ANNOUNCEMENT_COUNT_LIMIT)
      @faq_answers = FaqAnswer.order("faq_answers.updated_at desc")
        .joins({:faq => {:course => :course_assigned_users}})
        .where("course_assigned_users.user_id = ? AND open_flag = ? AND response_flag = ? AND courses.term_flag = ? AND courses.faq_cd = ?", current_user.id, true, true, true, true)
        .limit(OPEN_FAQ_COUNT_LIMIT)

      sql_texts = []
      sql_params = {}
      sql_texts.push("course_assigned_users.user_id = :user_id")
      sql_texts.push("courses.indirect_use_flag = :indirect_use_flag")
      sql_texts.push("(courses.term_flag = :term_flag OR courses.courseware_flag = :courseware_flag)")
      sql_params[:user_id] = current_user.id
      sql_params[:indirect_use_flag] = false
      sql_params[:term_flag] = true
      sql_params[:courseware_flag] = true

      if !params[:suggest].blank?
        if params[:type] == "0"
          sql_texts.push("course_name like :suggest")
          sql_params[:suggest] = "%" + params[:suggest] + "%"
        else
          sql_texts.push("instructor_name like :suggest")
          sql_params[:suggest] = "%" + params[:suggest] + "%"
        end
      end

      @courses = Course.joins(:course_assigned_users)
        .where(sql_texts.join(" AND "), sql_params)
        .order("school_year DESC, day_cd, hour_cd, season_cd").page(params[:page])

      # 未読レポート・未回答FAQ
      unread_sql_params = {}
      unread_sql_text = "course_assigned_users.user_id = :user_id AND courses.indirect_use_flag = :indirect_use_flag" +
        " AND (courses.term_flag = :term_flag OR courses.courseware_flag = :courseware_flag)" +
        " AND (unread_assignment_essay_count_view.unread_count > 0 OR non_answer_faq_count_view.non_answer_count > 0)" +
        " AND (courses.unread_assignment_display_cd = 0 OR courses.unread_faq_display_cd = 0)"
      unread_sql_params[:user_id] = current_user.id
      unread_sql_params[:indirect_use_flag] = false
      unread_sql_params[:term_flag] = true
      unread_sql_params[:courseware_flag] = true
      @not_read_assignment_essay_and_faqs = Course.joins(:course_assigned_users)
        .joins("LEFT JOIN unread_assignment_essay_count_view ON unread_assignment_essay_count_view.course_id = courses.id")
        .joins("LEFT JOIN non_answer_faq_count_view ON non_answer_faq_count_view.course_id = courses.id")
        .where(unread_sql_text, unread_sql_params).order("school_year DESC, day_cd, hour_cd, season_cd").distinct.limit(MAX_UNREAD_COUNT)

      #登録した公開科目一覧
      @allocated_open_courses = Course.joins(:open_course_assigned_users).where("open_course_assigned_users.user_id = ?", current_user.id).order("courses.updated_at desc")

      #学習可能なコース一覧
      #コース関係は現在未定
      @self_studies = []

    else
      @announcements = Announcement.eager_load(:course)
        .where("announcements.announcement_cd = ? AND courses.term_flag = ? AND courses.announcement_cd = ?", Settings.ANNOUNCEMENT_ANNOUNCEMENTCD_INFO, true, true)
        .order("announcements.updated_at desc").joins({:course => :course_enrollment_users}).where("course_enrollment_users.user_id = ?", current_user.id)
        .limit(OPEN_ANNOUNCEMENT_COUNT_LIMIT)
      @faq_answers = FaqAnswer.order("faq_answers.updated_at desc")
        .joins({:faq => {:course => :course_enrollment_users}})
        .where("course_enrollment_users.user_id = ? AND open_flag = ? AND response_flag = ? AND courses.term_flag = ? AND courses.faq_cd = ?", current_user.id, true, true, true, true)
        .limit(OPEN_FAQ_COUNT_LIMIT)

      sql_params = {}
      sql_text = "user_id = :user_id AND indirect_use_flag = :indirect_use_flag AND courses.term_flag = :term_flag AND courseware_flag = :courseware_flag"
      sql_params[:user_id] = current_user.id
      sql_params[:indirect_use_flag] = false
      sql_params[:term_flag] = true
      sql_params[:courseware_flag] = false
      @courses = Course.joins(:course_enrollment_users)
        .where(sql_text, sql_params).order("school_year DESC, day_cd, hour_cd, season_cd").page(params[:page])

    end

    @open_courses = Course.order("school_year DESC, day_cd, hour_cd, season_cd").joins(:open_course_assigned_users)
      .where("open_course_assigned_users.user_id = ? AND courses.term_flag = ?", current_user.id, true).page(params[:page])
  end
end
