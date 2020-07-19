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

class ResultsController < ApplicationController
  include MarkModule

  before_action :require_enrolled
  before_action :set_course, only: [:index]

  def index
    @answer_scores = get_answers_scores(@course, current_user)
    @all_exam_count = @answer_scores.count
    @finished_exam_count = 0
    finished_exams = @answer_scores.values.map do |answer_score|
      @finished_exam_count += 1 unless answer_score.id.nil?
    end
    @progress = @all_exam_count == 0 ? 0 : @finished_exam_count * 100 / @all_exam_count

    evaluation_answer_scores = AnswerScore.where("user_id = ? AND page_id IN (?)", current_user.id, @course.evaluations.select("id"))
    @comments = AssignmentEssayComment.where("answer_score_id IN (?)", evaluation_answer_scores.select("id"))
  end

  def show
    @generic_page = Compound.find(params[:id])
    @answer_scores = @generic_page.answer_scores.where("user_id = ? AND total_score >= 0", current_user.id)

    @latest_score = @generic_page.answer_scores.where("user_id = ? AND total_score >= 0", current_user.id).order("answer_count DESC").first

    ## 成績の計算
    mark_exam(@generic_page, @latest_score)

		## テストの満点スコアを取得
		testScore = 0

		questionTotalScore = 100

		## ?テストの設問のスコアの合計を取得
		@generic_page.parent_questions.each do |parent|
			parent.questions.each do |question|
				testScore += testScore + question.score
			end
		end

    ## グラフデータ
    make_graph_data(@generic_page)
  end

  private
    def make_graph_data(generic_page)
      scores = {}
      @chart_data = {0 => 0, 11 => 0, 21 => 0, 31 => 0, 41 => 0, 51 => 0, 61 => 0, 71 => 0, 81 => 0, 91 => 0}

  		## テスト結果リストを取得
      answer_scores = AnswerScore.where("page_id = ? AND total_score >= 0", generic_page.id).order("user_id ASC, answer_count DESC")
  		## 同じユーザの最後の解答以外削除
  		answer_scores.each do |answer_score|
        next if scores.key?(answer_score.user_id)
        scores[answer_score.user_id] = answer_score
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
    end
end
