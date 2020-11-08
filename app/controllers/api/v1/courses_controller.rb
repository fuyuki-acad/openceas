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

# @api Courses
#
# コース情報API
#
class Api::V1::CoursesController < ApiController
  # @api List courses
  #
  # @param school_year [Optional, String]
  #   設定時、指定された値にてテーブル項目：school_yearを検索
  #   デフォルト値　なし
  #
  # @param account [Optional, String]
  #   設定時、指定された値にてテーブル項目：accountを部分一致にて検索
  #   デフォルト値　なし
  #
  # @param season_cd [Optional, Integer, 1|2|3|4|5|6|7|8|9]
  #   設定時、指定された値にてテーブル項目：season_cdを検索
  #   値の内容ついては設定ファイルに依存（デフォルト設定値）1:春、2:夏、3:秋、4:冬、5:前期、6:後期、7:集中、8:通年、9:その他
  #   デフォルト値　なし
  #
  # @param day_cd [Optional, Integer, 1|2|3|4|5|6|7]
  #   設定時、指定された値にてテーブル項目：day_cdを検索
  #   値の内容ついては設定ファイルに依存（デフォルト設定値）1:月、2:火、3:水、4:木、5:金、6:土、7:日
  #   デフォルト値　なし
  #
  # @param hour_cd [Optional, Integer]
  #   設定時、指定された値にてテーブル項目：hour_cdを検索
  #   デフォルト値　なし
  #
  # @example request
  #     curl -H 'Authorization: Bearer <token>' \
  #          https://<open_ceas>/api/v1/courses
  #
  # @example response
  #     [
  #       {
  #       	"id":15253,
  #       	"course_cd":"LO168002",
  #       	"course_name":"テスト科目1",
  #       	"overview":"テスト項目の内容について",
  #       	"school_year":2018,
  #       	"season_cd":8,
  #       	"day_cd":0,
  #       	"hour_cd":0,
  #       	"instructor_name":"担任1 , 担任2",
  #       	"major":"admin",
  #       	"class_session_count":15,
  #       	"indirect_use_flag":0,
  #       	"parent_course_id":null,
  #       	"group_folder_count":2,
  #       	"term_flag":1,
  #       	"open_course_pass":"course_password",
  #       	"open_course_flag":0,
  #       	"bbs_cd":null,
  #       	'"chat_cd":null,
  #       	"announcement_cd":1,
  #       	"faq_cd":1,
  #       	"open_course_bbs_flag":0,
  #       	"open_course_chat_flag":0,
  #       	"open_course_announcement_flag":0,
  #       	"open_course_faq_flag":0,
  #       	"attendance_ip_list":",,,",
  #       	"courseware_flag":0,
  #       	"courseware_rank":"0",
  #       	"season_cd1":null,
  #       	"day_cd1":null,
  #       	"hour_cd1":null,
  #       	"season_cd2":null,
  #       	"day_cd2":null,
  #       	"hour_cd2":null,
  #       	"season_cd3":null,
  #       	"day_cd3":null,
  #       	"hour_cd3":null,
  #       	"season_cd4":null,
  #       	"day_cd4":null,
  #       	"hour_cd4":null,
  #       	"unread_assignment_display_cd":0,
  #       	"unread_faq_display_cd":0,
  #       	"effective_date":null,
  #       	"effective_memo":null,
  #       	"insert_memo":null,
  #       	"insert_user_id":8716,
  #       	"update_memo":null,
  #       	"update_user_id":1,
  #       	"created_at":"2018-02-20T10:26:14.000+09:00",
  #       	"updated_at":"2018-02-21T10:00:17.000+09:00",
  #       	"deleted_at":"2018-02-20T10:45:11.000+09:00",
  #       	"delete_memo":null,
  #       	"delete_user_id":null
  #       }
  #     ]
  #
  # @return [Array, Course]
  def index
    sql_texts = []
    sql_params = {}

    sql_texts.push("courses.indirect_use_flag = :indirect_use_flag AND (courses.term_flag = :term_flag OR courses.courseware_flag = :courseware_flag)")
    sql_params[:indirect_use_flag] = "0"
    sql_params[:term_flag] = Settings.COURSE_SELFSTUDY_INVALIDITY
    sql_params[:courseware_flag] = "0"

    if !params[:school_year].blank?
      sql_texts.push("courses.school_year = :school_year")
      sql_params[:school_year] = params[:school_year]
    end
    if !params[:season_cd].blank?
      sql_texts.push("courses.season_cd = :season_cd")
      sql_params[:season_cd] = params[:season_cd]
    end
    if !params[:day_cd].blank?
      sql_texts.push("courses.day_cd = :day_cd")
      sql_params[:day_cd] = params[:day_cd]
    end
    if !params[:hour_cd].blank?
      sql_texts.push("courses.hour_cd = :hour_cd")
      sql_params[:hour_cd] = params[:hour_cd]
    end

    courses = Course.order(VIEW_COUSE_ORER)
      .where(sql_texts.join(" AND "), sql_params)
    render json: courses
  end

  # @api course data
  # @param course id [Required, Integer]
  #   必須項目。コースIDにてコース情報を取得
  #   デフォルト値　なし
  #
  # @example request
  #     curl -H 'Authorization: Bearer <token>' \
  #          https://<open_ceas>/api/v1/course/15253
  #
  # @example response
  #     {
  #       "id":15253,
  #       "course_cd":"LO168002",
  #      	"course_name":"テスト科目1",
  #      	"overview":"テスト項目の内容について",
  #      	"school_year":2018,
  #      	"season_cd":8,
  #      	"day_cd":0,
  #      	"hour_cd":0,
  #       "instructor_name":"担任1 , 担任2",
  #      	"major":"admin",
  #      	"class_session_count":15,
  #      	"indirect_use_flag":0,
  #      	"parent_course_id":null,
  #      	"group_folder_count":2,
  #      	"term_flag":1,
  #       "open_course_pass":"course_password",
  #      	"open_course_flag":0,
  #      	"bbs_cd":null,
  #      	'"chat_cd":null,
  #      	"announcement_cd":1,
  #      	"faq_cd":1,
  #       "open_course_bbs_flag":0,
  #      	"open_course_chat_flag":0,
  #      	"open_course_announcement_flag":0,
  #      	"open_course_faq_flag":0,
  #      	"attendance_ip_list":",,,",
  #      	"courseware_flag":0,
  #      	"courseware_rank":"0",
  #       "season_cd1":null,
  #      	"day_cd1":null,
  #      	"hour_cd1":null,
  #      	"season_cd2":null,
  #      	"day_cd2":null,
  #      	"hour_cd2":null,
  #      	"season_cd3":null,
  #       "day_cd3":null,
  #      	"hour_cd3":null,
  #      	"season_cd4":null,
  #      	"day_cd4":null,
  #      	"hour_cd4":null,
  #      	"unread_assignment_display_cd":0,
  #      	"unread_faq_display_cd":0,
  #      	"effective_date":null,
  #       "effective_memo":null,
  #      	"insert_memo":null,
  #      	"insert_user_id":8716,
  #      	"update_memo":null,
  #      	"update_user_id":1,
  #      	"created_at":"2018-02-20T10:26:14.000+09:00",
  #     	"updated_at":"2018-02-21T10:00:17.000+09:00",
  #       "deleted_at":"2018-02-20T10:45:11.000+09:00",
  #      	"delete_memo":null,
  #      	"delete_user_id":null
  #     }
  #
  # @return [Course]
  def show
    course = Course.find(params[:id])
    render json: course
  end
end
