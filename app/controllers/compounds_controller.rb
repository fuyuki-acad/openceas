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

class CompoundsController < ApplicationController
  before_action :require_enrolled_or_open_assigned, only: [:show, :password]
  before_action :require_enrolled, only: [:confirm, :save, :mark, :mark_password, :self_mark, :update_self_score, :finish]
  skip_before_action :verify_authenticity_token, only: :confirm
  before_action :set_generic_page, only: [:show, :password, :confirm, :save, :mark, :mark_password, :self_mark, :update_self_score, :finish]

  def show
    create_access_log(@generic_page.course.id)

    @execute_flag = false

		## /// テスト開始前の各チェック /////
    ## 最新の解答結果を取得
    @latest_score = @generic_page.latest_score(current_user.id)

    # 回答済、未採点の場合自己採点へ
    if @latest_score && @latest_score.total_score < Settings.ANSWERSCORE_TMP_SAVED_SCORE
      if @generic_page.self_flag == Settings.GENERICPAGE_SELFFLG_SELF ||
          @generic_page.self_flag == Settings.GENERICPAGE_SELFFLG_MUTUAL ||
          @generic_page.self_flag == Settings.GENERICPAGE_SELFFLG_MUTUAL2
        redirect_to :action => :self_mark, :id => @generic_page
        return
      end
    end

    if params[:back] && session[:answers]
      @execution_count = get_execution_count(@generic_page)
      @answers = session[:answers]
      session[:answers] = nil
      @execute_flag = true
      return
    end

    ## 複合式テストに解答した回数を取得
    if @latest_score.blank?
      @execution_count = 1
    else
      @execution_count = @latest_score.answer_count
    end

    session[:answers] = nil

    ## 解答取得
    @answers = get_answers(@generic_page, @execution_count)

		## 受付期間
		## 【まだ受付開始していない時】
		if @generic_page.not_ready?
			@message = I18n.t("execution.MAT_EXE_MUL_ERROREXECUTEMULTIPLEFIB_NOTREADYSTARTTIME_html", :param0 => I18n.l(@generic_page.start_time))
			render "error"
      return
		end
		## 【1回も受験していない時】
		if @latest_score.nil?
			## 【すでに受付終了している時はエラー画面へ】
			if @generic_page.expired?
        @message = I18n.t("execution.MAT_EXE_MUL_ERROREXECUTEMULTIPLEFIB_ALREADYPASSEDENDTIME_html", :param0 => I18n.l(@generic_page.end_time))
  			render "error"
        return
			end

		## 1回以上受験している時
		else

			## 「未受験」「不受験」で採点する(された)学生の判定 kitajima
			@notExaminationFlg = 0

			## 一時保存されている場合　
			if @latest_score.saved?
				## 一時保存かつ受付終了　
        if @generic_page.expired?
          @message = I18n.t("execution.MAT_EXE_MUL_ERROREXECUTEMULTIPLEFIB_ALREADYPASSEDENDTIME_html", :param0 => I18n.l(@generic_page.end_time))
    			render "error"
          return
  			end
				## 一時保存かつ受付終了前
				## 【複合式テストを一時保存データで実施する準備をする】
				if @generic_page.start_pass.blank? || session[:start_pass_flag]
          ## 受験指示パスワードがない時
          @execute_flag = true
          return
				else
          ## 受験指示パスワードがある時
          @execution_count = get_execution_count(@generic_page)
          render "start_password"
          return
				end
			end

			## 【自己採点が終わっていない時は自己採点画面or自己採点開始パスワード画面へ】
      if @generic_page.self_flag == Settings.GENERICPAGE_SELFFLG_SELF ||
         @generic_page.self_flag == Settings.GENERICPAGE_SELFFLG_MUTUAL ||
         @generic_page.self_flag == Settings.GENERICPAGE_SELFFLG_MUTUAL2

				## フラグを設定
				@execute_flag = true
				@finish_cd = 1

        if @latest_score.self_total_score < Settings.ANSWERSCORE_TMP_SAVED_SCORE
          if !@generic_page.self_pass.blank? || session[:mark_pass_flag]
            ## 採点開始パスワードがある時
            @execution_count = get_execution_count(@generic_page, false)
  					render "mark_password"
            return
  				else
            ## 採点開始パスワードがない時
            redirect_to :action => :self_mark, :id => @generic_page
            return
    			end
    		end
      end

			## 設問構成を取得
			question_composition = @generic_page.get_question_composition

			if @latest_score.total_score < Settings.ANSWERSCORE_TMP_SAVED_SCORE
        ## 担任者の採点が終わっていない
				## 【すでに受付終了している時→解答結果画面へ】
				if @generic_page.expired?
          @message = I18n.t("execution.MAT_EXE_MUL_ERROREXECUTEMULTIPLEFIB_ALREADYPASSEDENDTIME_html", :param0 => I18n.l(@generic_page.end_time))
          render "mark"
          return

				else
          ## 受付終了していない
					## 【すでに受験回数分受験している時→解答結果画面へ】
          if @generic_page.max_count <= @latest_score.answer_count
            @message = I18n.t("execution.MAT_EXE_MUL_ERROREXECUTEMULTIPLEFIB_ALREADYEXAMEDMAXCOUNT_html", param0: @generic_page.max_count)
            render "mark"
            return
					else
            ## 【受験回数分受験していない時→エラー画面へ】
            @message = I18n.t("execution.MAT_EXE_COM_ERROREXECUTECOMPOUND_NOTGRADEYET")
            render "error"
            return
					end
				end

			else
        ## 担任者の採点が終わっている
				## 選択式のみの設問構成の時
				if question_composition == Settings.QUESTIONCOMPOSITIONCD_MULTIPLEONLY
					## 【すでに合格している時→解答結果画面へ】
					if @generic_page.passed?(current_user.id)
						if @generic_page.expired?
              @message = I18n.t("execution.MAT_EXE_MUL_ERROREXECUTEMULTIPLEFIB_ALREADYPASSEDENDTIME_html", :param0 => I18n.l(@generic_page.end_time))
            elsif @generic_page.max_count <= @latest_score.answer_count
              @message = I18n.t("execution.MAT_EXE_MUL_ERROREXECUTEMULTIPLEFIB_ALREADYEXAMEDMAXCOUNT_html", param0: @generic_page.max_count)
            end

            render "mark"
            return

					else
            ## 合格していない
						## 【すでに受付終了している時→解答結果画面へ】
						if @generic_page.expired?
              @message = I18n.t("execution.MAT_EXE_MUL_ERROREXECUTEMULTIPLEFIB_ALREADYPASSEDENDTIME_html", :param0 => I18n.l(@generic_page.end_time))
              render "mark"
              return

						else
              ## 受付終了していない
							## 【すでに受験回数分受験している時→解答結果画面へ】
							if @generic_page.max_count <= @latest_score.answer_count
                @message = I18n.t("execution.MAT_EXE_MUL_ERROREXECUTEMULTIPLEFIB_ALREADYEXAMEDMAXCOUNT_html", param0: @generic_page.max_count)
                render "mark"
                return
							end
						end
					end

				elsif question_composition == Settings.QUESTIONCOMPOSITIONCD_ESSAYONLY || question_composition == Settings.QUESTIONCOMPOSITIONCD_COMPOUND
          ## 記述式のみ||複合式の設問構成の時
					## 【すでに受付終了している時→解答結果画面へ】
          if @generic_page.expired?
            @message = I18n.t("execution.MAT_EXE_MUL_ERROREXECUTEMULTIPLEFIB_ALREADYPASSEDENDTIME_html", :param0 => I18n.l(@generic_page.end_time))
            render "mark"
            return

					else
            ## 受付終了していない
						## 【すでに受験回数分受験している時→解答結果画面へ】
            if @generic_page.max_count <= @latest_score.answer_count
              @message = I18n.t("execution.MAT_EXE_MUL_ERROREXECUTEMULTIPLEFIB_ALREADYEXAMEDMAXCOUNT_html", param0: @generic_page.max_count)
							render "mark"
              return
						end
					end
				end
			end
		end
		## /// テスト開始前の各チェック ここまで /////
    @execute_flag = true

    if @latest_score && @latest_score.total_score != Settings.ANSWERSCORE_TMP_SAVED_SCORE
      @execution_count += 1
      ## 解答取得
      @answers = get_answers(@generic_page, @execution_count)
    end

    if @generic_page.start_pass.blank? || session[:start_pass_flag]
			## 受験指示パスワードがない時
		else
      ## 受験指示パスワードがある時
      render "start_password"
		end
  end

  def password
    if params[:start_pass].blank?
      @message = I18n.t("execution.COMMONMATERIALSEXECUTION_STARTPASSWORDCHECK1")
    elsif params[:start_pass] == @generic_page.start_pass
      session[:start_pass_flag] = true
      show
      render :action => :show
    else
      @message = I18n.t("execution.COMMONMATERIALSEXECUTION_STARTPASSWORDCHECK2")
      @execution_count = get_execution_count(@generic_page)
      render "start_password"
    end
  end

  def confirm
    @execute_flag = true
		## 未受験者との区別
		@notExaminationFlg = 0

    ## 最新の解答結果を取得
    @latest_score = @generic_page.latest_score(current_user.id)
    ## 複合式テストに解答した回数を取得
    @execution_count = get_execution_count(@generic_page)

		## テストが選択式の設問のみで構成されているかどうかチェック
    @question_composition_cd = @generic_page.get_question_composition

    ## 解答(選択肢)をセットする
    @answers = {}
    if params[:answers]
      params[:answers].each do |key, values|
        @answer = Answer.new(:question_id => key, :user_id => current_user.id, :answer_count => 1)
        if @answer.question.pattern_cd == Settings.QUESTION_PATTERNCD_CHECK
          @answers[key] = []
          values.each do |value|
            if value["select_answer_id"]
              @answer.select_answer_id = value["select_answer_id"]
              @answers[key] << @answer
              @answer = Answer.new(:question_id => key, :user_id => current_user.id, :answer_count => 1)
            end
          end
        else
          @answer.select_answer_id = values["select_answer_id"] if values["select_answer_id"]
          @answer.text_answer = values["text_answer"] if values["text_answer"]
          @answers[key] = @answer
        end
      end
    end
    session[:answers] = params[:answers].to_unsafe_h
  end

  def save
    if @generic_page.expired?
      @message = I18n.t("execution.MAT_EXE_MUL_ERROREXECUTEMULTIPLEFIB_ALREADYPASSEDENDTIME_html", :param0 => I18n.l(@generic_page.end_time))
      render "error"
      return
    end

    @latest_score = @generic_page.latest_score(current_user.id)
    if @latest_score && @generic_page.max_count <= @latest_score.answer_count
      redirect_to :action => :show, :id => @generic_page
      return
    end

    if session[:answers].blank?
      @answers = params[:answers]
      tmpFlg = true
    else
      @answers = session[:answers]
      tmpFlg = false
    end

    @notExaminationFlg = 0

    ## テストが選択式の設問のみで構成されているかどうかチェック
    @question_composition_cd = @generic_page.get_question_composition

    ## 選択式の設問を採点し、合計得点(素点)を取得する(DBにはまだ登録しない)
		@total_score, user_answers = grade_multiple(@answers)
		## 配点合計を取得
		@totalAllotPoint = @generic_page.get_total_point

		if tmpFlg
			## DBに登録する
			begin
				save_answers(user_answers, @totalAllotPoint, @question_composition_cd, tmpFlg)
				message = I18n.t("execution.COMMONMATERIALSEXECUTION_TEMP_SAVE_SUCCESS")
			rescue => e
        logger.error e.backtrace.join("\n")
        message = I18n.t("execution.COMMONMATERIALSEXECUTION_TEMP_SAVE_FAILUER")
			end
      session[:answers] = nil
			## messageに保存結果を設定し実施画面に戻る
			redirect_to compound_path(@generic_page), :notice => message
      return
		end

		## 設問が選択式のみでない時
		if @question_composition_cd == Settings.QUESTIONCOMPOSITIONCD_COMPOUND || @question_composition_cd == Settings.QUESTIONCOMPOSITIONCD_ESSAYONLY

			## 自己採点ナシの時
			if @generic_page.self_flag == Settings.GENERICPAGE_SELFFLG_NONE
				## DBに登録する
				save_answers(user_answers, @totalAllotPoint, @question_composition_cd, tmpFlg)

        session[:answers] = nil
				## →finishCompound.jspへ
				redirect_to :action => :finish, :id => @generic_page
        return

				## 自己採点アリの時
			elsif @generic_page.self_flag == Settings.GENERICPAGE_SELFFLG_SELF ||
					@generic_page.self_flag == Settings.GENERICPAGE_SELFFLG_MUTUAL ||
					@generic_page.self_flag == Settings.GENERICPAGE_SELFFLG_MUTUAL2

				## DBに登録する
        save_answers(user_answers, @totalAllotPoint, @question_composition_cd, tmpFlg)

        ## 自己採点パスワードがない時
				if @generic_page.self_pass.blank? || session[:mark_pass_flag]
          redirect_to :action => :self_mark, :id => @generic_page
          return

          ## 自己採点パスワードがある時
				else
          redirect_to :action => :mark_password, :id => @generic_page
          return
				end
			end

			## 設問が選択式のみの時
		elsif @question_composition_cd == Settings.QUESTIONCOMPOSITIONCD_MULTIPLEONLY

			## DBに登録する
      save_answers(user_answers, @totalAllotPoint, @question_composition_cd, tmpFlg)

			## →gradeCompound.jspへ
      redirect_to :action => :mark, :id => @generic_page
      return
    end

    session[:answers] = nil
    redirect_to :action => :finish, :id => @generic_page

  rescue => e
    logger.error e.backtrace.join("\n")
    flash.now[:notice] = e.message
    render :show
  end

  def mark_password
    @execution_count = get_execution_count(@generic_page, false)

    if params[:self_pass].nil?
    else
      if params[:self_pass] != @generic_page.self_pass
        @message = I18n.t("execution.COMMONMATERIALSEXECUTION_GRADEPASSWORDCHECK2")
        return
      else
        session[:mark_pass_flag] = true
        redirect_to :action => :self_mark, :id => @generic_page
      end
    end
  end

  def self_mark
    if !@generic_page.self_pass.blank? && !session[:mark_pass_flag]
      @execution_count = get_execution_count(@generic_page, false)
      render "mark_password"
      return
    end

    ## テストが選択式の設問のみで構成されているかどうかチェック
    @question_composition_cd = @generic_page.get_question_composition

		if current_user.student?
      ## 最新の解答結果を取得
      @latest_score = @generic_page.latest_score(current_user.id)
      ## 解答取得
      @answers = get_answers(@generic_page, @latest_score.answer_count)
    else
      begin
        unless session[:answers].blank?
          @latest_score, @answers = generate_answers(session[:answers])
        else
          raise
        end
      rescue
        session[:answers] = nil
        redirect_to :action => :show, :id => @generic_page
      end
		end


    full_point = 0
		@multiple_score = 0
    @total_score = 0

		@generic_page.parent_questions.each do |parent|
			parent.questions.each do |question|
        full_point += question.score

        if question.pattern_cd == Settings.QUESTION_PATTERNCD_CHECK
          answerd = @answers[question.id.to_s] if @answers[question.id.to_s]
					@multiple_score += answerd[0]['score'] if answerd && !answerd[0]['score'].blank?
				elsif question.pattern_cd != Settings.QUESTION_PATTERNCD_ESSAY
					answerd = @answers[question.id.to_s] if @answers[question.id.to_s]
					@multiple_score += answerd['score'] if answerd && !answerd['score'].blank?
        else
          answerd = @answers[question.id.to_s]
          @total_score += answerd['score'] if answerd && !answerd['score'].blank?
				end
			end
		end

    @total_score = @total_score + @multiple_score
    @total_score_per_hundred = @total_score == 0 ? 0 : (@total_score * 100 / full_point).round
  end

  def update_self_score
    @latest_score = @generic_page.latest_score(current_user.id)

    if current_user.student?
      ActiveRecord::Base.transaction do
        full_point = 0
        @multiple_score = 0
        @total_score = 0

        @generic_page.parent_questions.each do |parent|
          parent.questions.each do |question|
            full_point += question.score

            if question.pattern_cd != Settings.QUESTION_PATTERNCD_ESSAY
              answerd = question.answers.where(:user_id => current_user.id, :answer_count => @latest_score.answer_count).first
              @multiple_score += answerd.score if answerd
            else
              self_score = params[:score][question.id.to_s].to_i
              answerd = question.answers.where(:user_id => current_user.id, :answer_count => @latest_score.answer_count).first
              answerd = answerd.presence || Answer.new(:user_id => current_user.id, :answer_count => @latest_score.answer_count)
              answerd.score = self_score
              answerd.self_score = self_score
              answerd.save!

              @total_score += self_score
            end
          end
        end

        @total_score = @total_score + @multiple_score
        if full_point == 0
          @total_score_per_hundred = 0
        else
          @total_score_per_hundred = (@total_score * 100 / full_point).round
        end

        @latest_score.total_raw_score = @total_score
        @latest_score.self_total_score = @total_score_per_hundred
        @latest_score.total_score = @total_score_per_hundred if @latest_score.total_score < 0
        @latest_score.effective_date = Time.zone.now
        @latest_score.save!
      end
    else
      session[:total_score] = params[:total_score_per_hundred]
    end

    redirect_to :action => :finish, :id => @generic_page

  rescue => e
    logger.error e.backtrace.join("\n")
    flash.now[:notice] = e.message
    render :self_mark
  end

  def mark
    ## テストが選択式の設問のみで構成されているかどうかチェック
    @question_composition_cd = @generic_page.get_question_composition

    @notExaminationFlg = 0

		## 選択式のため、採点済みにする
		@executeCompoundFinishCd = 2

    ## 最新の解答結果を取得
    @latest_score = @generic_page.latest_score(current_user.id)
    ## 解答取得
    if current_user.student?
      @answers = get_answers(@generic_page, @latest_score.answer_count)
    else
      begin
        unless session[:answers].blank?
          @latest_score, @answers = generate_answers(session[:answers])
        else
          raise
        end
      rescue
        session[:answers] = nil
        redirect_to :action => :show, :id => @generic_page
      end
    end
  end

  def finish
    if current_user.student?
      score = @generic_page.latest_score(current_user.id)
      @total_score = score.total_score
      @execution_count = score.answer_count
    else
      @total_score = session[:total_score]
      @execution_count = 1
      session[:total_score] = nil
    end
  end

  def clear_password
    session[:start_pass_flag] = nil
    session[:mark_pass_flag] = nil
    head :no_content
  end

  private
    def set_generic_page
      @generic_page = Compound.find_by(id: params[:id], type_cd: Settings.GENERICPAGE_TYPECD_COMPOUNDCODE)
    end

    def get_answers(generic_page, answer_count)
      answers = {}

      generic_page.parent_questions.each do |parent_question|
        parent_question.questions.eager_load(:answers).where(answers: {user_id: current_user.id, answer_count: answer_count}).each do |question|
          if question.pattern_cd == Settings.QUESTION_PATTERNCD_CHECK
            answers[question.id.to_s] = question.answers.map { |answer| answer }
          else
            answers[question.id.to_s] = question.answers.first
          end
        end
      end

      answers
    end

    def grade_multiple(answers)
  		## 合計得点
  		totalScore = 0
      user_answers = []

      @generic_page.parent_questions.each do |parent_question|
  			## 大問を取得
  			## 大問に登録された設問リストを取得
        parent_question.questions.each do |question|
  				## 複数選択の時
  				if question.pattern_cd == Settings.QUESTION_PATTERNCD_CHECK
  					## 設問に登録されている選択肢の中で正解であるものの数
            ## 選択肢が正解の時
  					allCorrectCounter = question.correct_values.count

  					## 選択された選択肢が正解している数
  					correctCounter = 0
  					## 選択された選択肢が不正解の数
  					incorrectCounter = 0

  					## 選択された選択肢の数だけ繰り返す
            if answers && answers[question.id.to_s]
    					answers[question.id.to_s].each do |answer|
    						isCorrect = false

    						## 採点する(設問に登録されている選択肢の数だけ繰り返す)
    						question.correct_values.each do |value|
    							## 選択された選択肢が正解の時
    							if value.id.to_s == answer["select_answer_id"]
    								correctCounter += 1
    								isCorrect = true
    								break
    							end
    						end

    						## 不正解の時
  							incorrectCounter += 1 if !isCorrect
    					end
            end

  					## この設問の配点
  					pluralScore = 0

  					## 完答コードが有効
  					if question.answer_in_full_cd == Settings.QUESTION_ANSWERINFULLCD_ANSWERINFULL
  						## 選択肢がすべて正解かつ余分に選択していない
  						if correctCounter > 0 && correctCounter == allCorrectCounter && incorrectCounter == 0
  							pluralScore = question.score
  							question.correct_flag = Settings.SELECT_SELECTCORRECTFLG_CORRECT
  						else
  							question.correct_flag = Settings.SELECT_SELECTCORRECTFLG_WRONG
  						end

  						## 完答コードが無効
  					#elsif question.answer_in_full_cd == Settings.QUESTION_ANSWERINFULLCD_NOTANSWERINFULL
            else
  						## 選択肢がすべて正解かつ余分に選択していない
  						if correctCounter > 0 && correctCounter == allCorrectCounter && incorrectCounter == 0
  							pluralScore = question.score
  							question.correct_flag = Settings.SELECT_SELECTCORRECTFLG_CORRECT

  							## 選択肢に間違いがあった時
  						else
  							## 得点を計算
  							## ◎(配点) * (正解した選択肢の数 - 不正解した選択肢の数) / (全ての正解の選択肢の数)
  							## 点 小数点以下切捨て
  							pluralScore = question.score * (correctCounter - incorrectCounter) / allCorrectCounter
  							if pluralScore < 0
  								pluralScore = 0
  							end

  							question.correct_flag = Settings.SELECT_SELECTCORRECTFLG_WRONG
  						end

  					end

  					## 合計得点に加算
  					totalScore += pluralScore

            if answers && answers[question.id.to_s]
              answers[question.id.to_s].each do |answer|
                unless answer["select_answer_id"].blank?
                  user_answer = Answer.new(:question_id => question.id, :user_id => current_user.id)
                  user_answer.select_answer_id = answer["select_answer_id"]
        					user_answer.score = pluralScore
        					user_answer.self_score = pluralScore
                  user_answers << user_answer
                end
              end
            end

            ## 記述の時
  				elsif question.pattern_cd == Settings.QUESTION_PATTERNCD_ESSAY
            user_answer = Answer.new(:question_id => question.id, :user_id => current_user.id)
            user_answer.select_answer_id = 0
            user_answer.text_answer = answers[question.id.to_s]["text_answer"]
            user_answer.score = 0
            user_answer.self_score = 0
            user_answers << user_answer

  					## 単一選択の時
  				else
  					## 選択された選択肢のオブジェクト
            unless answers[question.id.to_s]["select_answer_id"].blank?
    					user_answer = Answer.new(:question_id => question.id, :user_id => current_user.id)
              user_answer.select_answer_id = answers[question.id.to_s]["select_answer_id"]
    					## 採点する
    					user_answer.score = 0
              ##解答が選択されている場合のみ以下の処理を行う
              if answers[question.id.to_s]["select_answer_id"]
                question.correct_values.each do |value|
                  ## 選択した選択肢が正解なら正解フラグを立てる
                  if value.id.to_s == answers[question.id.to_s]["select_answer_id"]
                    totalScore += question.score
                    user_answer.score = question.score
                    user_answer.self_score = question.score
                    break
                  end
                end
              end

              user_answers << user_answer
            end
  				end
  			end

  		end

  		return [totalScore, user_answers]
    end

    def save_answers(answers, totalAllotPoint, question_composition_cd, tmp_flag)
  		## 選択式の設問の合計点数
  		multipleScore = 0
      questions = []
  		## 記述式の設問の自己採点の合計
  		selfScore = 0
  		## 合計点数(素点)
  		totalScore = 0
  		## 合計点数(100点換算)
  		totalScorePerHundred = 0
  		## 自己採点の合計点数
  		selfTotalScorePerHundred = 0

      update_date = ""

  		## 複合式テストに解答した回数を取得
      latest_score = @generic_page.latest_score(current_user.id)
      if latest_score
        if latest_score.total_score == Settings.ANSWERSCORE_TMP_SAVED_SCORE
          answer_count = latest_score.answer_count
        else
          answer_count = latest_score.answer_count + 1
        end
      else
        answer_count = 1
      end

      ActiveRecord::Base.transaction do
        target = []
        if latest_score
          ## 回答した受験回数のテスト結果が存在する場合は既存回答を削除する
          Answer.where(answer_score_id: latest_score.id).each do |answer|
            answer.destroy_historty(answer_count)
            answer.delete
          end
        end

    		date = Time.zone.now
        answers.each do |answer|
  				## 複数選択の時
  				if answer.question.pattern_cd == Settings.QUESTION_PATTERNCD_CHECK
            unless questions.include?(answer.question.id)
    					multipleScore += answer.score.to_i
              questions << answer.question.id
            end

  					## 単一選択の時
  				elsif answer.question.pattern_cd != Settings.QUESTION_PATTERNCD_ESSAY
            multipleScore += answer.score.to_i

  					## 記述の時
  				else
  					selfScore += answer.self_score unless answer.self_score.blank?
  			  end

          ## 学生の時はDBに登録する
          if current_user.student? && !answer.select_answer_id.blank?
            answer.answer_count = answer_count
          end
    		end

    		## 合計得点(素点)を計算
    		totalScore = multipleScore + selfScore
    		## 合計得点(100点換算)を計算
    		if totalAllotPoint == 0
    		  totalScorePerHundred = 0
    		else
      		totalScorePerHundred = (totalScore * 100 / totalAllotPoint).round
    		end

    		## 合否コード
    		passCd = Settings.ANSWERSCORE_PASSCD_UNSUBMITTING;

    		## 条件文変更,passCd=BaseDao.DEFAULT_ARGUMENT_INTを追加 2007/08/31 t-yano
    		## 設問が複合or記述のみの時
    		if question_composition_cd == Settings.QUESTIONCOMPOSITIONCD_COMPOUND || question_composition_cd == Settings.QUESTIONCOMPOSITIONCD_ESSAYONLY
    			## 自己採点ナシの時
    			if @generic_page.self_flag == Settings.GENERICPAGE_SELFFLG_NONE
    				@totalScore = totalScore
    				@totalScorePerHundred = Settings.DEFAULT_ARGUMENT_INT
    				## selfTotalScoreを選択式の合計得点として使い(仮：管理で表示するため？)、totalScoreに負の数（担任は未採点の意味）
    				selfTotalScorePerHundred = multipleScore
    				totalScore = Settings.DEFAULT_ARGUMENT_INT
    				totalScorePerHundred = Settings.DEFAULT_ARGUMENT_INT
    				passCd = Settings.DEFAULT_ARGUMENT_INT

    				## 自己採点アリの時
    			elsif @generic_page.self_flag == Settings.GENERICPAGE_SELFFLG_SELF ||
    					@generic_page.self_flag == Settings.GENERICPAGE_SELFFLG_MUTUAL ||
    					@generic_page.self_flag == Settings.GENERICPAGE_SELFFLG_MUTUAL2
    				@totalScore = totalScore
    				@totalScorePerHundred = totalScorePerHundred
    				## selfTotalScoreに負の数(※自己採点を途中でやめた時の対策)、totalScoreに負の数（担任は未採点の意味）
    				selfTotalScorePerHundred = Settings.DEFAULT_ARGUMENT_INT
    				totalScore = Settings.DEFAULT_ARGUMENT_INT
    				totalScorePerHundred = Settings.DEFAULT_ARGUMENT_INT
    				passCd = Settings.DEFAULT_ARGUMENT_INT
    			end

    			## 設問が選択式のみの時
    		elsif question_composition_cd == Settings.QUESTIONCOMPOSITIONCD_MULTIPLEONLY
    			## selfTotalScoreとtotalScoreを同じにしとく(とりあえず？)
    			selfTotalScorePerHundred = totalScorePerHundred

    			## 合格点以上なら合格
    			if @generic_page.pass_grade <= totalScorePerHundred
    				passCd = Settings.ANSWERSCORE_PASSCD_SUBMITTED
    				## 合格点より低い時は不合格
    			elsif @generic_page.pass_grade > totalScorePerHundred
    				passCd = Settings.ANSWERSCORE_PASSCD_UNSUBMITTING
    			end
    		end

  			if tmp_flag
  				totalScorePerHundred = Settings.ANSWERSCORE_TMP_SAVED_SCORE
  				selfTotalScorePerHundred = Settings.ANSWERSCORE_TMP_SAVED_SCORE
  				passCd = Settings.ANSWERSCORE_TMP_SAVED_SCORE
  			end
  			## テスト結果(answerScore)をDBに登録
  			## 回答した受験回数のテスト結果が存在する場合は上書きする
  			if latest_score.blank?
          ##素点合計をset
          latest_score = AnswerScore.new
          latest_score.user_id = current_user.id
      		latest_score.page_id = @generic_page.id
  			end

        latest_score.answer_count = answer_count

        ##素点合計をset
				latest_score.pass_cd = passCd
				latest_score.self_total_score = selfTotalScorePerHundred
				latest_score.total_score = totalScorePerHundred
        latest_score.total_raw_score = totalScore
        latest_score.effective_date = Time.zone.now if totalScorePerHundred > Settings.ANSWERSCORE_TMP_SAVED_SCORE

        ## 学生の時はDBに登録する
        if current_user.student?
          latest_score.save!

          answers.each do |answer|
            answer.answer_score_id = latest_score.id
            answer.save!(validate: !tmp_flag)
          end
    		end
      end
    end

    def generate_answers(answers)
      answer_score = AnswerScore.new
      mark_answers = Hash.new

      total_score, user_answers = grade_multiple(answers)

      answer_score.total_score = total_score
      answer_score.answer_count = 1

      user_answers.each do |answer|
        if answer.question.pattern_cd == Settings.QUESTION_PATTERNCD_CHECK
          mark_answers[answer.question_id.to_s] = [] unless mark_answers[answer.question_id.to_s]
          mark_answers[answer.question_id.to_s] << answer
        else
          mark_answers[answer.question_id.to_s] = answer
        end
      end

      return [answer_score, mark_answers]
    end

    def get_execution_count(generic_page, is_increment = true)
      execution_count = 1

      ## 最新の解答結果を取得
      latest_score = generic_page.latest_score(current_user.id)
      if latest_score.present?
        if latest_score.total_score == Settings.ANSWERSCORE_TMP_SAVED_SCORE
          execution_count = latest_score.answer_count
        elsif is_increment
          execution_count = latest_score.answer_count + 1
        else
          execution_count = latest_score.answer_count
        end
      end

      execution_count
    end
end
