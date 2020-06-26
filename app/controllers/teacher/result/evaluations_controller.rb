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
require 'nkf'

class Teacher::Result::EvaluationsController < ApplicationController
  before_action :require_assigned, only: [:show,
    :result, :save, :save_content, :outputcsv, :upload, :upload_confirm, :upload_error, :upload_save, :upload_result, :send_mail]
  before_action :set_courses, only: [:index]
  before_action :set_course, only: [:show]
  before_action :set_generic_page, only: [:result, :save, :save_content, :outputcsv, :upload, :upload_confirm, :upload_error, :upload_save, :upload_result, :send_mail]

  def result
    @answer_scores = get_answer_scores(@generic_page)
  end

  def save
    ActiveRecord::Base.transaction do
      ## 採点を登録する
      @generic_page.course.enrolled_users.each do |user|
        answer_score = @generic_page.latest_score(user.id)
        unless answer_score
          answer_score = AnswerScore.new(:page_id => @generic_page.id, :user_id => user.id,
            :total_score => Settings.DEFAULT_ARGUMENT_INT, :pass_cd => Settings.DEFAULT_ARGUMENT_INT)
        end
        assignment_essay_comment = answer_score.assignment_essay_comments.first
        assignment_essay_comment = AssignmentEssayComment.new unless assignment_essay_comment

        ## 既存データありの場合は登録しない
        next if answer_score.new_record? && params[:mail_flag].blank? && params[:assignment_essay_score][user.id.to_s].blank? && params[:memo][user.id.to_s].blank?

        ## 評価
        answer_score.assignment_essay_score = params[:assignment_essay_score][user.id.to_s] if params[:assignment_essay_score][user.id.to_s]
        ## コメント
        assignment_essay_comment.memo = params[:memo][user.id.to_s] if params[:memo][user.id.to_s]

        ## メール送信
        if params[:mail_flag]
          if params[:mail_flag][user.id.to_s] && assignment_essay_comment.mail_flag == Settings.ASSIGNMENTESSAYMAILCOMMENT_MAILFLG_OFF
            ## メール送信フラグを送信予定にする
            assignment_essay_comment.mail_flag = Settings.ASSIGNMENTESSAYMAILCOMMENT_MAILFLG_ON

          elsif params[:mail_flag][user.id.to_s] && assignment_essay_comment.mail_flag == Settings.ASSIGNMENTESSAYMAILCOMMENT_MAILFLG_SENDED
            ## メール送信フラグを再送信予定にする
            assignment_essay_comment.mail_flag = Settings.ASSIGNMENTESSAYMAILCOMMENT_MAILFLG_SENDED_ON

          elsif params[:mail_flag][user.id.to_s] && assignment_essay_comment.mail_flag == Settings.ASSIGNMENTESSAYMAILCOMMENT_MAILFLG_RESENDED
            ## メール送信フラグを再送信予定にする
            assignment_essay_comment.mail_flag = Settings.ASSIGNMENTESSAYMAILCOMMENT_MAILFLG_RESENDED_ON

          elsif params[:mail_flag][user.id.to_s] && assignment_essay_comment.mail_flag == Settings.ASSIGNMENTESSAYMAILCOMMENT_MAILFLG_ON
            ## メール送信フラグをクリアにする
            assignment_essay_comment.mail_flag = Settings.ASSIGNMENTESSAYMAILCOMMENT_MAILFLG_OFF

          elsif params[:mail_flag][user.id.to_s] && assignment_essay_comment.mail_flag == Settings.ASSIGNMENTESSAYMAILCOMMENT_MAILFLG_SENDED_ON
            ## メール送信フラグを送信済みにする
            assignment_essay_comment.mail_flag = Settings.ASSIGNMENTESSAYMAILCOMMENT_MAILFLG_SENDED

          elsif params[:mail_flag][user.id.to_s] && assignment_essay_comment.mail_flag == Settings.ASSIGNMENTESSAYMAILCOMMENT_MAILFLG_RESENDED_ON
            ## メール送信フラグを再送信済みにする
            assignment_essay_comment.mail_flag = Settings.ASSIGNMENTESSAYMAILCOMMENT_MAILFLG_RESENDED
          end
        end

        ## 採点結果を更新する
        answer_score.save!
        assignment_essay_comment.answer_score_id = answer_score.id if assignment_essay_comment.new_record?
        assignment_essay_comment.save!
      end
    end

    redirect_to :action => :result, :id => @generic_page

  rescue => e
    logger.error e.backtrace.join("\n")
    flash.now[:notice] = e.message
    @answer_scores = get_answer_scores(@generic_page)
    render action: :result
  end

  def save_content
    @generic_page.content = params[:mail_content]
    @generic_page.save
    redirect_to :action => :result, :id => @generic_page
  end

  def outputcsv
    result

    bom = %w(EF BB BF).map { |e| e.hex.chr }.join
    csv_data = CSV.generate(bom) do |csv|
      csv << ["#{I18n.t('materials_administration.MAT_ADM_CSV_HEADER1')}"]

      line = []
      line << I18n.t('materials_administration.MAT_ADM_CSV_HEADER2')
      line << @generic_page.course.id
      line << I18n.t('materials_administration.MAT_ADM_CSV_HEADER3')
      line << params[:id]
      csv << line

      line = []
      line << I18n.t('materials_administration.MAT_ADM_CSV_HEADER4')
      line << @generic_page.course.course_name
      csv << line

      line = []
      line << I18n.t('materials_administration.MAT_ADM_CSV_HEADER5')
      line << @generic_page.generic_page_title
      csv << line

      csv << []

      csv << [I18n.t('materials_administration.MAT_ADM_CSV_HEADER_EXPLANATION1')]
      csv << [I18n.t('materials_administration.MAT_ADM_CSV_HEADER_EXPLANATION2')]
      csv << [I18n.t('materials_administration.MAT_ADM_CSV_HEADER_EXPLANATION3')]
      csv << [I18n.t('materials_administration.MAT_ADM_CSV_HEADER_EXPLANATION4')]
      csv << [I18n.t('materials_administration.MAT_ADM_CSV_HEADER_EXPLANATION5')]
      csv << [I18n.t('materials_administration.MAT_ADM_CSV_HEADER_EXPLANATION6')]
      csv << [I18n.t('materials_administration.MAT_ADM_CSV_HEADER_EXPLANATION7')]
      csv << [I18n.t('materials_administration.MAT_ADM_CSV_HEADER_EXPLANATION8')]
      csv << [I18n.t('materials_administration.MAT_ADM_CSV_HEADER_EXPLANATION9')]
      csv << [I18n.t('materials_administration.MAT_ADM_CSV_HEADER_EXPLANATION10')]
      csv << [I18n.t('materials_administration.MAT_ADM_CSV_HEADER_EXPLANATION11')]
      csv << [I18n.t('materials_administration.MAT_ADM_CSV_HEADER_EXPLANATION12')]

      csv << []

      line = []
      line << I18n.t('materials_administration.MAT_ADM_CSV_HEADER6')
      line << I18n.t('materials_administration.MAT_ADM_CSV_HEADER7')
      line << I18n.t('materials_administration.MAT_ADM_CSV_HEADER8')
      line << I18n.t('materials_administration.MAT_ADM_CSV_HEADER9')
      line << I18n.t('materials_administration.MAT_ADM_CSV_HEADER10')
      line << I18n.t('materials_administration.MAT_ADM_CSV_HEADER11')
      csv << line

      # ユーザ一覧
      @generic_page.course.enrolled_users.each do |user|
        line = []
        line << CsvEvaluation::BUS_SER_IMP_IMP_IDENTIFICATIONCD
        line << user.id
        line << user.get_name_no_prefix + user.user_name

        if @answer_scores[user.id] && @answer_scores[user.id].latest_comment
          if @answer_scores[user.id].latest_comment.mail_flag == Settings.ASSIGNMENTESSAYMAILCOMMENT_MAILFLG_ON ||
             @answer_scores[user.id].latest_comment.mail_flag == Settings.ASSIGNMENTESSAYMAILCOMMENT_MAILFLG_SENDED_ON ||
             @answer_scores[user.id].latest_comment.mail_flag == Settings.ASSIGNMENTESSAYMAILCOMMENT_MAILFLG_RESENDED_ON
            line << Settings.ASSIGNMENTESSAYMAILCOMMENT_MAILFLG_ON
          else
            line << Settings.ASSIGNMENTESSAYMAILCOMMENT_MAILFLG_OFF
          end
          line << @answer_scores[user.id].assignment_essay_score
          line << @answer_scores[user.id].latest_comment.memo
        else
          line << Settings.ASSIGNMENTESSAYMAILCOMMENT_MAILFLG_OFF
          line << ""
          line << ""
        end

        csv << line
      end
    end

    send_data csv_data, filename: "evaluationlistInput.csv"
  end

  def upload_confirm
    @answer_scores = get_answer_scores(@generic_page)

    begin
      @csv = CsvEvaluation.new(csv_params)

      if @csv.valid?
        if @csv.csv?
          FileUtils.mkdir_p(@csv.tmp_dir)
          File.open(@csv.temp_file, 'w+b') do |fp|
            fp.write @csv.file.read
          end

          # 解析結果
          @results = {"all" => 0, "error" => 0, "status_error" => 0, 0 => 0, 1 => 0, 2 => 0, 3 => 0}
          @success = []

          users = {}
          @generic_page.course.enrolled_users.each.with_index(1) do |user, user_index|
            users.store(user.id.to_s, user)
          end

          @csv_evaluations = evaluation_csv_to_hash(@csv.temp_file, users)

          if @csv.file.size == 0
            @messages = I18n.t('registerList.PRI_REG_RESULTLIST_NOFILESIZEERROR')
          elsif @csv_evaluations.count > CsvEvaluation::BUS_UTI_CSV_LIMITCOUNT
            @messages = I18n.t('registerList.PRI_REG_IMPORTRESUL_LIMITOVERERROR_html')
          end

          session[:csv_evaluation] = @csv.temp_file
        else
          @messages = I18n.t('registerList.PRI_REG_RESULTLIST_NOCSVERROR')
        end
      else
        @messages = I18n.t('registerList.PRI_REG_RESULTLIST_NOSELECTERROR')
        render :user_result
      end

    rescue => e
      logger.error e.backtrace.join("\n")
      @messages = I18n.t('registerList.PRI_REG_RESULTLIST_NOSELECTERROR')
    end
  end

  def upload_save
    @update_count = 0
    ActiveRecord::Base.transaction do
      ## 採点を登録する
      @generic_page.course.enrolled_users.each do |user|
        answer_score = @generic_page.latest_score(user.id)
        unless answer_score
          answer_score = AnswerScore.new(:page_id => @generic_page.id, :user_id => user.id,
            :total_score => Settings.DEFAULT_ARGUMENT_INT, :pass_cd => Settings.DEFAULT_ARGUMENT_INT)
        end
        assignment_essay_comment = answer_score.assignment_essay_comments.first
        assignment_essay_comment = AssignmentEssayComment.new unless assignment_essay_comment

        ## 既存データありの場合は登録しない
        if params[:overwrite] == "2"
          next unless answer_score.new_record?
