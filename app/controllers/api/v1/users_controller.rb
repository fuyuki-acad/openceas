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

# @api Users
#
# ユーザ情報API
#
class Api::V1::UsersController < ApiController
  # @api List users
  #
  # @param user_name [Optional, String]
  #   設定時、指定された値にてテーブル項目：user_nameを部分一致にて検索
  #   デフォルト値　なし
  #
  # @param account [Optional, String]
  #   設定時、指定された値にてテーブル項目：accountを部分一致にて検索
  #   デフォルト値　なし
  #
  # @param role [Optional, String, "1"|"2"|"3"]
  #   設定時、指定された値にてテーブル項目：roleを検索
  #   1:Admin、2:Teacher、3:Student
  #   デフォルト値　なし
  #
  # @example request
  #     curl -H 'Authorization: Bearer <token>' \
  #          https://<open_ceas>/api/v1/users
  #
  # @example response
  #     [
  #       {
  #        "id":2934,
  #        "account":"taro.kio",
  #        "email":"taro.kio@gmail.com",
  #        "created_at":"2016-06-28T15:33:28.000+09:00",
  #        "updated_at":"2018-02-26T17:27:01.000+09:00",
  #        "user_name":"椎津　太郎",
  #        "kana_name":"シイズ　タロウ",
  #        "name_no_prefix":null,
  #        "display_name":null,
  #        "sex_cd":1,（1:男性、2:女性）
  #        "birth_date":"1980-01-01T09:00:00.000+09:00",
  #        "email_mobile":"椎津　太郎",
  #        "role_id":2,（1:Admin、2:Teacher、3:Student）
  #        "move_cd":0,
  #        "move_date":null,
  #        "information_cd":null,
  #        "term_flag":1,
  #        "myfolder_button_flag":0,
  #        "updated_type":2,
  #        "effective_date":null,
  #        "effective_memo":null,
  #        "insert_memo":null,
  #        "insert_user_id":null,
  #        "update_memo":null,
  #        "update_user_id":1,
  #        "deleted_at":"2018-02-22T10:12:18.000+09:00",
  #        "delete_memo":null,
  #        "delete_user_id":null,
  #        "deleted_res_at":null,
  #        "delete_res_memo":null,
  #        "locale":"ja",
  #        "uid":null,
  #        "provider":""
  #       }
  #     ]
  #
  # @return [Array, User]
  def index
    sql_texts = []
    sql_params = {}

    if !params[:user_name].blank?
      sql_texts.push("user_name like :user_name")
      sql_params[:user_name] = "%" + params[:user_name] + "%"
    end
    if !params[:account].blank?
      sql_texts.push("account like :account")
      sql_params[:account] = "%" + params[:account] + "%"
    end

    if !params[:role].blank?
      sql_texts.push("role_id = :role")
      sql_params[:role] = params[:role]
    end

    users = User.where(sql_texts.join(" AND "), sql_params)
    render json: users
  end

  # @api user data
  # @param user id [Required, Integer]
  #   必須項目。ユーザIDにてユーザ情報を取得
  #   デフォルト値　なし
  #
  # @example request
  #     curl -H 'Authorization: Bearer <token>' \
  #          https://<open_ceas>/api/v1/user/2934
  #
  # @example response
  #     {
  #      "id":2934,
  #      "account":"taro.kio",
  #      "email":"taro.kio@gmail.com",
  #      "created_at":"2016-06-28T15:33:28.000+09:00",
  #      "updated_at":"2018-02-26T17:27:01.000+09:00",
  #      "user_name":"椎津　太郎",
  #      "kana_name":"シイズ　タロウ",
  #      "name_no_prefix":null,
  #      "display_name":null,
  #      "sex_cd":1,（1:男性、2:女性）
  #      "birth_date":"1980-01-01T09:00:00.000+09:00",
  #      "email_mobile":"椎津　太郎",
  #      "role_id":2,（1:Admin、2:Teacher、3:Student）
  #      "move_cd":0,
  #      "move_date":null,
  #      "information_cd":null,
  #      "term_flag":1,
  #      "myfolder_button_flag":0,
  #      "updated_type":2,
  #      "effective_date":null,
  #      "effective_memo":null,
  #      "insert_memo":null,
  #      "insert_user_id":null,
  #      "update_memo":null,
  #      "update_user_id":1,
  #      "deleted_at":"2018-02-22T10:12:18.000+09:00",
  #      "delete_memo":null,
  #      "delete_user_id":null,
  #      "deleted_res_at":null,
  #      "delete_res_memo":null,
  #      "locale":"ja",
  #      "uid":null,
  #      "provider":""
  #     }
  #
  # @return [User]
  def show
    user = User.find(params[:id])
    render json: user
  end
end
