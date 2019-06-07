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
require 'fileutils'
require 'kconv'

class Teacher::Result::EssaysController < ApplicationController
  include MaterialFileModule

  ANALYZER_EXCEL_PATH = "/download"
  ANALYZER_EXCEL_NAME = "analyzer.xls"

  before_action :set_courses, only: [:index]
  before_action :set_course, only: [:show, :download_report, :download_package]
  before_action :set_essay, only: [:result, :mark, :file, :return_file, :file_confirm,
    :save, :update_score, :outputcsv_assignmentessay, :outputcsv_scoresheet,
    :upload, :upload_confirm, :upload_register, :upload_error, :import_file,
    :report_upload, :report_upload_confirm, :import_report, :send_mail,
    :download_report, :download_package, :history, :comment, :upload_return_report,
    :confirm_return_report, :save_return_report, :return_report]
  before_action :set_user, only: [:report_upload_confirm, :import_report]

  def show
    session[:essay_search] = nil
    @essays = @course.essays.joins(:class_sessions)
  end

  def result
    delete_temporary_file

    if params[:search].blank?
      params[:search] = {}
      params[:search][:order1] = "0"
      params[:search][:status] = "-1"
    end
    session[:essay_search] = params[:search]

    if params[:search][:order1] == "0"
      if params[:search][:order2] == "1"
        order = "users.name_no_prefix DESC, users.user_name DESC, answer_scores.answer_count"
      else
        order = "users.name_no_prefix, users.user_name, answer_scores.answer_count"
      end
    else
      if params[:search][:order2] == "1"
        order = "answer_scores.answer_count, answer_scores.answer_count"
      else
        order = "answer_scores.answer_count DESC, answer_scores.answer_count"
      end
    end

    case params[:search][:status]
    when AssignmentEssay::STATUS_NOTPRESENT.to_s
      if params[:search][:order2] == "1"
        order = "users.name_no_prefix DESC, users.user_name DESC"
      else
        order = "users.name_no_prefix, users.user_name"
      end
      selected_users = User.joins(:enrollment_courses).
        where("course_enrollment_users.course_id = ?", @essay.course.id).
        order(order)

    when AssignmentEssay::STATUS_PRESENTED.to_s
      selected_users = User.joins(:answer_scores, :enrollment_courses).
        where("answer_scores.page_id = ? AND course_enrollment_users.course_id = ? AND answer_scores.total_score < 0",
          @essay.id, @essay.course.id).
        order(order)

    when AssignmentEssay::STATUS_GRADED_REPRESENT.to_s
      selected_users = User.joins(:answer_scores, :enrollment_courses).
        where("answer_scores.page_id = ? AND course_enrollment_users.course_id = ? AND answer_scores.pass_cd = ?",
          @essay.id, @essay.course.id, Settings.ANSWERSCORE_PASSCD_UNSUBMITTING).
        order(order)

    when AssignmentEssay::STATUS_GRADED_ACCEPTANCE.to_s
      selected_users = User.joins(:answer_scores, :enrollment_courses).
        where("answer_scores.page_id = ? AND course_enrollment_users.course_id = ? AND answer_scores.pass_cd = ?",
          @essay.id, @essay.course.id, Settings.ANSWERSCORE_PASSCD_SUBMITTED).
        order(order)

    else
      selected_users = User.joins(:course_enrollment_users).eager_load(:answer_scores).
        where(course_enrollment_users: {course_id: @essay.course.id}).
        order(order)
    end

    @scores = {}
    @users = []
    selected_users.each do |user|
      latest_score = @essay.latest_score(user.id)

      case params[:search][:status]
      when AssignmentEssay::STATUS_PRESENTED.to_s
        next if latest_score.nil? || latest_score.total_score >= 0
      when AssignmentEssay::STATUS_GRADED_REPRESENT.to_s
        next if latest_score.nil? || latest_score.pass_cd != Settings.ANSWERSCORE_PASSCD_UNSUBMITTING
      when AssignmentEssay::STATUS_GRADED_ACCEPTANCE.to_s
        next if latest_score.nil? || latest_score.total_score < 0 || latest_score.pass_cd != Settings.ANSWERSCORE_PASSCD_SUBMITTED
      when AssignmentEssay::STATUS_NOTPRESENT.to_s
        next unless latest_score.blank?
      end

      @users << user
      @scores[user.id] = latest_score if latest_score
    end

    if params[:search][:order1] == "2"
      if params[:search][:order2] == "1"
        @users.sort! do |a, b|
          if @scores[b.id].blank? && @scores[a.id].blank?
            0
          elsif @scores[b.id].blank? || @scores[b.id].assignment_essay_score.blank?
            -1
          elsif @scores[a.id].blank? || @scores[a.id].assignment_essay_score.blank?
            1
          elsif @scores[b.id].assignment_essay_score.to_i > @scores[a.id].assignment_essay_score.to_i
            1
          else
            -1
          end
        end
      else
        @users.sort! do |a, b|
          if @scores[b.id].blank? && @scores[a.id].blank?
            0
          elsif @scores[b.id].blank? || @scores[b.id].assignment_essay_score.blank?
            -1
          elsif @scores[a.id].blank? || @scores[a.id].assignment_essay_score.blank?
            1
          elsif @scores[b.id].assignment_essay_score.to_i < @scores[a.id].assignment_essay_score.to_i
            1
          else
            -1
          end
        end
      end
    end
  end

  def mark
    @user = User.find(params[:user])

    @answer_score = @essay.latest_score(@user.id)
    if @answer_score.nil?
      @answer_score = AnswerScore.new
      @answer_score.page_id = @essay.id
      @answer_score.user_id = @user.id
      @answer_score.answer_count = 1
      @answer_score.pass_cd = Settings.ANSWERSCORE_PASSCD_SUBMITTED
      @comment = AssignmentEssayComment.new(:answer_score_id => @answer_score.id, :mail_flag => 0)
    elsif @answer_score.assignment_essay_comments.count == 0
      @comment = AssignmentEssayComment.new(:answer_score_id => @answer_score.id, :mail_flag => 0)
    else
      @comment = @answer_score.latest_comment
    end

  end

  def save
    @comment = params[:answer_score][:assignment_essay_comments_attributes]
    ## ユーザを取得
    @user = User.find(params[:answer_score][:user_id])
    ## レポート結果を取得
    @answer_score = @essay.latest_score(@user.id)

    ActiveRecord::Base.transaction do
      if @answer_score.nil?
        @answer_score = AnswerScore.new(answer_score_params)
      else
        @answer_score.assign_attributes(answer_score_params)
      end
      @answer_score.total_score = (Settings.DEFAULT_ARGUMENT_INT).abs - 1
      @answer_score.save!(validate: false)
    end

    redirect_to :action => :result, :id => @essay

  rescue => e
    logger.error e.backtrace.join("\n")
    flash.now[:notice] = e.message
    @answer_score.comment_attributes = params[:answer_score][:comment_attributes]
    render action: :mark

  end

  def file
    score = AnswerScoreHistory.where(id: params[:score]).first

    if score && score.link_name
      file_path = score.get_file_path
      stat = File::stat(file_path)

      if score.file_name.blank?
        file_name = File.basename(score.link_name)
      else
        file_name = score.file_name
      end
      file_name = "#{File.basename(file_name, '.*')}_#{score.answer_count.to_s}#{File.extname(file_name)}"
      #file_name = ERB::Util.url_encode(file_name) if msie?

      type, is_inline = get_content_type(file_name)
      if is_inline
        send_file(file_path, filename: file_name, length: stat.size, type: type, disposition: :inline)
      else
        send_file(file_path, filename: file_name, length: stat.size, type: type, disposition: :attachment)
      end
    end
  end

  def return_file
    score = AnswerScoreHistory.where(id: params[:score]).first

    if score && score.latest_comment
      latest_comment = score.latest_comment
    end

    if latest_comment && latest_comment.processed_link_name
      file_path = latest_comment.get_file_path
      stat = File::stat(file_path)

      if latest_comment.processed_file_name.blank?
        file_name = File.basename(latest_comment.processed_link_name)
      else
        file_name = latest_comment.processed_file_name
      end
      file_name = "#{File.basename(file_name, '.*')}_#{score.answer_count.to_s}#{File.extname(file_name)}"
      #file_name = ERB::Util.url_encode(file_name) if msie?

      type, is_inline = get_content_type(file_name)
      if is_inline
        send_file(file_path, filename: file_name, length: stat.size, type: type, disposition: :inline)
      else
        send_file(file_path, filename: file_name, length: stat.size, type: type, disposition: :attachment)
      end
    end
  end

  def file_confirm
    @user = User.find(params[:user])
    @score = @essay.latest_score(@user.id)
  end

  def update_score
    if params[:score].blank? || params[:score].to_i.to_s != params[:score].to_s
      flash.now[:notice] = I18n.t("materials_administration.COMMONMATERIALSADMINISTRATION_JAVASCRIPT6")
      params[:search] = session[:essay_search]
      result
      render action: :result
      return
    end

    ## 学生リストを取得
    @users = User.joins(:course_enrollment_users, :answer_scores).
      where("course_enrollment_users.course_id = ? AND answer_scores.total_score < 0", @essay.course_id)

    ActiveRecord::Base.transaction do
      ## 「提出済（未採点）」の学生を一括採点する
      @users.each do |user|
        answer_score = @essay.latest_score(user.id)
        ##「提出済（未採点）」のみ
        next if answer_score.nil? || answer_score.total_score >= 0

        ## レポートの採点結果を更新する
        answer_score.assignment_essay_score = params[:score]
        answer_score.total_score = (Settings.DEFAULT_ARGUMENT_INT).abs - 1
        answer_score.pass_cd = Settings.ANSWERSCORE_PASSCD_SUBMITTED
        answer_score.save!(validate: false)

        comment = answer_score.latest_comment
        comment = AssignmentEssayComment.new(:answer_score_id => answer_score.id) if comment
        comment.memo = ""
        comment.mail_flag = Settings.ANNOUNCEMENT_MAILFLG_UNTRANSMISSION
        comment.save!
      end
    end

    redirect_to :action => :result, :id => @essay

  rescue => e
    logger.error e.backtrace.join("\n")
    flash.now[:notice] = e.message
    params[:search] = session[:essay_search]
    result
    render action: :result
  end

  def outputcsv_scoresheet
    result

    send_data create_scoresheet, filename: "#{I18n.t('materials_administration.MAT_ADM_ASS_ASSIGNMENTESSAYTOTALRESULT_DOWNLOADSCORECARDCSVFILENAME')}.csv"
  end

  def outputcsv_assignmentessay
    result

    bom = %w(EF BB BF).map { |e| e.hex.chr }.join
    csv_data = CSV.generate(bom) do |csv|
      csv << ["#{I18n.t('materials_administration.MAT_ADM_COM_ADMINISTRATECOMPOUND_CSVCOLUMN1')}#{@essay.course.course_name}"]
      csv << ["#{I18n.t('materials_administration.MAT_ADM_COM_ADMINISTRATECOMPOUND_CSVCOLUMN2')}#{@essay.generic_page_title}"]

      line = []
      line << I18n.t('common.COMMON_ACCOUNT')
      line << I18n.t('common.COMMON_TARGETNAME')
      line << I18n.t('materials_administration.COMMONMATERIALSADMINISTRATION_PRESENTATIONCOUNT')
      line << I18n.t('materials_administration.COMMONMATERIALSADMINISTRATION_STATUS')
      line << I18n.t('materials_administration.COMMONMATERIALSADMINISTRATION_MARK1')
      csv << line

      @users.each.with_index(1) do |user, index|
        line = []
        line << user.account
        line << user.get_name_no_prefix + user.user_name

        if @scores[user.id]
          line << @scores[user.id].answer_count
        else
          line << 1
        end

        case @essay.essay_status(user.id)
        when 0
          line << I18n.t("materials_administration.MAT_ADM_ASS_ASSIGNMENTESSAYTOTALRESULT_NOTPRESENT")
        when 1
          line << I18n.t("materials_administration.MAT_ADM_ASS_ASSIGNMENTESSAYTOTALRESULT_PRESENTED")
        when 2
          line << I18n.t("materials_administration.MAT_ADM_ASS_ASSIGNMENTESSAYTOTALRESULT_REPRESENT")
        when 3
          line << I18n.t("materials_administration.MAT_ADM_ASS_ASSIGNMENTESSAYTOTALRESULT_GRADED")
        when 4
          line << I18n.t("materials_administration.MAT_ADM_ASS_ASSIGNMENTESSAYTOTALRESULT_GRADED_REPRESENT")
        when 5
          line << I18n.t("materials_administration.MAT_ADM_ASS_ASSIGNMENTESSAYTOTALRESULT_GRADED_ACCEPTANCE")
        when 6
          line << I18n.t("materials_administration.MAT_ADM_ASS_ASSIGNMENTESSAYTOTALRESULT_RETUENED_REPRESENT")
        when 7
          line << I18n.t("materials_administration.MAT_ADM_ASS_ASSIGNMENTESSAYTOTALRESULT_RETUENED_ACCEPTANCE")
        end

        if @scores[user.id] && @scores[user.id].assignment_essay_score
          line << @scores[user.id].assignment_essay_score
        else
          line << ""
        end

        csv << line
      end
    end

    send_data csv_data, filename: "#{I18n.t('materials_administration.MAT_ADM_ASS_ASSIGNMENTESSAYTOTALRESULT_CSVFILENAME')}.csv"
  end

  def upload_confirm
    begin
      @csv = CsvEssay.new(csv_params)

      if @csv.valid?
        if @csv.csv?
          FileUtils.mkdir_p(@csv.tmp_dir)
          File.open(@csv.temp_file, 'w+b') do |fp|
            fp.write @csv.file.read
          end
          session[:cav_essay] = @csv.temp_file
        else
          @messages = I18n.t('registerList.PRI_REG_RESULTLIST_NOCSVERROR')
        end
      else
        @messages = I18n.t('registerList.PRI_REG_RESULTLIST_NOSELECTERROR')
        render :upload
      end
    rescue => e
      logger.error e.backtrace.join("\n")
      @messages = I18n.t('registerList.PRI_REG_RESULTLIST_NOSELECTERROR')
    end
  end

  def upload_register
    result

    # ユーザ情報の取得
    users = {}
    @essay.course.enrolled_users.each.with_index(1) do |user, user_index|
      users.store(user.account, user)
    end

    upload_file = "#{session[:cav_essay]}"

    @csv_essays = essay_csv_to_hash(upload_file, users)
    @error_code = 0

    # 読込行数を超えているかチェック
    raise I18n.t("registerList.PRI_REG_IMPORTRESUL_LIMITOVERERROR_html") if @csv_essays.count > CsvEssay::BUS_UTI_CSV_LIMITCOUNT
  end

  def upload_error
    result

    # ユーザ情報の取得
    users = {}
    @essay.course.enrolled_users.each.with_index(1) do |user, user_index|
      users.store(user.account, user)
    end

    upload_file = "#{session[:cav_essay]}"
    @csv_essays = essay_csv_to_hash(upload_file, users)
  end

  def import_file
    result

    # ユーザ情報の取得
    users = {}
    @essay.course.enrolled_users.each.with_index(1) do |user, user_index|
      users.store(user.account, user)
    end

    upload_file = "#{session[:cav_essay]}"

    @csv_essays = essay_csv_to_hash(upload_file, users)
    if @errors.count == 0
      import_essays(users)
    end

    @messages = I18n.t('materials_administration.MAT_ADM_ASS_PASTASSIGNMENTESSAY_ENDIMPORTSCORESHEET')

    render :upload_result
  end

  def report_upload
    result
  end

  def report_upload_confirm
  end

  def import_report
    begin
      if params[:upload].blank?
        @messages = I18n.t("common.COMMON_UPLOADFILENULLCHECK")
        render :report_upload_confirm
        return
      end

      @file = params.require(:upload).permit(:upload_file)

      overwrite_flag = true
      total_score = 0


      @answer_score = @essay.latest_score(@user.id)
      ## ステータスの変更をするかどうか
      status_overwrite_flag = true

      if @answer_score
        ## 2回目以降の提出の時

        ## overwriteFlg==true(担任上書き)かつ採点があり、提出物がない場合はステータスを上書きしない
        if overwrite_flag && @answer_score.total_score >= 0 && @answer_score.link_name.blank?
          status_overwrite_flag = false
        end

        ## 採点済みレポートを担任がアップロードした場合にコメントをクリアするための処理
        essay_comment = @answer_score.assignment_essay_comments.first
      else
        @answer_score = AnswerScore.new
        @answer_score.page_id = @essay.id
        @answer_score.user_id = @user.id
        @answer_score.pass_cd = AssignmentEssay::STATUS_PRESENTED
        @answer_score.total_score = -1
      end

      @answer_score.file = @file[:upload_file]

      ActiveRecord::Base.transaction do
        ## save
        @answer_score.save!

        if status_overwrite_flag
          if essay_comment.blank?
            essay_comment = AssignmentEssayComment.new
            essay_comment.answer_score_id = @answer_score.id
          end

          essay_comment.return_flag = 0
          essay_comment.memo = ""
          essay_comment.mail_flag = 0
        end
        essay_comment.save!
      end

    rescue => e
      logger.error e.backtrace.join("\n")
      @messages = e.message
      render :report_upload_confirm
    end
  end

  def send_mail
    if params[:user] && params[:user].count > 0
      ActiveRecord::Base.transaction do
        params[:user].each do |user|
          user = User.find(user)
          answer_score = @essay.latest_score(user.id)
          if answer_score && answer_score.latest_comment && answer_score.latest_comment.mail_flag == 1
            latest_comment = answer_score.latest_comment
            EssayMailer.send_mail(@essay, latest_comment, user).deliver_now

            latest_comment.mail_flag = Settings.ASSIGNMENTESSAYMAILCOMMENT_MAILFLG_OFF
            latest_comment.save!
          end
        end
      end
    end

    redirect_to teacher_result_result_essay_path(@essay)

  rescue => e
    logger.error e.backtrace.join("\n")
    redirect_to teacher_result_result_essay_path(@essay), :notice => e.message
  end

  def download_report
    file_name = "assignmentEssay.zip"

    begin
      @tmp_dir = "#{Rails.root}/tmp/work/#{Time.zone.now.to_f.to_s.sub(".","")}"
      @temp_file = @tmp_dir + "/" + file_name
      FileUtils.mkdir_p(@tmp_dir)

      File.open(@tmp_dir + "/" + "readme.txt", "w:UTF-8") do |f|
        f.puts(I18n.t("materials_administration.MAT_ADM_ASS_ASSIGNMENTESSAYTOTALRESULT_REPORTDOWNLOADCARD3"))
        f.puts(I18n.t("materials_administration.MAT_ADM_ASS_ASSIGNMENTESSAYTOTALRESULT_REPORTDOWNLOADCARD4"))
      end

      File.open(@tmp_dir + "/" + "report.csv", "w:UTF-8") do |f|
        bom = "\uFEFF"
        csv_data = CSV.generate(bom) do |csv|
          line = []
          line << I18n.t("materials_administration.MAT_ADM_ASS_ASSIGNMENTESSAYTOTALRESULT_REPORTDOWNLOADCARD1")
          line << I18n.t("materials_administration.MAT_ADM_ASS_ASSIGNMENTESSAYTOTALRESULT_REPORTDOWNLOADCARD2")
          csv << line

          @course.enrolled_users.each do |user|
            line = []
            line << user.get_name_no_prefix + user.user_name
            line << user.account
            csv << line

            answer_scores = @essay.answer_scores.where(:user_id => user.id)
            answer_scores.each do |score|
              if score && score.link_name
                report = Rails.root.join("public").to_s + score.get_link_url
                if File.exist?(report)
