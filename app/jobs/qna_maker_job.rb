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

class QnaMakerJob < ApplicationJob
  queue_as :default

  def perform(*args)
    qna_responses = []

    begin
      qna_request = args[0]
      user_id = args[1]
      response = qna_question(qna_request.question, qna_request.user)

      if response['answers']
        response['answers'].each do |answer|
          qna_response = QnaResponse.new(qna_request_id: qna_request.id, answer: answer['answer'], score: answer['score'])
          qna_response.save

          qna_responses << qna_response if qna_response.score >= Settings.SCORE_THRESHOLD.to_i
        end
      end

    rescue => e
      qna_response = QnaResponse.new(qna_request_id: qna_request.id, answer: e.message, score: 0)
      qna_response.save
      qna_responses << qna_response
    end

    MessageCastJob.perform_later(qna_responses, user_id)
  end

  def get_response(uri, req)
    begin
      response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
        http.open_timeout = 30
        http.read_timeout = 30
        http.request(req)
      end

      case response
      when Net::HTTPSuccess
        response = JSON.parse(response.body)

      when Net::HTTPRedirection
        location = response['location']
        warn "redirected to #{location}"
        uri = URI.parse(location)
        get_json(location, req, limit - 1)

      else
        raise response.value

      end

    rescue => e
      raise [e.class, e].join(" : ")
    end

    response
  end

  def qna_question(question_text, user, limit = 10)
    response_text = ""

    knowledgebase = Settings.qna_maker.knowledgebase
    if user.student?
      settings_strict_filters = Settings.qna_maker.strict_filters.student
    else
      settings_strict_filters = Settings.qna_maker.strict_filters.teacher
    end

    url = "#{Settings.qna_maker.host}/knowledgebases/#{knowledgebase}/generateAnswer"
    uri = URI.parse(url)

    request = Net::HTTP::Post.new(uri.path)
    # Request headers
    request['Content-Type'] = 'application/json'
    # Request headers
    request['Authorization'] = "EndpointKey #{Settings.qna_maker.endpoint_key}"
    # strictFilters
    strict_filters = []
    settings_strict_filters.each do |key, value|
      strict_filters.push({"name" => key, "value" => value})
    end
    # Request body
    if strict_filters.length > 0
      request.body = {"question" => question_text, "top" => limit, "userId" => "openceas_user_#{user.id}", "strictFilters" => strict_filters}.to_json
    else
      request.body = {"question" => question_text, "top" => limit, "userId" => "openceas_user_#{user.id}"}.to_json
    end

    uri = URI.parse(url)
    begin
      response = get_response(uri, request)
      response_text = response

    rescue => e
      response_text = e.message
    end

    response_text
  end
end
