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

class Teacher::Result::CompoundsController < ApplicationController
  before_action :set_courses, only: [:index]
  before_action :set_course, only: [:show, :outputcsv_bulk]
  before_action :set_generic_page, only: [:result, :mark, :save, :graph, :outputcsv, :outputcsv_question]

  def show
    @compounds = @course.compounds.joins(:class_sessions)
  end

  def result
    start_count = 1
    max_count = @generic_page.max_count
    sql_order = ""

    # ひとまずユーザ順にソート
    if params[:term_flag] == "0" && params[:order] == "1"
      sql_order += "users.name_no_prefix DESC, users.user_name DESC"
    else
      sql_order += "users.name_no_prefix ASC, users.user_name ASC"
    end

    all_users = User.joins(:enrollment_courses).where("course_enrollment_users.course_id = ?", @generic_page.course.id).order(sql_order)

    if params[:term_flag] == "2"
      base_users = {}
      sort_users = {}
      all_users.each do |user|
        base_users.store(user.id, user)
        sort_users.store(user.id, 0)
      end

      if params[:count].to_i < 0
        answer_scores = @generic_page.answer_scores
      else
        answer_scores = @generic_page.answer_score_histories.where(:answer_count => params[:count].to_i)
      end

      answer_scores.each do |answer_score|
        if sort_users.key?(answer_score.user_id) && answer_score && answer_score.total_score
          sort_users.store(answer_score.user_id, answer_score.total_score)
        end
      end

      if params[:order] == "1"
        sort_users = sort_users.sort_by{|key,val| -val}
      else
        sort_users = sort_users.sort_by{|key,val| val}
      end

      all_users = []
      sort_users.each do |user_id, score|
        all_users << base_users[user_id]
      end
    end


    if params[:count].to_i > 0
      start_count = params[:count].to_i
      max_count = params[:count].to_i
    end

    @question_score = 0

    @generic_page.parent_questions.each do |parent_question|
      ## 設問に解答リストをセット
      parent_question.questions.each do |question|
        @question_score += question.score
      end
    end

    ## テスト結果の配列[履修者数][テスト回数][項目数(得点,ステータス,順位,採点済み人数、素点合計)]
    get_results(@generic_page, all_users, start_count, max_count)

    ## 履修者一覧を取得
    @users = []
    if params[:status].to_i > 0
      all_users.each do |user|
        @results.each do |count, result|
          if result[user.id]
            if result[user.id].total_score > Settings.ANSWERSCORE_TMP_SAVED_SCORE
              # 採点済み
              @users << user if params[:status] == "3"
            else
              # 未採点
              @users << user if params[:status] == "2"
            end
          elsif @generic_page.expired?
            # 不受験
            @users << user if params[:status] == "1"
          else
            # 未受験
            @users << user if params[:status] == "1"
          end
        end
      end
    else
      @users = all_users
    end

    session[:user_list] = @users.map {|user| user.id}
  end

  def graph
    @max_score = 0
    totalScore = 0
    @average = 0
    count = 0
    @max_score_acquisitor = nil
    @scores = {}
    @chart_data = {0 => 0, 11 => 0, 21 => 0, 31 => 0, 41 => 0, 51 => 0, 61 => 0, 71 => 0, 81 => 0, 91 => 0}

    ## テスト結果リストを取得
    answer_scores = AnswerScore.where("page_id = ? AND total_score >= 0", @generic_page.id).order("user_id ASC, answer_count DESC")
    ## 同じユーザの最後の解答以外削除
    answer_scores.each do |answer_score|
      next if @scores.key?(answer_score.user_id)
      @scores[answer_score.user_id] = answer_score
      case answer_score.total_score
      when 0..10
        @chart_data[0] += 1
      when 11..20
        @chart_data[11] += 1
      when 21..30
        @chart_data[21] += 1
      when 31..40
        @chart_data[31] += 1
      when 41..50
        @chart_data[41] += 1
      when 51..60
        @chart_data[51] += 1
      when 61..70
        @chart_data[61] += 1
      when 71..80
        @chart_data[71] += 1
      when 81..90
        @chart_data[81] += 1
      else
        @chart_data[91] += 1
      end
    end

    question_composition = @generic_page.get_question_composition

    ## 問題が選択式のみ、または記述式テストのとき
    if question_composition == Settings.QUESTIONCOMPOSITIONCD_MULTIPLEONLY
      @scores.each do |key, score|
        if score.total_score > @max_score
          @max_score = score.total_score
          @max_score_acquisitor = score.user
        end
        @average += score.total_score
        count += 1
      end

    ## 問題が複合式か記述のみかつ自己採点ありのとき
  elsif question_composition != Settings.QUESTIONCOMPOSITIONCD_MULTIPLEONLY &&
       (@generic_page.self_flag == Settings.GENERICPAGE_SELFFLG_SELF ||
        @generic_page.self_flag == Settings.GENERICPAGE_SELFFLG_MUTUAL ||
        @generic_page.self_flag == Settings.GENERICPAGE_SELFFLG_MUTUAL2)
      @scores.each do |key, score|
        if score.total_score && score.total_score >= 0
          if score.total_score > @max_score
            @max_score = score.total_score
            @max_score_acquisitor = score.user
          end
          @average += score.total_score
          count += 1

        elsif score.self_total_score && score.self_total_score >= 0
          if score.self_total_score > @max_score
            @max_score = score.self_total_score
            @max_score_acquisitor = score.user
          end
          @average += score.self_total_score
          count += 1
        end
      end
    end

    ## 問題が複合式か記述のみかつ自己採点なしのとき
    if question_composition != Settings.QUESTIONCOMPOSITIONCD_MULTIPLEONLY && @generic_page.self_flag == Settings.GENERICPAGE_SELFFLG_NONE
      @scores.each do |key, score|
        if score.total_score && score.total_score >= 0
          if score.total_score > @max_score
            @max_score = score.total_score
            @max_score_acquisitor = score.user
          end
          @average += score.total_score
          count += 1
        end
      end
    end

    @average = @average / count if count > 0
  end

  def mark
    @user = User.find(params[:user])
    @count = params[:count]
    @latest_answer = false

    ## テスト結果を取得
    answer_score = @generic_page.answer_score_histories.where("user_id = ? AND answer_count = ?", @user.id, @count).first
    ## 「未受験」「不受験」で採点する(された)学生の判定
    if answer_score.nil?
      @question_count = 0
      question_composition = @generic_page.get_question_composition

      ## 設問が存在すれば、未解答学生用の採点画面を表示するために
      if question_composition != Settings.QUESTIONCOMPOSITIONCD_NOTHING
        @question_count = -1
      end

      ## 総合得点の取得
      @question_score = 0
      @total_score = 0
      @generic_page.parent_questions.each do |parent|
        parent.questions.each do |question|
          @question_score += question.score

          user_answer = question.answer_histories.where("user_id = ? AND answer_count = ?", @user.id, @count).first
          if user_answer && !user_answer.score.blank?
            @total_score += user_answer.score
          end
        end
      end
      return
    end

    if answer_score.answer_count == answer_score.answer_score.answer_count
      answer_score = answer_score.answer_score
      @latest_answer = true
    end

    ## 採点対象の設問の数
    @question_count = 0
    @generic_page.parent_questions.each do |parent|
      @question_count += parent.questions.where("pattern_cd = ?", Settings.QUESTION_PATTERNCD_ESSAY).count
    end

    ## 記述式の合計点
    @essay_total_score = 0
    ## 生徒解答
    @user_answers = {}

    ## 自己採点なし||(自己採点あり&&得点が正)の時
    if @generic_page.self_flag == Settings.GENERICPAGE_SELFFLG_NONE ||
       ((@generic_page.self_flag == Settings.GENERICPAGE_SELFFLG_SELF ||
         @generic_page.self_flag == Settings.GENERICPAGE_SELFFLG_MUTUAL ||
         @generic_page.self_flag == Settings.GENERICPAGE_SELFFLG_MUTUAL2) &&
        answer_score.total_score > Settings.ANSWERSCORE_TMP_SAVED_SCORE)

      @generic_page.parent_questions.each do |parent|
        parent.essays.each do |question|
          user_answer = question.answer_histories.where("user_id = ? AND answer_count = ?", @user.id, @count).first
          @user_answers[question.id] = user_answer
          if user_answer && !user_answer.score.blank?
            @essay_total_score += user_answer.score
          end
        end
      end
      ## 自己採点あり&&得点が負の時
    elsif (@generic_page.self_flag == Settings.GENERICPAGE_SELFFLG_SELF ||
           @generic_page.self_flag == Settings.GENERICPAGE_SELFFLG_MUTUAL ||
           @generic_page.self_flag == Settings.GENERICPAGE_SELFFLG_MUTUAL2) &&
          answer_score.total_score < 0

      @generic_page.parent_questions.each do |parent|
        parent.essays.each do |question|
          user_answer = question.answer_histories.where("user_id = ?", @user.id).first
          @user_answers[question.id] = user_answer
          if user_answer && !user_answer.score.blank?
            @essay_total_score += user_answer.score
          end
        end
      end
    end

    ## 選択式の合計点
    @multiple_total_score = 0

    ## 大問リストを取得
    @generic_page.parent_questions.each do |parent|
      ## 設問に解答リストをセット
      parent.questions.each do |question|
        answer = question.answer_histories.where("user_id = ? AND answer_count = ?", @user.id, @count).first
        if answer && !answer.score.blank? && answer.text_answer.blank?
          @multiple_total_score += answer.score
        end
      end
    end
  end

  def save
    flash[:notice] = nil
    @user = User.find(params[:user])
    @count = params[:count]

    ActiveRecord::Base.transaction do
      answer_score = AnswerScore.where(:page_id => @generic_page.id, :user_id => @user.id).first
      if answer_score.nil?
        answer_score = AnswerScore.new(:page_id => @generic_page.id, :user_id => @user.id, answer_count: @count, :pass_cd => -1)
      elsif answer_score.answer_count != @count.to_i
        answer_score = AnswerScoreHistory.where(:page_id => @generic_page.id, :user_id => @user.id, :answer_count => @count).first
      end
      answer_score.save(validate: false) if answer_score.new_record?

      if !params[:essay_total_score].blank?
        ## 各設問の得点を取得する
        if params[:score]
          params[:score].each do |question_id, score|
            ## 各解答に点数をセットしupdateする
            answer = Answer.where(:question_id => question_id, :user_id => @user.id).first
            if answer.nil?
              answer = Answer.new(:question_id => question_id, :user_id => @user.id, :select_answer_id => 0, answer_score_id: answer_score.id)
            elsif answer.answer_count != @count.to_i
              answer = AnswerHistory.where(:question_id => question_id, :user_id => @user.id, :answer_count => @count).first
            end
            answer.score = score
            answer.save
          end
        end

        ## テスト結果をupdateする
        update_score(@generic_page, @user, @count)

      elsif !params[:total_score].blank?
        question_score = 0
        total_score = 0
        total_row_score = params[:total_score].to_i
        @generic_page.parent_questions.each do |parent|
          parent.questions.each do |question|
            question_score += question.score
          end
        end

        if question_score > 0 && total_row_score > 0
          if question_score < total_row_score
            total_score = total_row_score
            total_row_score = 0
          else
            total_score = total_row_score * 100 / question_score
          end
        end

        if params[:total_score] !~ /^[0-9]+$/
          raise I18n.t("materials_administration.MAT_ADM_COM_GRADECOMPOUND_HALFDIGIT")
        elsif params[:total_score].to_i > question_score
          raise I18n.t("materials_administration.MAT_ADM_COM_GRADECOMPOUND_BEYONDTOTALSCORE")
        end


        ## テスト結果をupdateする
        answer_score.total_score = total_score
        answer_score.total_raw_score = total_row_score
        answer_score.pass_cd= -1
        answer_score.save
      end
    end

    case params[:next_cd]
    when "1"
      unless session[:user_list].blank?
        user_index = session[:user_list].index(@user.id)
        if user_index && session[:user_list].count >= user_index+1
          next_user = session[:user_list][user_index+1]
          latest_score = @generic_page.latest_score(next_user)
          if latest_score
            redirect_to :action => :mark, :id => @generic_page, :user => next_user, :count => latest_score.answer_count
            return
          end
        end
      end
      redirect_to :action => :result, :id => @generic_page

    when "2"
      answer_score = AnswerScoreHistory.where(:page_id => @generic_page.id, :user_id => @user.id, :answer_count => @count.to_i + 1).first
      if answer_score
        redirect_to :action => :mark, :id => @generic_page, :user => @user.id, :count => @count.to_i + 1
        return
      end
      redirect_to :action => :result, :id => @generic_page

    else
      redirect_to :action => :result, :id => @generic_page

    end

  rescue => e
    flash[:notice] = e.message
    mark
    @total_score = params[:total_score]
    render :mark
  end

  def outputcsv_bulk
    bom = %w(EF BB BF).map { |e| e.hex.chr }.join
    csv_data = CSV.generate(bom) do |csv|
      csv << ["#{I18n.t('materials_administration.MAT_ADM_COM_ADMINISTRATECOMPOUND_CSVCOLUMN1')}#{@course.course_name}"]

      @course.compounds.each.with_index(1) do |compound|
        params[:id] = compound
        set_generic_page

        result

        csv << ["#{I18n.t('materials_administration.MAT_ADM_COM_ADMINISTRATECOMPOUND_CSVCOLUMN2')}#{@generic_page.generic_page_title}"]
        line = []
        line << I18n.t('common.COMMON_ACCOUNT')
        line << I18n.t('common.COMMON_TARGETNAME')
        @average_list.each do |key, average|
          line << "#{key}#{I18n.t('common.COMMON_COUNT2')}#{I18n.t('common.COMMON_RAWSCORE')}"
          line << "#{key}#{I18n.t('common.COMMON_COUNT2')}#{I18n.t('common.COMMON_PERCENTAGE')}"
        end
        csv << line

        @users.each.with_index(1) do |user, index|
          line = []
          line << user.account
          line << user.get_name_no_prefix + user.user_name
          @results.each do |count, result|
            if result[user.id] && result[user.id].total_score > Settings.ANSWERSCORE_TMP_SAVED_SCORE
              line << result[user.id].total_raw_score
            end

            if result[user.id] && result[user.id].total_score > Settings.ANSWERSCORE_TMP_SAVED_SCORE
              line << result[user.id].total_score
            end
          end
          csv << line
        end
      end
    end

    send_data csv_data, filename: "#{I18n.t('materials_administration.MAT_ADM_COM_ADMINISTRATECOMPOUND_CSVFILENAME')}.csv"
  end

  def outputcsv
    result

    bom = %w(EF BB BF).map { |e| e.hex.chr }.join
    csv_data = CSV.generate(bom) do |csv|
      csv << ["#{I18n.t('materials_administration.MAT_ADM_COM_ADMINISTRATECOMPOUND_CSVCOLUMN1')}#{@generic_page.course.course_name}"]
      csv << ["#{I18n.t('materials_administration.MAT_ADM_COM_ADMINISTRATECOMPOUND_CSVCOLUMN2')}#{@generic_page.generic_page_title}"]

      line = []
      line << I18n.t('common.COMMON_ACCOUNT')
      line << I18n.t('common.COMMON_TARGETNAME')
      @average_list.each do |key, average|
        line << "#{key}#{I18n.t('common.COMMON_COUNT2')}#{I18n.t('common.COMMON_RAWSCORE')}"
        line << "#{key}#{I18n.t('common.COMMON_COUNT2')}#{I18n.t('common.COMMON_PERCENTAGE')}"
      end
      csv << line

      @users.each.with_index(1) do |user, index|
        line = []
        line << user.account
        line << user.get_name_no_prefix + user.user_name
        @results.each do |count, result|
          if result[user.id] && result[user.id].total_score > Settings.ANSWERSCORE_TMP_SAVED_SCORE
            line << result[user.id].total_raw_score
          end

          if result[user.id] && result[user.id].total_score > Settings.ANSWERSCORE_TMP_SAVED_SCORE
            line << result[user.id].total_score
          end
        end
        csv << line
      end
    end

    send_data csv_data, filename: "#{I18n.t('materials_administration.MAT_ADM_COM_ADMINISTRATECOMPOUND_CSVFILENAME')}.csv"
  end

  def outputcsv_question
    bom = %w(EF BB BF).map { |e| e.hex.chr }.join
    csv_data = CSV.generate(bom) do |csv|
      csv << ["#{I18n.t('materials_administration.MAT_ADM_COM_ADMINISTRATECOMPOUND_CSVCOLUMN1')}#{@generic_page.course.course_name}"]
      csv << ["#{I18n.t('materials_administration.MAT_ADM_COM_ADMINISTRATECOMPOUND_CSVCOLUMN2')}#{@generic_page.generic_page_title}"]

      @generic_page.parent_questions.each.with_index(1) do |parent, parent_index|
        # 大問
        line = []
        line << I18n.t('materials_administration.COMMONMATERIALSADMINISTRATION_PARENTQUESTION')
        line << ""
        line << parent.content.html_safe
        csv << line

        # 設問
        line = []
        line << I18n.t('materials_administration.COMMONMATERIALSADMINISTRATION_QUESTION')
        line << ""

        header = []
        header << I18n.t('materials_administration.MAT_ADM_ASS_ASSIGNMENTESSAYTOTALRESULT_REPORTDOWNLOADCARD2')
        header << I18n.t('materials_administration.MAT_ADM_ASS_ASSIGNMENTESSAYTOTALRESULT_REPORTDOWNLOADCARD1')

        parent.questions.each.with_index(1) do |parent_question, question_index|
          line << parent_question.content.html_safe

          header << "#{I18n.t('common.COMMON_TEST_ANSWER')}#{parent_index}-#{question_index}"
        end
        csv << line

        # 空白行
        csv << []

        # 見出し
        csv << header

        # ユーザ一覧
        @generic_page.course.enrolled_users.each do |user|
          line = []
          if @generic_page.anonymous_flag == Settings.GENERICPAGE_ANONYNOUSFLG_ON
            line << "****"
            line << "****"
          else
            line << user.account
            line << user.get_name_no_prefix + user.user_name
          end

          parent.questions.each.with_index do |question, index|
            answers = Answer.where(["user_id = ? AND question_id = ?", user.id, question.id]).order("question_id")
            answer_texts = []
            answers.each do |answer|
              if question.pattern_cd == Settings.QUESTION_PATTERNCD_ESSAY
                answer_texts << answer.text_answer
              else
                select_quizze = question.select_quizzes.where(["select_quizzes.id = ?", answer.select_answer_id]).first
                answer_texts << select_quizze.content.html_safe if select_quizze.present?
              end
            end
            line << answer_texts.join(",")
          end

          csv << line
        end
      end

    end

    send_data csv_data, filename: "#{I18n.t('materials_administration.MAT_ADM_COM_ADMINISTRATECOMPOUND_CSVFILENAME')}.csv"
  end

  private
    def set_generic_page
      @generic_page = Compound.find_by(id: params[:id], type_cd: Settings.GENERICPAGE_TYPECD_COMPOUNDCODE)
    end

    def get_results(generic_page, users, start_count, max_count)
      @average_list = {}
      @results = {}

      if start_count < 0
        start_count = 1
        latest_flag = true
      else
        latest_flag = false
      end

      question_composition = generic_page.get_question_composition

      ## ユーザリスト件数分処理
      users.each do |user|
        ## 最終受験回数
        lastCount = 0
        ## 最大受験回数分処理
        start_count.upto(max_count)  do |count|
          @results[count] = {} if @results[count].nil?

          ## 学生[i]のテスト[j]回目の結果を取得する(一時保存結果を除く)
          answered_score =  generic_page.answer_score_histories.
            where("user_id = ? AND answer_count = ?", user.id, count).first

          ## テスト結果が存在する時は受験済み
          if answered_score
              @results[count][user.id] = answered_score
          end
        end
      end

      if latest_flag && max_count > 1
        users.each do |user|
          next if @results[max_count][user.id]

          (max_count - 1).downto(1) do |count|
            if @results[count][user.id]
              @results[max_count][user.id] = @results[count][user.id]
              break
            end
          end
        end

        (max_count - 1).downto(1) do |count|
          @results.delete(count)
        end
        start_count = max_count
      end

      ##
      ## 順位を求める
      ##
      ## 受験回数分処理
      start_count.upto(max_count)  do |count|
        totalScore = 0
        totalRawScore = 0
        count_r = 0

        ## ユーザリスト件数分処理
        users.each do |user|
          ## 順位初期値
          studentOrder = 0
          ## 得点が設定されている場合のみ順位付け
          if @results[count][user.id]
            ## 未採点は対象外
            next if @results[count][user.id].total_raw_score.nil? || @results[count][user.id].total_raw_score <= Settings.ANSWERSCORE_TMP_SAVED_SCORE

            totalScore += @results[count][user.id].total_score
            if @results[count][user.id].total_raw_score > Settings.ANSWERSCORE_TMP_SAVED_SCORE
              totalRawScore += @results[count][user.id].total_raw_score
              count_r += 1
            end

            studentOrder = 1
            ## 履修者数分処理
            users.each do |other|
              next if user.id == other.id || @results[count][other.id].nil? || @results[count][other.id].total_raw_score.nil? || @results[count][other.id].total_raw_score <= Settings.ANSWERSCORE_TMP_SAVED_SCORE
              ## 採点済みのみ対象
              if (question_composition == Settings.QUESTIONCOMPOSITIONCD_MULTIPLEONLY) ||
                 (question_composition == Settings.QUESTIONCOMPOSITIONCD_ESSAYONLY) ||
                 (question_composition == Settings.QUESTIONCOMPOSITIONCD_COMPOUND)
                ## 自身より得点の高い場合カウントアップ
                if @results[count][user.id].total_score < @results[count][other.id].total_score
                  studentOrder += 1
                end
              end
            end
            ## 履修者のテスト回の順位格納
            @results[count][user.id].rank = studentOrder
          end
        end

        ## 平均値を格納
        @average_list[count] = []
        if count_r > 0
          @average_list[count][0] = (totalRawScore / count_r).round
        else
          @average_list[count][0] = 0
        end
        if @results[count] && @results[count].count > 0
          @average_list[count][1] = (totalScore / @results[count].count).round
        else
          @average_list[count][1] = -1
        end
      end
    end

    def update_score(generic_page, user, count)
      scored_question_ids = []
      ## 合計点数(素点)
      totalScore = 0
      ## 合計点数(100点換算)
      totalScorePerHundred = 0

      totalAllotPoint = Question.joins(:parent => :generic_pages).where("generic_pages.id = ?", generic_page.id).sum("score")

      answers = AnswerHistory.joins(:question => [:parent => :generic_pages]).
        where("generic_pages.id = ? AND answer_histories.user_id = ? AND answer_histories.answer_count = ?", generic_page.id, user.id, count)
      answers.each do |answer|
        next if scored_question_ids.include?(answer.question_id)
        scored_question_ids << answer.question_id
        totalScore += answer.score
      end

      if totalAllotPoint > 0
        ## 合計得点(100点換算)を計算
        totalScorePerHundred = totalScore * 100 / totalAllotPoint
      end

      ## 合否コード
      if generic_page.pass_grade <= totalScorePerHundred
        passCd = Settings.ANSWERSCORE_PASSCD_SUBMITTED
      else
        passCd = Settings.ANSWERSCORE_PASSCD_UNSUBMITTING
      end

      ## テスト結果(answerScore)をDBに登録
      ## 回答した受験回数のテスト結果が存在する場合は上書きする
      answer_score = AnswerScore.where(["page_id = ? AND user_id = ?", @generic_page.id, user.id]).first
      if answer_score.blank?
        ##素点合計をset
        answer_score = AnswerScore.new
        answer_score.user_id = user.id
        answer_score.page_id = @generic_page.id
        answer_score.answer_count = count
      elsif answer_score.answer_count != count.to_i
        answer_score = AnswerScoreHistory.where(["page_id = ? AND user_id = ? AND answer_count = ?", @generic_page.id, user.id, count]).first
      end
      ##素点合計をset
      answer_score.total_score = totalScorePerHundred
      answer_score.total_raw_score = totalScore
      answer_score.pass_cd = passCd
      answer_score.save!
    end
end
