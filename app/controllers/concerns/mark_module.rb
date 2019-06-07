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

module MarkModule
  extend ActiveSupport::Concern

  ANDER_SCORE = "-"

  def get_answers_scores(course, user)
    answer_scores = {}

    ## 科目に関連のあるページをすべて取得
		## その中から複合式、記号入力式テストをすべて取得
		## ユーザの解答結果だけ繰り返し
		## テストの数だけ繰り返し
		course.exams.each do |exam|
			## 解答結果がテストの中にあれば、解答結果をプレゼン用DTOに変換しリストに追加する
			answer_score = exam.answer_scores.
        where("user_id = ? AND total_score >= ?", user.id, Settings.ANSWERSCORE_TMP_SAVED_SCORE).
        order("answer_count DESC").first

			if answer_score
        question_composition = exam.get_question_composition

				## 成績の計算
				mark_exam(exam, answer_score)

				if question_composition == Settings.QUESTIONCOMPOSITIONCD_MULTIPLEONLY || exam.type_cd == Settings.GENERICPAGE_TYPECD_MULTIPLEFIBCODE
					answer_score.view_total_score = answer_score.total_score.to_s + "/100"
				elsif question_composition != Settings.QUESTIONCOMPOSITIONCD_MULTIPLEONLY &&
						  (exam.self_flag == Settings.GENERICPAGE_SELFFLG_SELF ||
						   exam.self_flag == Settings.GENERICPAGE_SELFFLG_MUTUAL ||
						   exam.self_flag == Settings.GENERICPAGE_SELFFLG_MUTUAL2)
					if answer_score.total_score && answer_score.total_score >= 0
						answer_score.view_total_score = answer_score.total_score.to_s + "/100"
					elsif answer_score.self_total_score && answer_score.self_total_score >= 0
            answer_score.view_total_score = answer_score.self_total_score.to_s + "/100"
					else
            answer_score.view_total_score = ANDER_SCORE
						answer_score.order = ANDER_SCORE
					end

				elsif question_composition != Settings.QUESTIONCOMPOSITIONCD_MULTIPLEONLY && exam.self_flag == Settings.GENERICPAGE_SELFFLG_NONE
					if answer_score.total_score && answer_score.total_score >= 0
            answer_score.view_total_score = answer_score.total_score.to_s + "/100"
					else
						answer_score.view_total_score = ANDER_SCORE
					end
				end

				answer_scores[exam.id] = answer_score

			else
				## 表示用のダミーを用意し、リストに追加する
        answer_score = AnswerScore.new
        answer_score.answer_count = 0
        answer_score.view_total_score = ANDER_SCORE
        answer_score.rank = ANDER_SCORE
        answer_score.average = ANDER_SCORE
        answer_score.max_score = ANDER_SCORE
				answer_scores[exam.id] = answer_score
			end
		end

		return answer_scores
  end

  def mark_exam(exam, uesr_answer_score)
    answer_scores = {}

		## 配点計算用
		calcurate = 0
		## 平均計算用
		average = 0
		## 順位計算用
		order = 1
		## 最高得点計算用
		maxScore = 0
		count = 0

		## すべての問題の配点の合計を算出
		exam.parent_questions.each do |parent|
			parent.questions.each do |question|
				calcurate += question.score
			end
		end

		## ユーザ毎の最後の解答を取得する。（（保存解答は対象外）
    latest_answers = exam.answer_scores.where("total_score > ?", Settings.ANSWERSCORE_TMP_SAVED_SCORE).order("answer_count DESC")
		latest_answers.each do |answer_score|
      next if answer_scores.key?(answer_score.user_id)

      answer_scores[answer_score.user_id] = answer_score
		end

    question_composition = exam.get_question_composition

		## 問題が選択式のみ、または記述式テストのとき
		if question_composition == Settings.QUESTIONCOMPOSITIONCD_MULTIPLEONLY ||
       exam.type_cd == Settings.GENERICPAGE_TYPECD_MULTIPLEFIBCODE


			answer_scores.each do |key, answer_score|
				if answer_score.total_score > maxScore
					maxScore = answer_score.total_score
				end
				average += answer_score.total_score
				count += 1

        next if key == uesr_answer_score.user_id

				if !uesr_answer_score.total_score.blank? && uesr_answer_score.total_score >= 0
					if uesr_answer_score.total_score < answer_score.total_score
						## 順位の変動
						order += 1
					end
        elsif !uesr_answer_score.self_total_score.blank? && uesr_answer_score.self_total_score >= 0
          if uesr_answer_score.self_total_score < answer_score.total_score
						## 順位の変動
						order += 1
					end
				end
			end
		end

		## 問題が複合式か記述のみかつ自己採点ありのとき
		if question_composition != Settings.QUESTIONCOMPOSITIONCD_MULTIPLEONLY &&
			 (exam.self_flag == Settings.GENERICPAGE_SELFFLG_SELF ||
				exam.self_flag == Settings.GENERICPAGE_SELFFLG_MUTUAL ||
				exam.self_flag == Settings.GENERICPAGE_SELFFLG_MUTUAL2)

			answer_scores.each do |key, answer_score|
        if !answer_score.total_score.blank? && answer_score.total_score >= 0
          if answer_score.total_score > maxScore
						maxScore = answer_score.total_score
					end
					average += answer_score.total_score
					count += 1

          if !uesr_answer_score.total_score.blank? && uesr_answer_score.total_score >= 0
            if uesr_answer_score.total_score < answer_score.total_score
  						## 順位の変動
  						order += 1
  					end
          elsif !uesr_answer_score.self_total_score.blank? && uesr_answer_score.self_total_score >= 0
             if uesr_answer_score.self_total_score < answer_score.total_score
   						## 順位の変動
   						order += 1
   					end
   				end
				elsif !answer_score.self_total_score.blank? && answer_score.self_total_score >= 0
					if answer_score.self_total_score > maxScore
						maxScore = answer_score.self_total_score
					end
					average += answer_score.self_total_score
					count += 1

          if !uesr_answer_score.total_score.blank? && uesr_answer_score.total_score >= 0
						if uesr_answer_score.total_score < answer_score.self_total_score
							## 順位の変動
							order += 1
						end
          elsif !uesr_answer_score.self_total_score.blank? && uesr_answer_score.self_total_score >= 0
						if uesr_answer_score.self_total_score < answer_score.self_total_score
              ## 順位の変動
							order += 1
						end
					end
				end
			end
		end

		## 問題が複合式か記述のみかつ自己採点なしのとき
		if question_composition != Settings.QUESTIONCOMPOSITIONCD_MULTIPLEONLY && exam.self_flag == Settings.GENERICPAGE_SELFFLG_NONE
      answer_scores.each do |key, answer_score|
        if !answer_score.total_score.blank? && answer_score.total_score >= 0
          if answer_score.total_score > maxScore
						maxScore = answer_score.total_score
					end
					average += answer_score.total_score
					count += 1

          if !uesr_answer_score.total_score.blank? && uesr_answer_score.total_score >= 0
						if uesr_answer_score.total_score < answer_score.total_score
              ## 順位の変動
							order += 1
						end
					end
				end
			end

		end

		if uesr_answer_score.total_score < 0 && exam.self_flag == Settings.GENERICPAGE_SELFFLG_NONE
      uesr_answer_score.average = ANDER_SCORE
      uesr_answer_score.rank = ANDER_SCORE
      uesr_answer_score.max_score = ANDER_SCORE

		else

			if count != 0
				if average < 0
          uesr_answer_score.average = ANDER_SCORE
          uesr_answer_score.rank = ANDER_SCORE
          uesr_answer_score.max_score = ANDER_SCORE
				else
          uesr_answer_score.average = (average / count).round
          uesr_answer_score.rank = order
          uesr_answer_score.max_score = maxScore
				end
			else
        uesr_answer_score.average = ANDER_SCORE
        uesr_answer_score.rank = ANDER_SCORE
        uesr_answer_score.max_score = ANDER_SCORE
			end
		end
  end
end
