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

class EssaysController < ApplicationController
  before_action :require_enrolled_or_open_assigned, only: [:show]
  before_action :require_enrolled, only: [:upload, :password, :file, :return_file]
  before_action :set_essay, only: [:show, :upload, :password, :file, :return_file]

  def show
		## レポートを取得する
		@answer_scores = @essay.answer_score_histories.where("user_id = ?", current_user.id).order("answer_count ASC")

		## 今回取得した配列には一人のユーザについてのレポートの状態だけが入っている。その配列の末尾(=最新のもの)を現在の状態として取得
		@assignmentEssayStatus = @essay.essay_status(current_user.id)

		## レポートの提出可否を表すフラグ
		@is_can_submit = true

		## 受理されている場合は提出不可
		if @assignmentEssayStatus == AssignmentEssay::STATUS_GRADED_ACCEPTANCE ||
       @assignmentEssayStatus == AssignmentEssay::STATUS_GRADED_ACCEPTANCE_FEEDBACK ||
       @assignmentEssayStatus == AssignmentEssay::STATUS_RETURNED_ACCEPTANCE_FEEDBACK
			@is_can_submit = false

			## 未提出の時は期限前・終了かどうかの判定を行う
		elsif @assignmentEssayStatus == AssignmentEssay::STATUS_NOTPRESENT
			## 期限前の判定
			if @essay.start_time && Time.zone.now < @essay.start_time
				@is_can_submit = false
				@assignmentEssayStatus = AssignmentEssay::STATUS_BEFORE_START

				## 終了の判定
			elsif @essay.end_time && Time.zone.now > @essay.end_time
				@is_can_submit = false
				@assignmentEssayStatus = AssignmentEssay::STATUS_AFTER_END
			end

			## 提出済の時は終了かどうかの判定を行う
		elsif @assignmentEssayStatus == AssignmentEssay::STATUS_PRESENTED
			## 終了の判定
			if @essay.end_time && Time.zone.now > @essay.end_time
        @assignmentEssayStatus = AssignmentEssay::STATUS_AFTER_END
				@is_can_submit = false
			end
		end

    render "password" if !@essay.start_pass.blank? && !session[:essay_start_pass_flag]
  end

  def password
    if params[:start_pass].blank?
      flash.now[:notice] = I18n.t("execution.COMMONMATERIALSEXECUTION_STARTPASSWORDCHECK1")
    elsif params[:start_pass] == @essay.start_pass
      session[:essay_start_pass_flag] = true
      redirect_to :action => :show, :id => @essay
    else
      flash.now[:notice] = I18n.t("execution.COMMONMATERIALSEXECUTION_STARTPASSWORDCHECK2")
    end
  end

  def upload
    if @essay.expired?
      render "error"
      return
    end

    @is_can_submit = true

    if current_user.student?
      total_score = -1
      overwrite_flag = false
    else
      total_score = 0
      overwrite_flag = true
    end

    @answer_score = @essay.latest_score(current_user.id)
		## ステータスの変更をするかどうか
		status_overwrite_flag = true

    if @answer_score
  		## 2回目以降の提出の時
  		## →未提出で採点された場合も提出回数は1回とし、カウントを増やすように変更(2011/09/15)
  		## 再提出の時（＝点数がつけられており、なおかつパスコードが０） &&overwriteFlgがfalseの場合
  		if !overwrite_flag && @answer_score.total_score >= 0 && @answer_score.pass_cd == Settings.ANSWERSCORE_PASSCD_UNSUBMITTING
        ## 提出回数+1する
        @answer_score.answer_count = @answer_score.answer_count + 1
  		else
				## overwriteFlg==true(担任上書き)かつ採点があり、提出物がない場合はステータスを上書きしない
        if overwrite_flag && @answer_score.total_score >= 0 && @answer_score.link_name.blank?
          status_overwrite_flag = false
        end

        ## 採点済みレポートを担任がアップロードした場合にコメントをクリアするための処理
        essay_comment = @answer_score.assignment_essay_comments.first
      end
    else
      @answer_score = AnswerScore.new
    end


		## 必要なデータをセット
		if status_overwrite_flag || !overwrite_flag
			@answer_score.pass_cd = AssignmentEssay::STATUS_PRESENTED
			@answer_score.total_score = total_score
		end
    if @answer_score.new_record?
		  @answer_score.page_id = @essay.id
      @answer_score.user_id = current_user.id
    end

    @answer_score.file = params[:file]

    if current_user.student?
      ActiveRecord::Base.transaction do
    		## save
    		@answer_score.save!

    		## ステータス上書きフラグがtrueの場合のみコメントを上書きする。学生がアップロードした場合、元々assignmentEssayCommentは何もしていない
    		if status_overwrite_flag
          essay_comment = AssignmentEssayComment.new if essay_comment.nil?
          essay_comment.answer_score_id = @answer_score.id
          essay_comment.return_flag = 0
          essay_comment.memo = ""
          essay_comment.mail_flag = 0
    			## save
    			essay_comment.save!
    		end
      end
    end

    redirect_to :action => :show, :id => @essay

  rescue ActiveRecord::StatementInvalid => e
    logger.error e.backtrace.join("\n")
    if(e.cause.class == Mysql2::Error &&
       e.cause.message.match(/^Incorrect string value/))
      flash.now[:notice] = I18n.t("error.ERROR_UNSUPPORTED_CHARACTER_IN_FILE_NAME")
    else
      flash.now[:notice] = I18n.t("error.ERROR_FATAL_EXPLANATION1_html")
    end
    render action: :show

  rescue => e
    if @answer_score && @answer_score.errors.count == 0
      logger.error e.backtrace.join("\n")
      flash.now[:notice] = I18n.t("error.ERROR_FATAL_EXPLANATION1_html")
    end
    render action: :show
  end

  def clear_password
    session[:essay_start_pass_flag] = nil
    head :no_content
  end

  def file
    if params[:count].blank?
      score = @essay.latest_score(current_user.id)
    else
      score = @essay.answer_score_histories.where("user_id = ? AND answer_count = ?", current_user.id, params[:count]).first
    end

    if score && score.link_name
      file_path = score.get_file_path
      stat = File::stat(file_path)

      if score.file_name.blank?
        file_name = File.basename(score.link_name)
      else
        file_name = score.file_name
      end
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
    if params[:count].blank?
      score = @essay.answer_score_histories.where("user_id = ?", current_user.id).order("answer_count DESC").first
    else
      score = @essay.answer_score_histories.where("user_id = ? AND answer_count = ?", current_user.id, params[:count]).first
    end

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
      #file_name = ERB::Util.url_encode(file_name) if msie?

      type, is_inline = get_content_type(file_name)
      if is_inline
        send_file(file_path, filename: file_name, length: stat.size, type: type, disposition: :inline)
      else
        send_file(file_path, filename: file_name, length: stat.size, type: type, disposition: :attachment)
      end
    end
  end

  private
    def set_essay
      @essay = Essay.find_by(id: params[:id], type_cd: Settings.GENERICPAGE_TYPECD_ASSIGNMENTESSAYCODE)
    end
end
