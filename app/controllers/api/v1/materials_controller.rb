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

# @api Materials
#
# 授業資料情報API
#
class Api::V1::MaterialsController < ApiController
  # @api List generic pages
  #
  # @param course id [Required, Integer]
  #   必須項目。指定されたコースIDに関連する授業資料情報を取得
  #   デフォルト値　なし
  #
  # @param type_cd [Optional, Integer]
  #   設定時、指定された値にてテーブル項目：type_cdを検索
  #   値の内容ついては設定ファイルに依存（デフォルト設定値）1:授業資料、2:参考URL
  #   デフォルト値　なし
  #
  # @example request
  #     curl -H 'Authorization: Bearer <token>' \
  #          https://<open_ceas>/api/v1/materials/15253
  #
  # @example response
  #     [
  #       {
  #         "id":49186,
  #       	"course_id":15253,
  #       	"generic_page_title":"授業教材",
  #       	"pass_grade":null,
  #       	"max_count":0,
  #       	"start_pass":null,
  #       	"start_time":null,
  #       	"end_time":null,
  #       	"self_flag":0,
  #       	"self_pass":null,
  #       	"url_content":null,
  #       	"type_cd":1,
  #       	"file_name":"授業教材.pdf",
  #       	"link_name":"15191827976700902.pdf",
  #       	"explanation_file_name":null,
  #       	"explanation_link_name":null,
  #       	"edit_flag":0,
  #       	"anonymous_flag":0,
  #       	"timelag_flag":0,
  #       	"pre_grading_enable_flag":0,
  #       	"assignment_essay_return_method_cd":null,
  #       	"score_open_flag":0,
  #       	"fck_flag":0,"material_memo":"",
  #       	"material_memo_closed":"",
  #       	"content":null,
  #       	"start_flag":0,
  #       	"stop_flag":0,
  #       	"interview_flag":0,
  #       	"effective_date":null,
  #       	"effective_memo":null,
  #       	"insert_memo":null,
  #       	"insert_user_id":8717,
  #       	"update_memo":null,
  #       	"update_user_id":8717,
  #       	"created_at":"2018-02-21T12:13:17.000+09:00",
  #       	"updated_at":"2018-02-21T12:13:17.000+09:00"
  #       },
  #       {
  #         "id":49234,
  #         "course_id":15253,
  #         "generic_page_title":"参考URL",
  #         "pass_grade":null,
  #         "max_count":0,
  #         "start_pass":null,
  #         "start_time":null,
  #         "end_time":null,
  #         "self_flag":0,
  #         "self_pass":"",
  #         "url_content":"http://www.xxxxxxx.co.jp",
  #         "type_cd":2,
  #         "file_name":null,
  #         "link_name":null,
  #         "explanation_file_name":null,
  #         "explanation_link_name":null,
  #         "edit_flag":0,
  #         "anonymous_flag":0,
  #         "timelag_flag":0,
  #         "pre_grading_enable_flag":0,
  #         "assignment_essay_return_method_cd":null,
  #         "score_open_flag":0,
  #         "fck_flag":0,
  #         "material_memo":"",
  #         "material_memo_closed":null,
  #         "content":null,
  #         "start_flag":0,
  #         "stop_flag":0,
  #         "interview_flag":0,
  #         "effective_date":null,
  #         "effective_memo":null,
  #         "insert_memo":null,
  #         "insert_user_id":8717,
  #         "update_memo":null,
  #         "update_user_id":8717,
  #         "created_at":"2018-04-04T09:41:18.000+09:00",
  #         "updated_at":"2018-04-04T09:41:18.000+09:00"
  #       }
  #     ]
  #
  # @return [Array, GenericPage]
  def index
    sql_texts = []
    sql_params = {}

    sql_texts.push("course_id = :course_id")
    sql_params[:course_id] = params[:course_id]

    if params[:type_cd].blank?
      sql_texts.push("type_cd IN (:type_cd)")
      sql_params[:type_cd] = [Settings.GENERICPAGE_TYPECD_MATERIALCODE, Settings.GENERICPAGE_TYPECD_URLCODE]
    else
      sql_texts.push("type_cd = :type_cd")
      sql_params[:type_cd] = params[:type_cd]
    end

    pages = GenericPage.where(sql_texts.join(" AND "), sql_params)
    render json: pages
  end

  # @api generic page data
  # @param generic_page id [Required, Integer]
  #   必須項目。GenericPage IDにて授業資料情報を取得
  #   デフォルト値　なし
  #
  # @example request
  #     curl -H 'Authorization: Bearer <token>' \
  #          https://<open_ceas>/api/v1/material/49186
  #
  # @example response
  #     {
  #       "id":49186,
  #     	"course_id":15253,
  #      	"generic_page_title":"授業教材",
  #      	"pass_grade":null,
  #      	"max_count":0,
  #      	"start_pass":null,
  #       "start_time":null,
  #      	"end_time":null,
  #      	"self_flag":0,
  #      	"self_pass":null,
  #      	"url_content":null,
  #      	"type_cd":1,
  #      	"file_name":"授業教材.pdf",
  #       "link_name":"15191827976700902.pdf",
  #      	"explanation_file_name":null,
  #      	"explanation_link_name":null,
  #      	"edit_flag":0,
  #      	"anonymous_flag":0,
  #      	"timelag_flag":0,
  #      	"pre_grading_enable_flag":0,
  #      	"assignment_essay_return_method_cd":null,
  #       "score_open_flag":0,
  #      	"fck_flag":0,"material_memo":"",
  #      	"material_memo_closed":"",
  #      	"content":null,
  #      	"start_flag":0,
  #      	"stop_flag":0,
  #      	"interview_flag":0,
  #       "effective_date":null,
  #      	"effective_memo":null,
  #      	"insert_memo":null,
  #      	"insert_user_id":8717,
  #      	"update_memo":null,
  #      	"update_user_id":8717,
  #      	"created_at":"2018-02-21T12:13:17.000+09:00",
  #      	"updated_at":"2018-02-21T12:13:17.000+09:00"
  #     }
  #
  # @return [GenericPage]
  def show
    page = GenericPage.find(params[:id])
    render json: page
  end
end
