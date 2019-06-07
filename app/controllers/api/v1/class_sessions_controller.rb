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

# @api ClassSessions
#
# 授業実施情報API
#
class Api::V1::ClassSessionsController < ApiController
  # @api List class sessions
  #
  # @param course id [Required, Integer]
  #   必須項目。指定されたコースIDに関連する授業実施情報を取得
  #   デフォルト値　なし
  #
  # @example request
  #     curl -H 'Authorization: Bearer <token>' \
  #          https://<open_ceas>/api/v1/class_sessions/15253
  #
  # @example response
  #     [
  #       {
  #         "id":13966,
  #         "course_id":15253,
  #         "class_session_no":0,
  #         "class_session_title":null,
  #         "overview":null,
  #         "class_session_day":"共通ページ",
  #         "class_session_memo":null,
  #         "class_session_memo_closed":null,
  #         "effective_date":null,
  #         "effective_memo":null,
  #         "insert_memo":null,
  #         "insert_user_id":8716,
  #         "update_memo":null,
  #         "update_user_id":8716,
  #         "created_at":"2018-02-20T10:26:14.000+09:00",
  #         "updated_at":"2018-02-20T10:26:14.000+09:00",
  #         "materials":[<<GenericPage情報>>],
  #         "urls":[<<GenericPage情報>>],
  #         "componds":[<<GenericPage情報>>],
  #         "multiplefibs":[<<GenericPage情報>>],
  #         "essays":[<<GenericPage情報>>],
  #         "questionnaires":[<<GenericPage情報>>]
  #       }
  #     ]
  #
  # @return [Array, ClassSession]
  def index
    sessions = []
    course = Course.find(params[:course_id])

    course.class_sessions.each do |session|
      sessions << to_hash(session)
    end

    render json: sessions
  end

  # @api class session data
  # @param class_session id [Required, Integer]
  #   必須項目。ClassSession IDにて授業実施情報を取得
  #   デフォルト値　なし
  #
  # @example request
  #     curl -H 'Authorization: Bearer <token>' \
  #          https://<open_ceas>/api/v1/class_session/13966
  #
  # @example response
  #     {
  #       "id":13966,
  #       "course_id":15253,
  #       "class_session_no":0,
  #       "class_session_title":null,
  #       "overview":null,
  #       "class_session_day":"共通ページ",
  #       "class_session_memo":null,
  #       "class_session_memo_closed":null,
  #       "effective_date":null,
  #       "effective_memo":null,
  #       "insert_memo":null,
  #       "insert_user_id":8716,
  #       "update_memo":null,
  #       "update_user_id":8716,
  #       "created_at":"2018-02-20T10:26:14.000+09:00",
  #       "updated_at":"2018-02-20T10:26:14.000+09:00",
  #       "materials":[<<GenericPage情報>>],
  #       "urls":[<<GenericPage情報>>],
  #       "componds":[<<GenericPage情報>>],
  #       "multiplefibs":[<<GenericPage情報>>],
  #       "essays":[<<GenericPage情報>>],
  #       "questionnaires":[<<GenericPage情報>>]
  #     }
  #
  # @return [ClassSession]
  def show
    session = ClassSession.find(params[:id])
    render json: to_hash(session)
  end

  private
    def to_hash(class_session)
      session = class_session.attributes
      session["materials"] = class_session.materials
      session["urls"] = class_session.urls
      session["componds"] = class_session.componds
      session["multiplefibs"] = class_session.multiplefibs
      session["essays"] = class_session.essays
      session["questionnaires"] = class_session.questionnaires
      session["questionnaires"] = class_session.evaluations
      session
    end
end