#                  FileUtils.cp_r(report, @tmp_dir + "/" + score.file_name)
                  report_name = "#{user.get_name_no_prefix}#{user.user_name}_#{score.answer_count.to_s}#{File.extname(score.file_name)}"
                  FileUtils.cp_r(report, @tmp_dir + "/" + report_name)
                end
              end
            end
          end
        end

        f.write(csv_data)
      end

      compress

      zip_data = File.read(@temp_file)

      send_data(zip_data, :type => 'application/zip', :dispositon => 'attachment', :filename => file_name)
    ensure
      clean_up_data
    end
  end

  def download_package
    file_name = "packagedIndividualPracticeSubmission.zip"

    begin
      @tmp_dir = "#{Rails.root}/tmp/work/#{Time.zone.now.to_f.to_s.sub(".","")}"
      @temp_file = @tmp_dir + "/" + file_name
      FileUtils.mkdir_p(@tmp_dir)
      FileUtils.mkdir_p(@tmp_dir + "/tmp")
      FileUtils.mkdir_p(@tmp_dir + "/tmp/kobetsuensyuu")

      @course.enrolled_users.each do |user|
        answer_scores = @essay.answer_scores.where(:user_id => user.id)
        answer_scores.each do |score|
          if score && score.link_name
            report = Rails.root.join("public").to_s + score.get_link_url
            if File.exist?(report)
              report_name = "#{user.account}_#{score.answer_count.to_s}#{File.extname(score.file_name)}"
              FileUtils.cp_r(report, @tmp_dir + "/tmp/kobetsuensyuu/" + report_name)
            end
          end
        end
      end

      result
      File.open(@tmp_dir + "/tmp/kobetsuensyuu/#{I18n.t('materials_administration.MAT_ADM_ASS_ASSIGNMENTESSAYTOTALRESULT_DOWNLOADSCORECARDCSVFILENAME')}.csv", "w") do |f|
        f.write(create_scoresheet)
      end

      analyzer_excel = Rails.root.join("public").to_s + ANALYZER_EXCEL_PATH + "/" + ANALYZER_EXCEL_NAME
      if File.exist?(analyzer_excel)
        FileUtils.cp_r(analyzer_excel, @tmp_dir + "/tmp/kobetsuensyuu/" + ANALYZER_EXCEL_NAME)
      end

      compress

      zip_data = File.read(@temp_file)

      send_data(zip_data, :type => 'application/zip', :dispositon => 'attachment', :filename => file_name)
    ensure
      clean_up_data
    end
  end

  def create_scoresheet
    bom = "\uFEFF"
