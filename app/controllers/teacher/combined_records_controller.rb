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

class Teacher::CombinedRecordsController < ApplicationController
  before_action :set_courses, only: [:index]
  before_action :set_course, except: [:index]

  OUTPUTSEQUENCE = [6, 0, 1, 2, 3, 5, 4]
  COMPOUND_CD = 0;        # 複合式テスト
  MULTIPLEFIB_CD = 1;     # 記号入力式テスト
  ASSIGNMENTESSAY_CD = 2; # レポート
  QUESTIONNAIRE_CD = 3;   # アンケート
  ATTENDACE_CD = 4;       # 出席情報
  EVALUATIONLIST_CD = 5;  # 評価記入リスト
  MATERIAL_COUNT = 7;     # 教材の数
  COMPOUND_CD2 = 6;       # 複合式テスト(素点)

  require 'csv'

  def index
  end

  def show
    # 各授業回数、種類の列数[授業回数][テスト種類]
    initialize_class_session_column_count
    @selected = ""

    unless params[:select]
      params[:select] = [COMPOUND_CD.to_s, MULTIPLEFIB_CD.to_s, ASSIGNMENTESSAY_CD.to_s, QUESTIONNAIRE_CD.to_s, ATTENDACE_CD.to_s, EVALUATIONLIST_CD.to_s]
    end

    unless params[:select].nil?
      # 複合式テストの結果一覧取得[授業回数][確認回数の最大値][学生数]
      if params[:select].include?(COMPOUND_CD.to_s) || params[:select].include?(COMPOUND_CD2.to_s)
        # 各授業回数の複合式テストのリストを取得
        # 各授業回数のページのリストのリストを返す
        generic_page_list = get_generic_page_list(Settings.GENERICPAGE_TYPECD_COMPOUNDCODE)

        # 複合式テストの結果一覧を取得
        @compounds = get_material_total_result(generic_page_list)

        if params[:select].include?(COMPOUND_CD.to_s)
          allocated_count = get_allocated_count(generic_page_list)
          set_class_session_column_count(COMPOUND_CD, allocated_count)

          @selected += COMPOUND_CD.to_s
        end
        if params[:select].include?(COMPOUND_CD2.to_s)
          allocated_count = get_allocated_count(generic_page_list)
          set_class_session_column_count(COMPOUND_CD2, allocated_count)

          @selected += COMPOUND_CD2.to_s
        end

        # 自己採点フラグリストを取得する
        @self_flags = get_self_flags(generic_page_list)

        # 配点合計リストを取得する
