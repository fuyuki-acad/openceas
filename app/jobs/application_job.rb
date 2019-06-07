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

class ApplicationJob < ActiveJob::Base
  queue_as :default

  def perform(content, user_id, session_id)
    setup_ai

    begin
      response = @client.text_request(content)
      response_text = set_output_text(response)

    rescue => e
      response_text = e.message
    end

    conversation = Conversation.new(content: response_text, user_id: user_id)
    conversation.save

    MessageCastJob.perform_later conversation, session_id
  end

  def setup_ai
    @client = ApiAiRuby::Client.new(
        :client_access_token => Settings.config.api_ai.token
    )
  end

  def set_output_text(response)
    output = response[:result][:fulfillment][:speech] if response[:result][:fulfillment][:speech]
    output
  end
end