#    bom = %w(EF BB BF).map { |e| e.hex.chr }.join
    csv_data = CSV.generate(bom) do |csv|
      csv << ["#{I18n.t('materials_administration.MAT_ADM_ASS_ASSIGNMENTESSAYTOTALRESULT_DOWNLOADSCORECARD1')}"]
      line = []
      line << I18n.t('materials_administration.MAT_ADM_ASS_ASSIGNMENTESSAYTOTALRESULT_DOWNLOADSCORECARD2')
      line << @essay.course.id
      line << I18n.t('materials_administration.MAT_ADM_ASS_ASSIGNMENTESSAYTOTALRESULT_DOWNLOADSCORECARD3')
      line << @essay.id
      csv << line

      csv << ["#{I18n.t('materials_administration.MAT_ADM_ASS_ASSIGNMENTESSAYTOTALRESULT_DOWNLOADSCORECARD4')}#{@essay.course.course_name}"]
      csv << ["#{I18n.t('materials_administration.MAT_ADM_ASS_ASSIGNMENTESSAYTOTALRESULT_DOWNLOADSCORECARD5')}#{@essay.generic_page_title}"]

      csv << []
      csv << ["#{I18n.t('materials_administration.MAT_ADM_ASS_ASSIGNMENTESSAYTOTALRESULT_DOWNLOADSCORECARD6')}"]
      csv << ["#{I18n.t('materials_administration.MAT_ADM_ASS_ASSIGNMENTESSAYTOTALRESULT_DOWNLOADSCORECARD7')}"]
      csv << ["#{I18n.t('materials_administration.MAT_ADM_ASS_ASSIGNMENTESSAYTOTALRESULT_DOWNLOADSCORECARD8')}"]
      csv << ["#{I18n.t('materials_administration.MAT_ADM_ASS_ASSIGNMENTESSAYTOTALRESULT_DOWNLOADSCORECARD9')}"]
      csv << ["#{I18n.t('materials_administration.MAT_ADM_ASS_ASSIGNMENTESSAYTOTALRESULT_DOWNLOADSCORECARD10')}"]
      csv << ["#{I18n.t('materials_administration.MAT_ADM_ASS_ASSIGNMENTESSAYTOTALRESULT_DOWNLOADSCORECARD11')}"]
      csv << ["#{I18n.t('materials_administration.MAT_ADM_ASS_ASSIGNMENTESSAYTOTALRESULT_DOWNLOADSCORECARD12')}"]
      csv << ["#{I18n.t('materials_administration.MAT_ADM_ASS_ASSIGNMENTESSAYTOTALRESULT_DOWNLOADSCORECARD13')}"]
      csv << ["#{I18n.t('materials_administration.MAT_ADM_ASS_ASSIGNMENTESSAYTOTALRESULT_DOWNLOADSCORECARD14')}"]
      csv << ["#{I18n.t('materials_administration.MAT_ADM_ASS_ASSIGNMENTESSAYTOTALRESULT_DOWNLOADSCORECARD15')}"]

      csv << []

      line = []
      line << I18n.t('materials_administration.MAT_ADM_ASS_ASSIGNMENTESSAYTOTALRESULT_DOWNLOADSCORECARD16')
      line << I18n.t('materials_administration.MAT_ADM_ASS_ASSIGNMENTESSAYTOTALRESULT_DOWNLOADSCORECARD17')
      line << I18n.t('materials_administration.MAT_ADM_ASS_ASSIGNMENTESSAYTOTALRESULT_DOWNLOADSCORECARD18')
      line << I18n.t('materials_administration.MAT_ADM_ASS_ASSIGNMENTESSAYTOTALRESULT_DOWNLOADSCORECARD19')
      line << I18n.t('materials_administration.MAT_ADM_ASS_ASSIGNMENTESSAYTOTALRESULT_DOWNLOADSCORECARD20')
      line << I18n.t('materials_administration.MAT_ADM_ASS_ASSIGNMENTESSAYTOTALRESULT_DOWNLOADSCORECARD21')
      line << I18n.t('materials_administration.MAT_ADM_ASS_ASSIGNMENTESSAYTOTALRESULT_DOWNLOADSCORECARD22')
      line << I18n.t('materials_administration.MAT_ADM_ASS_ASSIGNMENTESSAYTOTALRESULT_DOWNLOADSCORECARD23')
      line << I18n.t('materials_administration.MAT_ADM_ASS_ASSIGNMENTESSAYTOTALRESULT_DOWNLOADSCORECARD24')
      csv << line

      @users.each.with_index(1) do |user, index|
        line = []

        line << CsvEssay::BUS_SER_IMP_IMP_IDENTIFICATIONCD
        line << user.account
        line << user.get_name_no_prefix + user.user_name

        if @scores[user.id]
          line << @scores[user.id].answer_count
        else
          line << 0
        end

        case @essay.essay_status(user.id)
        when 0
          line << I18n.t("materials_administration.MAT_ADM_ASS_ASSIGNMENTESSAYTOTALRESULT_NOTPRESENT")
        when 1
          line << I18n.t("materials_administration.MAT_ADM_ASS_ASSIGNMENTESSAYTOTALRESULT_PRESENTED")
        when 2
          line << I18n.t("materials_administration.MAT_ADM_ASS_ASSIGNMENTESSAYTOTALRESULT_REPRESENT")
        when 3
          line << I18n.t("materials_administration.MAT_ADM_ASS_ASSIGNMENTESSAYTOTALRESULT_GRADED")
        when 4
          line << I18n.t("materials_administration.MAT_ADM_ASS_ASSIGNMENTESSAYTOTALRESULT_GRADED_REPRESENT")
        when 5
          line << I18n.t("materials_administration.MAT_ADM_ASS_ASSIGNMENTESSAYTOTALRESULT_GRADED_ACCEPTANCE")
        when 6
          line << I18n.t("materials_administration.MAT_ADM_ASS_ASSIGNMENTESSAYTOTALRESULT_RETUENED_REPRESENT")
        when 7
          line << I18n.t("materials_administration.MAT_ADM_ASS_ASSIGNMENTESSAYTOTALRESULT_RETUENED_ACCEPTANCE")
        end

        if @scores[user.id] && @scores[user.id].assignment_essay_score
          line << @scores[user.id].assignment_essay_score
        else
          line << ""
        end

        line << ""

        if @scores[user.id] && @scores[user.id].latest_comment
          if @scores[user.id].latest_comment.mail_flag == 1
            ##line << I18n.t("materials_administration.MAT_ADM_ASS_ASSIGNMENTESSAYTOTALRESULT_SENDPLAN")
            line << ""
          else
            line << ""
          end
        else
          line << ""
        end

        if @scores[user.id] && @scores[user.id].latest_comment
          line << @scores[user.id].latest_comment.memo
        else
          line << ""
        end

        csv << line
      end
    end

    return csv_data
  end

  def history
    @user = User.find(params[:user])
    @histories = []
    scores = @essay.answer_score_histories.where(user_id: @user.id).order(:answer_count)

    scores.each.with_index(1) do |score, i|
      break if i >= scores.count

      @histories << score
    end
  end

  def comment
    score = AnswerScoreHistory.find(params[:score])
    comment = score.latest_comment

    comment.update!(comment_params)
    redirect_to teacher_result_result_essay_history_path(@essay, user: score.user_id)

  rescue => e
    logger.error e.backtrace.join("\n")
    redirect_to teacher_result_result_essay_history_path(@essay, user: score.user_id), notice: e.message
  end

  def upload_return_report
    if @essay.assignment_essay_return_method_cd != Settings.GENERICPAGE_RETURN_METHOD_INDIVIDUALLY &&
       @essay.assignment_essay_return_method_cd != Settings.GENERICPAGE_RETURN_METHOD_SIMULTANEOUSLY
       redirect_to teacher_result_result_essay_path(@essay)
    end
  end

  def confirm_return_report
    essay_file = EssayFile.new
    essay_file.file = params[:upload]
    essay_file.check_data
    if essay_file.errors.count != 0
      flash.now[:notice] = I18n.t("materials_administration.MAT_ADM_ASS_ASSIGNMENTESSAYUPLOAD_EXPLANATION7")
      result
      render :upload_return_report
      return
    end

    essay_file.extract_file
    extracted_files = essay_file.extracted_files
    session[:return_extract_path] = essay_file.extracted_file_path

    @user_files = []
    @essay.course.course_enrollment_users.each do |enrollment_user|
      next if enrollment_user.user.blank? || enrollment_user.user.get_name_no_prefix.to_s.length == 0

      extracted_files.each do |file_name|
        if file_name.start_with?(enrollment_user.user.get_name_no_prefix)
          @user_files << [enrollment_user.user.id, enrollment_user.user.get_name_no_prefix + enrollment_user.user.user_name, file_name]
          break
        end
      end
    end

  rescue => e
    logger.error e.backtrace.join("\n")
    flash.now[:notice] = e.message.toutf8.gsub("\\", "/")
    delete_temporary_file

    render :upload_return_report
  end

  def save_return_report
    if params[:user] && params[:user].count > 0
      extracted_file_path = session[:return_extract_path]

      params[:user].each do |user|
        latest_score = @essay.latest_score(user)

        if latest_score.blank?
          latest_score = AnswerScore.new
          latest_score.user_id = user
          latest_score.page_id = @essay.id
          latest_score.answer_count = 1
          latest_score.pass_cd = Settings.ANSWERSCORE_PASSCD_SUBMITTED
          latest_score.total_score = -1
          latest_score.total_score = (Settings.DEFAULT_ARGUMENT_INT).abs - 1
          latest_score.save!(validate: false)
        end

        Dir.entries(extracted_file_path).each do |entry|
          if entry.start_with?(latest_score.user.get_name_no_prefix)
            new_file = extracted_file_path + "/" + entry

            latest_comment = latest_score.latest_comment
            if latest_comment.blank?
              latest_comment = AssignmentEssayComment.new
              latest_comment.answer_score_id = latest_score.id
              latest_comment.return_flag = 0
              latest_comment.memo = ""
              latest_comment.mail_flag = 0
            end

            if @essay.assignment_essay_return_method_cd == Settings.GENERICPAGE_RETURN_METHOD_SIMULTANEOUSLY
              latest_comment.return_flag = 0
            else
              latest_comment.return_flag = 1
            end

            latest_comment.set_return_file(new_file)
            latest_comment.save
            break
          end
        end
      end
    end

    #session[:return_extract_path] = nil
    redirect_to teacher_result_result_essay_path(@essay), :notice => I18n.t("common.COMMON_UPLOADED")

  rescue => e
    logger.error e.backtrace.join("\n")
    flash.now[:notice] = e.message
    confirm_return_report
    render :confirm_return_report

  ensure
    delete_temporary_file
  end

  def return_report
    if params[:users] && params[:users].count > 0
      params[:users].each do |user|
        latest_score = @essay.latest_score(user)
        if latest_score
          latest_comment = latest_score.latest_comment
          if latest_comment
            latest_comment.return_flag = 1
            latest_comment.save
          end
        end
      end
    end

    redirect_to teacher_result_result_essay_path(@essay), :notice => I18n.t("materials_administration.MAT_ADM_ASS_ASSIGNMENTESSAYTOTALRESULT_RETURNCOMPLETE")
  end

  def essay_csv_to_hash(upload_file, users)
    lineno = 0
    index = 0
    essays = []
    accounts = []
    @errors = {}

    csv_data = CSV.parse(File.new(upload_file)) do |csv_row|
      case lineno
      when 1
        # 科目IDが違う場合
        if csv_row[1] != @essay.course.id.to_s
          @messages = I18n.t('registerList.PRI_REG_IMPORTRESUL_SUBJECTIDRERROR')
          break
        end

        # タイトルIDが違う場合
        if csv_row[3] != @essay.id.to_s
          @messages = I18n.t('registerList.PRI_REG_IMPORTRESUL_TITLEIDRERROR')
          break
        end
      end

      if lineno > CsvEssay::HEADER_LINENO
        line = {}
        line["identification_cd"] = csv_row[0]
        line["account"] = csv_row[1]
        line["usr_name"] = csv_row[2]
        line["answer_count"] = csv_row[3]
        line["status"] = get_status_cd(csv_row[4])
        line["total_score"] = csv_row[5]
        line["reintroduction_flag"] = csv_row[6]
        line["mail_flag"] = csv_row[7]
        line["comment"] = csv_row[8]
        index += 1
        essays << line

        # キー項目のバリデーション
        # 項目数が正しくない場合
        if line.count != CsvEssay::BUS_UTI_CSV_COLUMNCOUNT
          @errors[index] = I18n.t('registerList.PRI_REG_RESULTLIST_COLUMNCOUNTERROR')
          next
        end

        # 識別子コードが入力されていない場合
        if line["identification_cd"].blank?
          @errors[index] = I18n.t('registerList.PRI_REG_RESULTLIST_IDENTIFICATIONCDNULLERROR')
          next
        end

        # 識別子コードが正しくない場合
        if line["identification_cd"] != CsvEssay::BUS_SER_IMP_IMP_IDENTIFICATIONCD
          @errors[index] = I18n.t('registerList.PRI_REG_RESULTLIST_IDENTIFICATIONCDERROR')
          next
        end

        # 学生IDが変更されている場合
        unless users[line["account"]]
          @errors[index] = I18n.t('registerList.PRI_REG_RESULTLIST_ACOUNTERROR')
          next
        else
          user_id = users[line["account"]].id
        end

        # 提出回数が変更されている場合
        if @scores[user_id]
          answer_count = @scores[user_id].answer_count.to_s
        else
          answer_count = "0"
        end
        if answer_count != line["answer_count"]
          @errors[index] = I18n.t('registerList.PRI_REG_RESULTLIST_ANSWERCOUNTERROR')
          next
        end

        # ステータスが変更されている場合

        status_cd = get_status_cd(line["status"])
        if line["status"] != @essay.essay_status(user_id)
          @errors[index] = I18n.t('registerList.PRI_REG_RESULTLIST_STATUSERROR')
          next
        end

        # 点数に文字列が含まれている場合
        # 点数が0～100でないとき場合
        unless (line["total_score"].to_i.to_s == line["total_score"].to_s &&
                line["total_score"].to_i >= 0 && line["total_score"].to_i <= 100) ||
                line["total_score"].blank?
          @errors[index] = I18n.t('registerList.PRI_REG_RESULTLIST_SCOREERROR')
          next
        end

        # 再提出フラグがnullか1でない場合
        unless line["reintroduction_flag"].blank? || line["reintroduction_flag"] == "1"
          @errors[index] = I18n.t('registerList.PRI_REG_RESULTLIST_REINTRODUCTIONFLGCDERROR')
          next
        end

        # メール送信フラグがnullか1でない場合
        unless line["mail_flag"].blank? || line["mail_flag"] == "1"
          @errors[index] = I18n.t('registerList.PRI_REG_RESULTLIST_MAILFLGCDERROR')
          next
        end

        # コメントが1000字を超えている場合場合
        unless line["comment"].blank? || line["comment"].length <= 1000
          @errors[index] = I18n.t('registerList.PRI_REG_RESULTLIST_COMENTFLGCDERROR')
          next
        end
      end
      lineno += 1
    end

    essays
  end

  def get_status_cd(status)
    case status
    when I18n.t("materials_administration.MAT_ADM_ASS_ASSIGNMENTESSAYTOTALRESULT_NOTPRESENT")
      status_cd = 0
    when I18n.t("materials_administration.MAT_ADM_ASS_ASSIGNMENTESSAYTOTALRESULT_PRESENTED")
      status_cd = 1
    when I18n.t("materials_administration.MAT_ADM_ASS_ASSIGNMENTESSAYTOTALRESULT_REPRESENT")
      status_cd = 2
    when I18n.t("materials_administration.MAT_ADM_ASS_ASSIGNMENTESSAYTOTALRESULT_GRADED")
      status_cd = 3
    when I18n.t("materials_administration.MAT_ADM_ASS_ASSIGNMENTESSAYTOTALRESULT_GRADED_REPRESENT")
      status_cd = 4
    when I18n.t("materials_administration.MAT_ADM_ASS_ASSIGNMENTESSAYTOTALRESULT_GRADED_ACCEPTANCE")
      status_cd = 5
    when I18n.t("materials_administration.MAT_ADM_ASS_ASSIGNMENTESSAYTOTALRESULT_RETUENED_REPRESENT")
      status_cd = 6
    when I18n.t("materials_administration.MAT_ADM_ASS_ASSIGNMENTESSAYTOTALRESULT_RETUENED_ACCEPTANCE")
      status_cd = 7
    else
      if status =~ /^[0-7]$/
        status_cd = status.to_i
      else
        status_cd = ""
      end
    end

    status_cd
  end

  def import_essays(users)
    ActiveRecord::Base.transaction do
      begin
        @csv_essays.each do |csv_essay|
          if users[csv_essay["account"]]
            user_id = users[csv_essay["account"]].id
          end

          answer_score = @essay.latest_score(user_id)
          if answer_score.nil?
            answer_score = AnswerScore.new
            answer_score.page_id = @essay.id
            answer_score.user_id = user_id
            answer_score.answer_count = 1
            answer_score.pass_cd = Settings.ANSWERSCORE_PASSCD_SUBMITTED
          end

          ## レポートの採点結果を更新する
          answer_score.assignment_essay_score = csv_essay["total_score"].to_i
          answer_score.total_score = (Settings.DEFAULT_ARGUMENT_INT).abs - 1

          if csv_essay["reintroduction_flag"] == "1"
            answer_score.pass_cd = Settings.ANSWERSCORE_PASSCD_UNSUBMITTING
          else
            answer_score.pass_cd = Settings.ANSWERSCORE_PASSCD_SUBMITTED
          end

          answer_score.save!(validate: false)

          comment = answer_score.latest_comment
          if comment.nil?
            comment = AssignmentEssayComment.new(:answer_score_id => answer_score.id)
          end
          comment.memo = csv_essay["comment"].presence || ""

          if @essay.assignment_essay_return_method_cd && @essay.assignment_essay_return_method_cd == 2
            comment.return_flag = Settings.ASSIGNMENTESSAYMAILCOMMENT_RETURNFLG_RETURNED
          end

          if csv_essay["mail_flag"] == "1"
            comment.mail_flag = Settings.ASSIGNMENTESSAYMAILCOMMENT_MAILFLG_ON
            comment.save!
          else
            comment.mail_flag = Settings.ANNOUNCEMENT_MAILFLG_UNTRANSMISSION
            comment.save!
          end
        end
      rescue => e
        logger.error e.backtrace.join("\n")
        raise ActiveRecord::Rollback
        @messages = e.message
      end
    end
  end

  private
    def set_essay
      @essay = Essay.find_by(id: params[:id], type_cd: Settings.GENERICPAGE_TYPECD_ASSIGNMENTESSAYCODE)
    end

    def answer_score_params
      params.require(:answer_score).permit(:page_id, :user_id, :answer_count, :pass_cd, :assignment_essay_score,
        assignment_essay_comments_attributes: [:memo, :mail_flag, :id, :answer_score_id])
    end

    def get_users(search_params)
      users
    end

    def set_user
      @user = User.find(params[:user_id])
    end

    def csv_params
      params.require(:upload).permit(:file)
    end

    def comment_params
      params.require(:comment).permit(:memo)
    end

    def delete_temporary_file
      unless session[:return_extract_path].blank?
        extracted_file_path = session[:return_extract_path]
        FileUtils.rm_rf(extracted_file_path)
      end

    ensure
      session[:return_extract_path] = nil
    end
end
