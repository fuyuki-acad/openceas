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

class Essay < GenericPage
  attr_accessor :latest_answer_score

  ## 共通のステータス
	#** 未提出 * *#
	STATUS_NOTPRESENT = 0
	#** 提出済（未採点） * *#
	STATUS_PRESENTED = 1
	#** 期限前 * *#
	STATUS_BEFORE_START = 8
	#** 終了 * *#
	STATUS_AFTER_END = 9
  #** 採点済（再提出）※通常レポート用 * *#
	STATUS_GRADED_REPRESENT = 2
	#** 採点済（受理） ※通常レポート用 * *#
	STATUS_GRADED_ACCEPTANCE = 3
  #** 採点済（再提出）※フィードバック用 * *#
	STATUS_GRADED_REPRESENT_FEEDBACK = 4
	#** 採点済（受理） ※フィードバック用 * *#
	STATUS_GRADED_ACCEPTANCE_FEEDBACK = 5
	#** 返却済（再提出）※フィードバック用 * *#
	STATUS_RETURNED_REPRESENT_FEEDBACK = 6
	#** 返却済（受理） ※フィードバック用 * *#
	STATUS_RETURNED_ACCEPTANCE_FEEDBACK = 7

  def essay_status(user_id)
    score = self.answer_scores.where(user_id: user_id).order("updated_at DESC").first
    ## 通常のレポートの時
    if self.assignment_essay_return_method_cd == Settings.GENERICPAGE_RETURN_METHOD_NOT_RETURN
      if score
        if score.total_score < 0
          ## 提出済（未採点）
          AssignmentEssay::STATUS_PRESENTED
        elsif score.pass_cd == Settings.ANSWERSCORE_PASSCD_UNSUBMITTING
          ## 採点済（再提出）
          AssignmentEssay::STATUS_GRADED_REPRESENT
        elsif score.pass_cd == Settings.ANSWERSCORE_PASSCD_SUBMITTED
          ## 採点済（受理）
          AssignmentEssay::STATUS_GRADED_ACCEPTANCE
        end
      else
        ## 未提出
        AssignmentEssay::STATUS_NOTPRESENT
      end

      ## フィードバックの時
		elsif self.assignment_essay_return_method_cd == Settings.GENERICPAGE_RETURN_METHOD_SIMULTANEOUSLY ||
          self.assignment_essay_return_method_cd == Settings.GENERICPAGE_RETURN_METHOD_INDIVIDUALLY

      if score
				## 提出済（未採点）
				if score.total_score.blank? || score.total_score < 0
					AssignmentEssay::STATUS_PRESENTED;
        else
          comment = score.latest_comment
          if comment.blank?
            ## 未提出
            AssignmentEssay::STATUS_NOTPRESENT
            return
          end

					if comment.return_flag.blank?
						## PDFレポートでassignment_essay_scoreが登録されているのにreturnFlgがnullの場合
						## returnFlgを設定する
            if self.assignment_essay_return_method_cd == Settings.GENERICPAGE_RETURN_METHOD_INDIVIDUALLY
              comment.return_flag = Settings.ASSIGNMENTESSAYMAILCOMMENT_RETURNFLG_RETURNED
            elsif self.assignment_essay_return_method_cd == Settings.GENERICPAGE_RETURN_METHOD_SIMULTANEOUSLY
              comment.return_flag = Settings.ASSIGNMENTESSAYMAILCOMMENT_RETURNFLG_NOTRETURN
            end
					end
          if comment.return_flag.blank?
            AssignmentEssay::STATUS_PRESENTED;
					elsif score.pass_cd == Settings.ANSWERSCORE_PASSCD_UNSUBMITTING
						## 採点済（再提出）
						if comment.return_flag == Settings.ASSIGNMENTESSAYMAILCOMMENT_RETURNFLG_NOTRETURN
							AssignmentEssay::STATUS_GRADED_REPRESENT_FEEDBACK;

							## 返却済（再提出）
            elsif comment.return_flag == Settings.ASSIGNMENTESSAYMAILCOMMENT_RETURNFLG_RETURNED
							AssignmentEssay::STATUS_RETURNED_REPRESENT_FEEDBACK;
						end

          elsif score.pass_cd == Settings.ANSWERSCORE_PASSCD_SUBMITTED
						## 採点済（受理）
            if comment.return_flag == Settings.ASSIGNMENTESSAYMAILCOMMENT_RETURNFLG_NOTRETURN
							AssignmentEssay::STATUS_GRADED_ACCEPTANCE_FEEDBACK;

							## 返却済（受理）
            elsif comment.return_flag == Settings.ASSIGNMENTESSAYMAILCOMMENT_RETURNFLG_RETURNED
							AssignmentEssay::STATUS_RETURNED_ACCEPTANCE_FEEDBACK;
						end
          end
        end
      else
        ## 未提出
        AssignmentEssay::STATUS_NOTPRESENT
      end
    end
  end

  def result_essay_status(user_id)
    status = essay_status(user_id)

    now = Time.zone.now

    if self.end_time < now
      if status == AssignmentEssay::STATUS_NOTPRESENT
        status = AssignmentEssay::STATUS_AFTER_END
      end
		elsif self.start_time > now
      status = AssignmentEssay::STATUS_BEFORE_START
    end

    status
  end

  def essay_status_name(user_id)
    case result_essay_status(user_id)
    when AssignmentEssay::STATUS_NOTPRESENT
      ## レポートの状態が0の場合は「未提出」
			I18n.t("converter.PRE_CON_ASSIGNMENTESSAYSTATUSCONVERTER_NOTPRESENT")

    when AssignmentEssay::STATUS_PRESENTED
  		## レポートの状態が1の場合は「提出済」
      I18n.t("converter.PRE_CON_ASSIGNMENTESSAYSTATUSCONVERTER_PRESENTED")

    when AssignmentEssay::STATUS_GRADED_REPRESENT
  		## レポートの状態が2の場合は「再提出」
      I18n.t("converter.PRE_CON_ASSIGNMENTESSAYSTATUSCONVERTER_REPRESENT")

    when AssignmentEssay::STATUS_GRADED_ACCEPTANCE
  		## ※レポートの状態が3の場合は「受理」
      I18n.t("converter.PRE_CON_ASSIGNMENTESSAYSTATUSCONVERTER_ACCEPTANCE")

    when AssignmentEssay::STATUS_GRADED_REPRESENT_FEEDBACK
  		## ※レポートの状態が4の場合は「再提出」
      I18n.t("converter.PRE_CON_ASSIGNMENTESSAYSTATUSCONVERTER_REPRESENT")

    when AssignmentEssay::STATUS_GRADED_ACCEPTANCE_FEEDBACK
  		## ※レポートの状態が5の場合は「受理」
      I18n.t("converter.PRE_CON_ASSIGNMENTESSAYSTATUSCONVERTER_ACCEPTANCE")

    when AssignmentEssay::STATUS_RETURNED_REPRESENT_FEEDBACK
  		## ※レポートの状態が6の場合は「再提出（返却レポートあり）」
      I18n.t("converter.PRE_CON_ASSIGNMENTESSAYSTATUSCONVERTER_REPRESENT") + I18n.t("converter.PRE_CON_ASSIGNMENTESSAYSTATUSCONVERTER_RETURNED")

    when AssignmentEssay::STATUS_RETURNED_ACCEPTANCE_FEEDBACK
  		## ※レポートの状態が7の場合は「受理（返却レポートあり）」
      I18n.t("converter.PRE_CON_ASSIGNMENTESSAYSTATUSCONVERTER_ACCEPTANCE") + I18n.t("converter.PRE_CON_ASSIGNMENTESSAYSTATUSCONVERTER_RETURNED")

    when AssignmentEssay::STATUS_BEFORE_START
  		## レポートの状態が8の場合は「期限前」
      I18n.t("converter.PRE_CON_ASSIGNMENTESSAYSTATUSCONVERTER_BEFORESTART")

    when AssignmentEssay::STATUS_AFTER_END
  		## レポートの状態が9の場合は「終了」
      I18n.t("converter.PRE_CON_ASSIGNMENTESSAYSTATUSCONVERTER_AFTEREND")
  	end
  end

  def confirm_status
		now = Time.zone.now

    ## レポートの状態が9の場合は「終了」
		if self.end_time < now
      STATUS_AFTER_END

      ## レポートの状態が8の場合は「期限前」
		elsif self.start_time > now
      STATUS_BEFORE_START

      ## レポートの状態が0の場合は「受付中」
		else
      STATUS_NOTPRESENT
		end
  end

  def confirm_status_name
		now = Time.zone.now

    ## レポートの状態が9の場合は「終了」
		if self.end_time < now
      I18n.t("converter.PRE_CON_ASSIGNMENTESSAYSTATUSCONVERTER_AFTEREND")

      ## レポートの状態が8の場合は「期限前」
		elsif self.start_time > now
      I18n.t("converter.PRE_CON_ASSIGNMENTESSAYSTATUSCONVERTER_BEFORESTART")

      ## レポートの状態が0の場合は「受付中」
		else
      I18n.t("converter.PRE_CON_ASSIGNMENTESSAYSTATUSCONFIRMCONVERTER_DURING")
		end
  end

  def can_submit?(user_id)
    can_submit = true

    status = essay_status(user_id)
    ## 受理されている場合は提出不可
    if status == AssignmentEssay::STATUS_GRADED_ACCEPTANCE ||
       status == AssignmentEssay::STATUS_GRADED_ACCEPTANCE_FEEDBACK ||
       status == AssignmentEssay::STATUS_RETURNED_ACCEPTANCE_FEEDBACK
      can_submit = false

    ## 未提出の時は期限前・終了かどうかの判定を行う
    elsif status == AssignmentEssay::STATUS_NOTPRESENT
      if self.start_time > Time.zone.now
        ## 期限前
        can_submit = false
      elsif self.end_time < Time.zone.now
        ## 期限終了
        can_submit = false
      end

    elsif status == AssignmentEssay::STATUS_PRESENTED
      if self.end_time < Time.zone.now
        ## 期限終了
        can_submit = false
      end
    end

    can_submit
  end

  def unread_essay_count
    if @count.blank?
      unread_essay = UnreadAssignmentEssayCountView.where(:course_id => self.course_id, :generic_page_id => self.id).first
      if unread_essay
        @count = unread_essay.unread_count
      else
        @count = 0
      end
    end

    @count
  end

  def report_cd
    ret = 1

    ## 通常レポートの時
    if self.pre_grading_enable_flag == Settings.GENERICPAGE_PREGRADINGENABLEFLG_OFF
      if self.end_time <= Time.zone.now
        ret = 2
      else
        ret = 0
      end
    elsif self.pre_grading_enable_flag == Settings.GENERICPAGE_PREGRADINGENABLEFLG_ON
      ret = 2
    end

    ret
  end

  def max_answer_count(user)
    count = self.answer_scores.where("user_id = ?", user.id).maximum("answer_count")
    count.blank? ? 0 : count
  end

  def total_upload_filesize(user_id = nil)
    if user_id.blank?
      return I18n.t("materials_administration.MAT_ADM_ASS_UPLOADED_FILES_HAS_BEEN_DELETED") if self.essayfile_deleted == 1
      total = self.answer_score_histories.sum(:file_size)
    else
      histories = self.answer_score_histories.where(user_id: user_id)
      return if histories.count == 0
      return I18n.t("materials_administration.MAT_ADM_ASS_UPLOADED_FILE_HAS_BEEN_DELETED") if self.essayfile_deleted == 1
      total = histories.sum(:file_size)
    end

    if total == 0
      return "#{total} MB"
    else
      total = total.to_f / (1024 * 1024)
      return "#{total.round(2)} MB"
    end
  end
end
