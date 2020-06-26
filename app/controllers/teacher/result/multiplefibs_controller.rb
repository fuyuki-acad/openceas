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

class Teacher::Result::MultiplefibsController < ApplicationController
  before_action :require_assigned, only: [:show, :outputcsv_bulk, :result, :outputcsv]
  before_action :set_courses, only: [:index]
  before_action :set_course, only: [:show, :outputcsv_bulk]
  before_action :set_generic_page, only: [:result, :outputcsv]

  def show
    @multiplefibs = @course.multiplefibs.joins(:class_sessions)
  end

  def result
    ## 結果格納用
    @average_list = {}
    @results = {}

    ## 履修者数分処理
    enrolled_users = @generic_page.course.enrolled_users
    enrolled_users.each do |user|
      ## 最大受験回数分処理
      1.upto(@generic_page.max_count)  do |count|
        @results[count] = {} if @results[count].nil?

        ## 学生[i]のテスト[j]回目の結果を取得する
        answered_score =  @generic_page.answer_score_histories.
          where("user_id = ? AND answer_count = ? AND total_score >= ?", user.id, count, Settings.ANSWERSCORE_TMP_SAVED_SCORE).first

        ## テスト結果が存在する場合
        if answered_score
          @results[count][user.id] = answered_score
        end
      end
    end

    ##
    ## 順位を求める
    ##
    ## 受験回数分処理
    1.upto(@generic_page.max_count)  do |count|
      ## ユーザリスト件数分処理
      enrolled_users.each do |user|
        ## 順位初期値
        studentOrder = 0
        ## 得点が設定されている場合のみ順位付け
        if @results[count][user.id]
          studentOrder = 1
          ## 履修者数分処理
          enrolled_users.each do |other|
            next if user.id == other.id || @results[count][other.id].nil?
            ## 自身より得点の高い場合カウントアップ
            if @results[count][user.id].total_score < @results[count][other.id].total_score
              studentOrder += 1
            end
          end
          ## 履修者のテスト回の順位格納
          @results[count][user.id].rank = studentOrder
        end
      end
    end

    ## テスト回数分処理
    1.upto(@generic_page.max_count)  do |count|
      answered_scores =  @generic_page.answer_score_histories.where("answer_count = ? AND total_score >= 0", count)

      ## テスト回の平均点
      averageScore = 0
      ## テスト回の合計点数
      totalScore = 0
      ## テスト回の採点済み人数
      gradedCount = answered_scores.count
      ## 履修者数分処理
      answered_scores.each do |answered_score|
        ## 採点済みの履修者のみ対象
        ## テスト回の合計点数に得点を加算
        totalScore += answered_score.total_score
      end
      ## 採点済み人数が発生する場合のみ
      if gradedCount > 0
        ## 「テスト回の合計点 / テスト回の採点済み人数」（小数点1位で四捨五入）を平均として格納
        averageScore = (totalScore / gradedCount).round
      end
      ## 平均値を格納
      @average_list[count] = averageScore
    end
  end

  def outputcsv_bulk
    bom = %w(EF BB BF).map { |e| e.hex.chr }.join
    csv_data = CSV.generate(bom) do |csv|
      csv << ["#{I18n.t('materials_administration.MAT_ADM_COM_ADMINISTRATECOMPOUND_CSVCOLUMN1')}#{@course.course_name}"]

      @course.multiplefibs.each do |multiplefib|
        params[:id] = multiplefib
        set_generic_page

        result

        csv << ["#{I18n.t('materials_administration.MAT_ADM_COM_ADMINISTRATECOMPOUND_CSVCOLUMN2')}#{@generic_page.generic_page_title}"]

        line = []
        line << I18n.t('common.COMMON_ACCOUNT')
        line << I18n.t('common.COMMON_TARGETNAME')
        1.upto(@generic_page.max_count) do |index|
          line << "#{index}#{t("common.COMMON_COUNT2")}"
        end
        csv << line

        @generic_page.course.enrolled_users.each do |user|
          line = []
          line << user.account
          line << user.get_name_no_prefix + user.user_name

          1.upto(@generic_page.max_count) do |index|
            if @results[index][user.id] && @results[index][user.id].total_score >= @generic_page.pass_grade
              line << @results[index][user.id].total_score
            else
              if @results[index][user.id]
                line << @results[index][user.id].total_score
              end
            end
          end
          csv << line
        end
      end
    end

    send_data csv_data, filename: "#{I18n.t('materials_administration.MAT_ADM_MUL_ADMINISTRATEMULTIPLEFIB_CSVFILENAME')}.csv"
  end

  def outputcsv
    result

    bom = %w(EF BB BF).map { |e| e.hex.chr }.join
    csv_data = CSV.generate(bom) do |csv|
      csv << ["#{I18n.t('materials_administration.MAT_ADM_COM_ADMINISTRATECOMPOUND_CSVCOLUMN1')}#{@generic_page.course.course_name}aaaaaaaaaaaaaaaaaaaaaa"]
      csv << ["#{I18n.t('materials_administration.MAT_ADM_COM_ADMINISTRATECOMPOUND_CSVCOLUMN2')}#{@generic_page.generic_page_title}"]

      line = []
      line << I18n.t('common.COMMON_ACCOUNT')
      line << I18n.t('common.COMMON_TARGETNAME')
      1.upto(@generic_page.max_count) do |index|
        line << "#{index}#{t("common.COMMON_COUNT2")}"
      end
      csv << line

      @generic_page.course.enrolled_users.each do |user|
        line = []
        line << user.account
        line << user.get_name_no_prefix + user.user_name

        1.upto(@generic_page.max_count) do |index|
          if @results[index][user.id] && @results[index][user.id].total_score >= @generic_page.pass_grade
            line << @results[index][user.id].total_score
          else
            if @results[index][user.id]
              line << @results[index][user.id].total_score
            end
          end
        end
        csv << line
      end
    end

    send_data csv_data, filename: "#{I18n.t('materials_administration.MAT_ADM_MUL_ADMINISTRATEMULTIPLEFIB_CSVFILENAME')}.csv"
  end

  private
    def set_generic_page
      @generic_page = GenericPage.find_by(id: params[:id], type_cd: Settings.GENERICPAGE_TYPECD_MULTIPLEFIBCODE)
    end
end