#      int[][] totalAllotPointArray = getTotalAllotPoint(classSessionCount, genericPageListList);
      end

      # 記号入力式テストの結果一覧取得[授業回数][確認回数の最大値][学生数]
      if params[:select].include?(MULTIPLEFIB_CD.to_s)
        # 各授業回数の記号入力式テストのリストを取得
        # 各授業回数のページのリストのリストを返す
        generic_page_list = get_generic_page_list(Settings.GENERICPAGE_TYPECD_MULTIPLEFIBCODE)

        # 記号入力式テストの結果一覧を取得
        @multiple_fibs = get_material_total_result(generic_page_list)

        # 各授業回数の記号入力式テストの割り付け数のリストをセットする
        allocated_count = get_allocated_count(generic_page_list)
        set_class_session_column_count(MULTIPLEFIB_CD, allocated_count)

        @selected += MULTIPLEFIB_CD.to_s
      end

      # レポートの結果一覧取得[授業回数][確認回数の最大値][学生数]
      if params[:select].include?(ASSIGNMENTESSAY_CD.to_s)
        # 各授業回数のレポートのリストを取得
        # 各授業回数のページのリストのリストを返す
        generic_page_list = get_generic_page_list(Settings.GENERICPAGE_TYPECD_ASSIGNMENTESSAYCODE)

        # レポートの結果一覧を取得
        @assignment_essays = get_material_total_result(generic_page_list)

        # 各授業回数のレポートの割り付け数のリストをセットする
        allocated_count = get_allocated_count(generic_page_list)
        set_class_session_column_count(ASSIGNMENTESSAY_CD, allocated_count)

        # レポートタイプ配列を作成
        @return_method_cds = generic_page_list

        @selected += ASSIGNMENTESSAY_CD.to_s
      end

      # アンケートの結果一覧取得[授業回数][確認回数の最大値][学生数]
      if params[:select].include?(QUESTIONNAIRE_CD.to_s)
        # 各授業回数のアンケートのリストを取得
        # 各授業回数のページのリストのリストを返す
        generic_page_list = get_generic_page_list(Settings.GENERICPAGE_TYPECD_QUESTIONNAIRECODE)

        # アンケートの結果一覧を取得
        @questionnaires = get_material_total_result(generic_page_list)

        # 各授業回数のレポートの割り付け数のリストをセットする
        allocated_count = get_allocated_count(generic_page_list)
        set_class_session_column_count(QUESTIONNAIRE_CD, allocated_count)

        @selected += QUESTIONNAIRE_CD.to_s
      end

      # 評価記入リストの結果一覧取得[授業回数][確認回数の最大値][学生数]
      if params[:select].include?(EVALUATIONLIST_CD.to_s)
        # 各授業回数の評価記入リストのリストを取得
        # 各授業回数のページのリストのリストを返す
        generic_page_list = get_generic_page_list(Settings.GENERICPAGE_TYPECD_EVALUATIONLISTCODE)

        # 評価記入リストの結果一覧を取得
        @evaluations = get_material_total_result(generic_page_list)

        # 各授業回数の評価記入リストの割り付け数のリストをセットする
        allocated_count = get_allocated_count(generic_page_list)
        set_class_session_column_count(EVALUATIONLIST_CD, allocated_count)

        @selected += EVALUATIONLIST_CD.to_s
      end

      # 出席の結果一覧取得[学生数][授業回数][確認回数の最大値]
      if params[:select].include?(ATTENDACE_CD.to_s)
        # 指定した科目に関連のある確認回数を取得
        attendance_list = []
        for class_session_count in 0..@course.class_session_count
          attendance_list << @course.attendances.where(class_session_no: class_session_count)
        end

        # 確認回数のリストを取得
        @attendances = get_attendance_data_for_combined_record(attendance_list)

        # 各授業回数の出席の確認回数のリストをセットする
        allocated_count = get_allocated_count(attendance_list)
        set_class_session_column_count(ATTENDACE_CD, allocated_count)

        @selected += ATTENDACE_CD.to_s
      end
    end
  end

  def output_csv
    selected = params["select"].split(//)
    respond_to do |format|
      format.html
      format.csv { send_data create_csv(selected), filename: "combinedRecord.csv" }
    end
  end

  def create_csv(selected)
    # 各授業回数、種類の列数[授業回数][テスト種類]
    initialize_class_session_column_count

    # 各授業回数のページのリストのリストを返す
    # 複合式テストの結果一覧を取得
#    unless params[:select].nil?
      # 複合式テストの結果一覧取得[授業回数][確認回数の最大値][学生数]"
      if selected.include?(COMPOUND_CD.to_s) || selected.include?(COMPOUND_CD2.to_s)
        generic_page_list = get_generic_page_list(Settings.GENERICPAGE_TYPECD_COMPOUNDCODE)
        @compounds = get_material_total_result(generic_page_list)
        if selected.include?(COMPOUND_CD.to_s)
          allocated_count = get_allocated_count(generic_page_list)
          set_class_session_column_count(COMPOUND_CD, allocated_count)
        end
        if selected.include?(COMPOUND_CD2.to_s)
          allocated_count = get_allocated_count(generic_page_list)
          set_class_session_column_count(COMPOUND_CD2, allocated_count)
        end

        # 自己採点フラグリストを取得する
        @self_flags = get_self_flags(generic_page_list)
      end

      # 記号入力式テストの結果一覧を取得
      if selected.include?(MULTIPLEFIB_CD.to_s)
        generic_page_list = get_generic_page_list(Settings.GENERICPAGE_TYPECD_MULTIPLEFIBCODE)
        @multiple_fibs = get_material_total_result(generic_page_list)
        allocated_count = get_allocated_count(generic_page_list)
        set_class_session_column_count(MULTIPLEFIB_CD, allocated_count)
      end

      # レポートの結果一覧を取得
      if selected.include?(ASSIGNMENTESSAY_CD.to_s)
        generic_page_list = get_generic_page_list(Settings.GENERICPAGE_TYPECD_ASSIGNMENTESSAYCODE)
        @assignment_essays = get_material_total_result(generic_page_list)
        allocated_count = get_allocated_count(generic_page_list)
        set_class_session_column_count(ASSIGNMENTESSAY_CD, allocated_count)
        @return_method_cds = generic_page_list
      end

      # アンケートの結果一覧を取得
      if selected.include?(QUESTIONNAIRE_CD.to_s)
        generic_page_list = get_generic_page_list(Settings.GENERICPAGE_TYPECD_QUESTIONNAIRECODE)
        @questionnaires = get_material_total_result(generic_page_list)
        allocated_count = get_allocated_count(generic_page_list)
        set_class_session_column_count(QUESTIONNAIRE_CD, allocated_count)
      end

      # 評価記入リストの結果一覧を取得
      if selected.include?(EVALUATIONLIST_CD.to_s)
        generic_page_list = get_generic_page_list(Settings.GENERICPAGE_TYPECD_EVALUATIONLISTCODE)
        @evaluations = get_material_total_result(generic_page_list)
        allocated_count = get_allocated_count(generic_page_list)
        set_class_session_column_count(EVALUATIONLIST_CD, allocated_count)
      end

      # 確認回数のリストを取得
      if selected.include?(ATTENDACE_CD.to_s)
        attendance_list = []
        for class_session_count in 0..@course.class_session_count
          attendance_list << @course.attendances.where(class_session_no: class_session_count)
        end
        @attendances = get_attendance_data_for_combined_record(attendance_list)
        allocated_count = get_allocated_count(attendance_list)
        set_class_session_column_count(ATTENDACE_CD, allocated_count)
      end
#    end

    bom = %w(EF BB BF).map { |e| e.hex.chr }.join
    csv_data = CSV.generate(bom) do |csv|
      # ヘッダ1
      header1 = []
      # 学生(学籍番号,氏名)
      header1 << I18n.t('common.COMMON_STUDENT')
      header1 << ""

      # 授業回数
      for class_session_count in 0..@course.class_session_count
        if class_session_count == 0
          header1 << I18n.t('combinedRecord.COM_COMBINEDRECORD_COMMON')
        else
          header1 << class_session_count.to_s + I18n.t('common.COMMON_COUNT1')
        end

        count = 0
        @classSessionColumnCount[class_session_count].each do |column_count|
          count += column_count
        end
        for index in 2..count
          header1 << ""
        end
      end
      csv << header1

      # ヘッダ2
      header2 = []
      # 学生(学籍番号,氏名)
      header2 << ""
      header2 << ""
      # 授業回数
      for class_session_count in 0..@course.class_session_count
        # 教材の種類
        count = 0
        @classSessionColumnCount[class_session_count].each do |column_count|
          count += column_count
        end
        if count == 0
          header2 << I18n.t('combinedRecord.COM_COMBINEDRECORD_NOTHING')
        elsif count > 0
          # 教材の種類
          OUTPUTSEQUENCE.each do |type_cd|
            # 各教材の回数
            for cloumn_count in 1..@classSessionColumnCount[class_session_count][type_cd]
              case type_cd
              when COMPOUND_CD2 then
                header2 << I18n.t('combinedRecord.COM_COMBINEDRECORD_COMPOUNDOMIT_RAW')
                header2 << I18n.t('combinedRecord.COM_COMBINEDRECORD_COMPOUNDOMIT_PERCENTAGE') if @classSessionColumnCount[class_session_count][COMPOUND_CD] > 0
              when COMPOUND_CD then
                # 素点があった場合出力しない
                header2 << I18n.t('combinedRecord.COM_COMBINEDRECORD_COMPOUNDOMIT_PERCENTAGE') if @classSessionColumnCount[class_session_count][COMPOUND_CD2] == 0
              when MULTIPLEFIB_CD then
                header2 << I18n.t('combinedRecord.COM_COMBINEDRECORD_MULTIPLEFIBOMIT')
              when ASSIGNMENTESSAY_CD then
                header2 << I18n.t('combinedRecord.COM_COMBINEDRECORD_ASSIGNMENTESSAYOMIT')
              when QUESTIONNAIRE_CD then
                header2 << I18n.t('combinedRecord.COM_COMBINEDRECORD_QUESTIONNAIREOMIT')
              when EVALUATIONLIST_CD then
                header2 << I18n.t('combinedRecord.COM_COMBINEDRECORD_EVALUATIONLISTOMIT')
              when ATTENDACE_CD then
                header2 << I18n.t('combinedRecord.COM_COMBINEDRECORD_ATTENDANCE')
              end
            end
          end
        end
      end
      csv << header2

      # 学生ごとのデータ
      # 学生数
      @course.enrolled_users.each.with_index(1) do |user, user_index|
        line = []
        line << user.get_name_no_prefix
        line << user.user_name
#        pw.print(CSVUtil.nameNoPrefixConverter(studentArray[i].getNameNoPrefix()) + ",");

        # 授業回数
        for class_session_count in 0..@course.class_session_count
          count = 0
          # 教材の種類
          @classSessionColumnCount[class_session_count].each do |column_count|
            count += column_count
          end

          if count == 0
            line << ""
          else
            # 教材の種類
            OUTPUTSEQUENCE.each do |type_cd|
              # 各教材の回数
              for cloumn_count in 0..@classSessionColumnCount[class_session_count][type_cd] - 1
                case type_cd
                # 複合式テスト(素点)
                when COMPOUND_CD2 then
                  unless @compounds.nil?
                    unless @compounds[class_session_count][cloumn_count][user.id].nil?
                      unless @compounds[class_session_count][cloumn_count][user.id].self_total_score.nil?
                        # 未採点&&自己採点アリの時は、自己採点を出力
                        # 素点はnullの可能性があるので変換する
                        if @compounds[class_session_count][cloumn_count][user.id].self_total_score >= 0 && @compounds[class_session_count][cloumn_count][user.id].total_raw_score.nil?
                          if @self_flags[class_session_count][cloumn_count] == Settings.GENERICPAGE_SELFFLG_SELF || @self_flags[class_session_count][cloumn_count] == Settings.GENERICPAGE_SELFFLG_MUTUAL || @self_flags[class_session_count][cloumn_count] == Settings.GENERICPAGE_SELFFLG_MUTUAL2
                            line << @compounds[class_session_count][cloumn_count][user.id].self_total_score
                          else
                            line << ""
                          end
                        # 採点済の時は、合計得点を100点換算し出力
                        elsif @compounds[class_session_count][cloumn_count][user.id].self_total_score >= 0 && @compounds[class_session_count][cloumn_count][user.id].total_raw_score >= 0
                          line << @compounds[class_session_count][cloumn_count][user.id].total_raw_score
                        else
                          line << ""
                        end
                      else
                        line << ""
                      end

                      # 百分率も設定されていたら出力する
                      if @classSessionColumnCount[class_session_count][COMPOUND_CD] > 0
                        unless @compounds[class_session_count][cloumn_count][user.id].self_total_score.nil?
                          # 未採点&&自己採点アリの時は、自己採点を出力
                          if @compounds[class_session_count][cloumn_count][user.id].self_total_score >= 0 && @compounds[class_session_count][cloumn_count][user.id].total_score < 0
                            if @self_flags[class_session_count][cloumn_count] == Settings.GENERICPAGE_SELFFLG_SELF || @self_flags[class_session_count][cloumn_count] == Settings.GENERICPAGE_SELFFLG_MUTUAL || @self_flags[class_session_count][cloumn_count] == Settings.GENERICPAGE_SELFFLG_MUTUAL2
                              line << @compounds[class_session_count][cloumn_count][user.id].self_total_score
                            else
                              line << ""
                            end
                          # 採点済の時は、合計得点を100点換算し出力
                          elsif @compounds[class_session_count][cloumn_count][user.id].self_total_score >= 0 && @compounds[class_session_count][cloumn_count][user.id].total_score >= 0
                            line << @compounds[class_session_count][cloumn_count][user.id].total_score
                          else
                            line << ""
                          end
                        else
                          line << ""
                        end
                      end
                    else
                      line << ""
                      line << "" if @classSessionColumnCount[class_session_count][COMPOUND_CD] > 0
                    end
                  end

                # 複合式テスト（百分率)
                when COMPOUND_CD then
                  # 素点が設定されていたら出力しない
                  if @classSessionColumnCount[class_session_count][COMPOUND_CD2] <= 0
                    unless @compounds.nil?
                      unless @compounds[class_session_count][cloumn_count][user.id].nil?
                        unless @compounds[class_session_count][cloumn_count][user.id].self_total_score.nil?
                          # 未採点&&自己採点アリの時は、自己採点を出力
                          if @compounds[class_session_count][cloumn_count][user.id].self_total_score >= 0 && @compounds[class_session_count][cloumn_count][user.id].total_score < 0
                            if @self_flags[class_session_count][cloumn_count] == Settings.GENERICPAGE_SELFFLG_SELF || @self_flags[class_session_count][cloumn_count] == Settings.GENERICPAGE_SELFFLG_MUTUAL || @self_flags[class_session_count][cloumn_count] == Settings.GENERICPAGE_SELFFLG_MUTUAL2
                              line << @compounds[class_session_count][cloumn_count][user.id].self_total_score
                            else
                              line << ""
                            end
                          # 採点済の時は、合計得点を100点換算し出力
                          elsif @compounds[class_session_count][cloumn_count][user.id].self_total_score >= 0 && @compounds[class_session_count][cloumn_count][user.id].total_score >= 0
                            line << @compounds[class_session_count][cloumn_count][user.id].total_score
                          else
                            line << ""
                          end
                        else
                          line << ""
                        end
                      else
                        line << ""
                      end
                    end
                  end

                # 記号入力式テスト
                when MULTIPLEFIB_CD then
                  if @multiple_fibs
                    if @multiple_fibs[class_session_count][cloumn_count][user.id].nil?
                      line << ""
                    else
                      line << @multiple_fibs[class_session_count][cloumn_count][user.id].total_score
                    end
                  end

                # レポート
                when ASSIGNMENTESSAY_CD then
                  if @assignment_essays
                    if @assignment_essays[class_session_count][cloumn_count][user.id].nil?
                      line << ""
                    else
                      if @return_method_cds[class_session_count][cloumn_count].assignment_essay_return_method_cd == 0
                        if @assignment_essays[class_session_count][cloumn_count][user.id].assignment_essay_score.nil?
                          line << @assignment_essays[class_session_count][cloumn_count][user.id].total_score
                        else
                          line << @assignment_essays[class_session_count][cloumn_count][user.id].assignment_essay_score
                        end
                      else
                        line << @assignment_essays[class_session_count][cloumn_count][user.id].assignment_essay_score
                      end
                    end
                  end

                # アンケート
                when QUESTIONNAIRE_CD then
                  if @questionnaires
                    if @questionnaires[class_session_count][cloumn_count][user.id].nil?
                      line << ""
                    else
                      line << I18n.t('combinedRecord.COM_COMBINEDRECORD_CIRCLE')
                    end
                  end

                # 連結評価一覧表
                when EVALUATIONLIST_CD then
                  if @evaluations
                    if @evaluations[class_session_count][cloumn_count][user.id].nil?
                      line << ""
                    else
                      line << @evaluations[class_session_count][cloumn_count][user.id].assignment_essay_score
                    end
                  end

                # 出席
                when ATTENDACE_CD then
                  if @attendances
                    case @attendances[class_session_count][cloumn_count][user.id]
                    when Settings.ATTENDANCEINFO_ATTENDANCEDATACD_UNREGISTRATION then
                      line << ""
                    when Settings.ATTENDANCEINFO_ATTENDANCEDATACD_ATTENDANCE then
                      line << I18n.t('combinedRecord.COM_COMBINEDRECORD_CIRCLE')
                    when Settings.ATTENDANCEINFO_ATTENDANCEDATACD_LATE then
                      line << I18n.t('combinedRecord.COM_COMBINEDRECORD_TRIANGLE')
                    when Settings.ATTENDANCEINFO_ATTENDANCEDATACD_ABSENT then
                      line << I18n.t('combinedRecord.COM_COMBINEDRECORD_X')
                    end
                  end
                end
              end
            end
          end
        end

        csv << line
      end

    end
  end

  def get_generic_page_list(type_cd)
    # 各授業回数のページのリストのリストを返す
    generic_page_list = [];
    for class_session_count in 0..@course.class_session_count
      unless @course.class_session(class_session_count).nil?
        generic_page_list << @course.class_session(class_session_count).generic_pages.where(type_cd: type_cd)
      else
        generic_page_list << nil
      end
    end

    return generic_page_list
  end

  def get_self_flags(generic_page_list)
    # テスト数の最大値を取得
    max_count = 0
    generic_page_list.each do |generic_page|
      unless generic_page.nil?
        max_count = generic_page.count if max_count < generic_page.count
      end
    end

    # resultArray[授業回数][テスト数の最大値]のselfFlg
    results = []
    for class_session_count in 0..@course.class_session_count
      results << []
      for test_count in 0..max_count - 1
        results[class_session_count] << {}
      end
    end

    for class_session_count in 0..@course.class_session_count
      # その授業回数に割り付けられているページのリスト
      if generic_page_list[class_session_count]
        generic_page_list[class_session_count].each.with_index do |generic_page, generic_page_count|
          results[class_session_count][generic_page_count] = generic_page.self_flag
        end
      end
    end

    return results;
  end

  def initialize_class_session_column_count
    # 各授業回数、種類の列数[授業回数][テスト種類]
    @classSessionColumnCount = []
    for class_session_count in 0..@course.class_session_count
      @classSessionColumnCount << []
      for material_count in 0..MATERIAL_COUNT
        @classSessionColumnCount[class_session_count] << 0
      end
    end
  end

  def get_allocated_count(generic_page_list)
    allocated_count = []
    generic_page_list.each do |generic_page|
      unless generic_page.nil?
        allocated_count << generic_page.count
      else
        allocated_count << 0
      end
    end

    return allocated_count
  end

  def set_class_session_column_count(type_cd, allocated_count)
    for class_session_count in 0..@course.class_session_count
      @classSessionColumnCount[class_session_count][type_cd] = allocated_count[class_session_count].nil? ? 0 : allocated_count[class_session_count]
    end
  end

  def get_material_total_result(generic_page_list)
    # テスト数の最大値を取得
    max_count = 0
    generic_page_list.each do |generic_page|
      unless generic_page.nil?
        max_count = generic_page.count if max_count < generic_page.count
      end
    end

    # resultArray[授業回数][テスト数の最大値][学生数]の点数
    results = []
    for class_session_count in 0..@course.class_session_count
      results << []
      for test_count in 0..max_count - 1
        results[class_session_count] << {}
      end
    end

    for class_session_count in 0..@course.class_session_count
      # 割り付けられているページ数
      if generic_page_list[class_session_count]
        generic_page_list[class_session_count].each.with_index do |generic_page, generic_page_count|

          # 学生数
          @course.enrolled_users.each do |user|
            if generic_page.type_cd == Settings.GENERICPAGE_TYPECD_QUESTIONNAIRECODE
              answer_score = generic_page.answer_scores.where("user_id = ? AND total_score >= ?", user.id, 0).order('answer_count desc').first
            else
              answer_score = generic_page.answer_scores.where(:user_id => user.id).order('answer_count desc').first
            end
            unless answer_score
              results[class_session_count][generic_page_count].store(user.id, nil)
            else
              answer_score.self_total_score = 0 if answer_score.self_total_score.nil? || answer_score.self_total_score < 0
              results[class_session_count][generic_page_count].store(user.id, answer_score)
            end
          end
        end
      end
    end

    return results
  end

  def get_attendance_data_for_combined_record(attendance_list)
    # 確認回数の最大値を取得
    max_count = 0
    attendance_list.each do |attendance|
      max_count = attendance.count if max_count < attendance.count
    end

    # resultArray[授業回数][テスト数の最大値][学生数]の点数
    results = []
    for class_session_count in 0..@course.class_session_count
      results << []
      for test_count in 0..max_count - 1
        results[class_session_count] << {}
      end
    end

    # 1回以上出席収集をしている時
    if max_count > 0
      # 授業回数
      for class_session_count in 0..@course.class_session_count
        # 確認回数
        if attendance_list[class_session_count]
          attendance_list[class_session_count].each.with_index do |attendance, attendance_count|

            # 学生数
            @course.enrolled_users.each do |user|
              # 該当学生の出席情報ものを抽出
              attendance_information = AttendanceInformation.where("attendance_id = ? AND attendance_information.user_id = ?", attendance.id, user.id).first

              # 出席情報があれば、出席情報コードを入れる
              unless attendance_information
                results[class_session_count][attendance_count].store(user.id, Settings.ATTENDANCEINFO_ATTENDANCEDATACD_UNREGISTRATION)
              else
                results[class_session_count][attendance_count].store(user.id, attendance_information.attendance_data_cd)
              end
            end
          end
        end
      end
    else
      results = nil
    end

    return results
  end
end