#          next if answer_score.new_record? && params[:mail_flag].blank? && params[:assignment_essay_score][user.id.to_s].blank? && params[:memo][user.id.to_s].blank?
        end

        next if params[:assignment_essay_score][user.id.to_s].blank?
        next if params[:memo][user.id.to_s].length > 4096

        ## 評価
        answer_score.assignment_essay_score = params[:assignment_essay_score][user.id.to_s]
        ## コメント
        assignment_essay_comment.memo = params[:memo][user.id.to_s] if params[:memo][user.id.to_s]

        ## メール送信
        if params[:mail_flag] && params[:mail_flag][user.id.to_s]
          ## メール送信フラグを送信予定にする
          assignment_essay_comment.mail_flag = Settings.ASSIGNMENTESSAYMAILCOMMENT_MAILFLG_ON
        else
          ## メール送信フラグをクリアにする
          assignment_essay_comment.mail_flag = Settings.ASSIGNMENTESSAYMAILCOMMENT_MAILFLG_OFF
        end

        ## 採点結果を更新する
        answer_score.save!
        assignment_essay_comment.answer_score_id = answer_score.id if assignment_essay_comment.new_record?
        assignment_essay_comment.save!
        @update_count += 1
      end

      session[:overwrite] = params[:overwrite]
    end

    render :upload_result
  rescue => e
    logger.error e.backtrace.join("\n")
    flash.now[:notice] = e.message
    @answer_scores = get_answer_scores(@generic_page)
    render action: :result

  end

  def upload_result
    @answer_scores = get_answer_scores(@generic_page)
    upload_file = "#{session[:csv_evaluation]}"

    # 解析結果
    @results = {"all" => 0, "error" => 0, "status_error" => 0, 0 => 0, 1 => 0, 2 => 0, 3 => 0}
    @success = []

    users = {}
    @generic_page.course.enrolled_users.each.with_index(1) do |user, user_index|
      users.store(user.id.to_s, user)
    end

    @csv_evaluations = evaluation_csv_to_hash(upload_file, users)
    @csv_evaluations.each.with_index(1) do |csv_evaluation, index|
      answer_score = @generic_page.latest_score(csv_evaluation["usr_id"])
      unless @errors[index]
        @errors[index] = I18n.t('registerList.PRI_REG_RESULT_REGISTERED')
        if answer_score
          if session[:overwrite] == "2"
            @errors[index] = I18n.t('registerList.PRI_REG_RESULT_NOT_REGISTERED_BY_OVERRIDE')
          end
        end
      end
    end

    render :upload_error
  end

  def upload_error
    @answer_scores = get_answer_scores(@generic_page)
    upload_file = "#{session[:csv_evaluation]}"

    # 解析結果
    @results = {"all" => 0, "error" => 0, "status_error" => 0, 0 => 0, 1 => 0, 2 => 0, 3 => 0}
    @success = []

    users = {}
    @generic_page.course.enrolled_users.each.with_index(1) do |user, user_index|
      users.store(user.id.to_s, user)
    end

    @csv_evaluations = evaluation_csv_to_hash(upload_file, users)
  end

  def send_mail
    if !params[:mail_flag] || params[:mail_flag].to_unsafe_h.count == 0
      raise I18n.t("materials_administration.MAT_ADM_CSV_MAILNOUSER")
    end

    if @generic_page.content.length == 0
      raise I18n.t("materials_administration.MAT_ADM_CSV_MAILNOCONTENT")
    end

    ActiveRecord::Base.transaction do
      params[:mail_flag].to_unsafe_h.keys.each do |user|
        user = User.find(user)
        answer_score = @generic_page.latest_score(user.id)
        if answer_score && answer_score.latest_comment
          latest_comment = answer_score.latest_comment

          if latest_comment.mail_flag == Settings.ASSIGNMENTESSAYMAILCOMMENT_MAILFLG_ON ||
             latest_comment.mail_flag == Settings.ASSIGNMENTESSAYMAILCOMMENT_MAILFLG_SENDED_ON ||
             latest_comment.mail_flag == Settings.ASSIGNMENTESSAYMAILCOMMENT_MAILFLG_RESENDED_ON
            EvaluationMailer.send_mail(@generic_page, latest_comment, user).deliver_now

            if latest_comment.mail_flag == Settings.ASSIGNMENTESSAYMAILCOMMENT_MAILFLG_ON
              latest_comment.mail_flag = Settings.ASSIGNMENTESSAYMAILCOMMENT_MAILFLG_SENDED
            else
              latest_comment.mail_flag = Settings.ASSIGNMENTESSAYMAILCOMMENT_MAILFLG_RESENDED
            end
            latest_comment.mailsend_date = Time.zone.now
            latest_comment.save!
          end
        end
      end
    end

    redirect_to teacher_result_result_evaluation_path(@generic_page)

  rescue => e
    logger.error e.backtrace.join("\n")
    redirect_to teacher_result_result_evaluation_path(@generic_page), :notice => e.message
  end

  def evaluation_csv_to_hash(upload_file, users)
    lineno = 0
    index = 0
    evaluations = []
    accounts = []
    @errors = {}

    csv_data = CSV.parse(File.new(upload_file)) do |csv_row|
      case lineno
      when 1
        # 科目IDが違う場合
        if csv_row[1] != @generic_page.course.id.to_s
          @messages = I18n.t('registerList.PRI_REG_IMPORTRESUL_SUBJECTIDRERROR')
          break
        end

        # タイトルIDが違う場合
        if csv_row[3] != @generic_page.id.to_s
          @messages = I18n.t('registerList.PRI_REG_IMPORTRESUL_TITLEIDRERROR')
          break
        end
      when 2
        # 科目名が違う場合
        if csv_row[1] != @generic_page.course.course_name
          @messages = I18n.t('registerList.PRI_REG_IMPORTRESUL_SUBJECTNAMEERROR')
          break
        end
      when 3
        # 評価記入リストタイトルが違う場合
        if csv_row[1] != @generic_page.generic_page_title
          @messages = I18n.t('registerList.PRI_REG_IMPORTRESUL_EVALUATIONLISTTITLEERROR')
          break
        end
      end

      if lineno >= (CsvEvaluation::CSV_DATA_START_LINENO + CsvEvaluation::HEADER_LINENO)
        line = {}
        line["identification_cd"] = csv_row[0]
        line["usr_id"] = csv_row[1]
        line["usr_name"] = csv_row[2]
        line["mailsend"] = csv_row[3]
        line["score"] = csv_row[4]
        line["comment"] = csv_row[5]
        index += 1
        evaluations << line

        if users[line["usr_id"]]
          user = users[line["usr_id"]]
          @results["all"] += 1
          if @answer_scores[user.id]
            status = "update"
          else
            status = ""
          end

          if line["score"].blank?
            @errors[index] = I18n.t('registerList.PRI_REG_RESULT_NOT_REGISTERED_BY_NOSCORE')
            next
          end
          if line["comment"] && line["comment"].length > 4096
            @errors[index] = I18n.t('registerList.PRI_REG_RESULTLIST_COLUMNCOUNTERROR')
            next
          end
          line["score"] = line["score"].slice(0, 10) if line["score"] && line["score"].length > 10
          success_user = {"user_id" => user.id, "user_name" => user.user_name, "mailsend" => line["mailsend"], "score" => line["score"], "comment" => line["comment"], "status" => status}
          @success << success_user
        else
          @errors[index] = I18n.t('registerList.PRI_REG_RESULTLIST_ACOUNTERROR')
          next
        end
      end

      lineno += 1
    end

    evaluations
  end

  private
    def set_generic_page
      @generic_page = GenericPage.find(params[:id])
    end

    def get_answer_scores(generic_page)
      scores = {}
      @generic_page.course.enrolled_users.each do |user|
        answer_score = generic_page.latest_score(user.id)
        scores[user.id] = answer_score
      end
      scores
    end

    def csv_params
      params.require(:upload).permit(:file)
    end
end
