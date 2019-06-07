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

class Admin::SupportsController < ApplicationController
  def index
    @end_date = Time.zone.parse(Time.zone.now.strftime('%Y%m%d 00:00:00'))
    @start_date = @end_date.prev_month.tomorrow
    @results = get_results(@start_date, @end_date.tomorrow)
    @score_form = SupportScoreForm.new(start_date: @start_date, end_date: @end_date)
  end

  def monthly
    summary = {}
    today = Time.zone.parse(Time.zone.now.strftime('%Y%m01 00:00:00'))

    #monthly
    12.times do |count|
      target = today.ago(count.month)

      summary[I18n.l(target, format: :ym)] = QnaRequest.
        where(["updated_at >= ? and updated_at < ?", target, target.next_month]).count
    end

    render json: summary
  end

  def score
    chart_data = []
    chart_count = [0, 0, 0, 0, 0]

    end_date = Time.zone.parse(params[:end_date])
    start_date = Time.zone.parse(params[:start_date])
    results = QnaRequest.where(["qna_requests.updated_at >= ? AND qna_requests.updated_at < ? ", start_date, end_date.tomorrow])

    results.each do |result|
      max_score = result.max_score

      if max_score <= 20
        chart_count[0] += 1
      elsif max_score <= 40
        chart_count[1] += 1
      elsif max_score <= 60
        chart_count[2] += 1
      elsif max_score <= 60
        chart_count[3] += 1
      else
        chart_count[4] += 1
      end
    end

    chart_data << ["0 - 20", chart_count[0]]
    chart_data << ["20 - 40", chart_count[1]]
    chart_data << ["40 - 60", chart_count[2]]
    chart_data << ["60 - 80", chart_count[3]]
    chart_data << ["80 - 100", chart_count[4]]

    render json: chart_data
  end

  def refresh_score
    @score_form = SupportScoreForm.new(score_form_params)
    @score_form.valid?
  end

  def refresh_detail
    @datail_form = SupportDetailForm.new(detail_form_params)
    if @datail_form.valid?
      end_date = Time.zone.parse(@datail_form.end_date).tomorrow
      start_date = Time.zone.parse(@datail_form.start_date)
      end_score = @datail_form.end_score
      start_score = @datail_form.start_score
      page = params[:page]

      @results = get_results(start_date, end_date, start_score, end_score, page)
    end
  end

  private
    def get_results(start_date, end_date, start_score = 0, end_score = 100, page = 0)
      sql_params = {}
      sql_text = "SELECT qna_requests.*, max_score_response.max_score FROM qna_requests" +
        " LEFT JOIN (SELECT qna_request_id, max(qna_responses.score) AS max_score FROM qna_responses GROUP BY qna_request_id) max_score_response" +
        " ON qna_requests.id = max_score_response.qna_request_id" +
        " WHERE qna_requests.updated_at >= :start_date AND qna_requests.updated_at < :end_date"

      sql_params[:start_date] = start_date
      sql_params[:end_date] = end_date

      end_score = 100 if end_score.to_i == 0
      sql_text = sql_text + " AND (max_score_response.max_score <= :end_score"
      sql_params[:end_score] = end_score.to_i

      if start_score.to_i > 0
        sql_text = sql_text + " AND max_score_response.max_score >= :start_score)"
        sql_params[:start_score] = start_score
      else
        sql_text = sql_text + " OR max_score_response.max_score IS NULL)"
      end

      sql_text = sql_text + " ORDER BY max_score_response.max_score DESC"

      results = QnaRequest.find_by_sql([sql_text, sql_params])
      Kaminari.paginate_array(results).page(page).per(Settings.SCORE_LIST_PER_PAGE.to_i)
    end

    def score_form_params
      params.require(:support_score_form).permit(:start_date, :end_date)
    end

    def detail_form_params
      params.permit(:start_date, :end_date, :start_score, :end_score)
    end
end
