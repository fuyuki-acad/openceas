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

require 'rails_helper'

RSpec.describe "ClassSession", type: :request do
  before do
    FactoryBot.create(:course, :year_of_2018, id: 1)
    FactoryBot.create(:class_session, course_id: 1, class_session_no: 0)
    FactoryBot.create(:class_session, course_id: 1, class_session_no: 1)
    FactoryBot.create(:class_session, course_id: 1, class_session_no: 2)
    FactoryBot.create(:class_session, course_id: 1, class_session_no: 3)
    FactoryBot.create(:class_session, course_id: 1, class_session_no: 4)
    FactoryBot.create(:class_session, course_id: 1, class_session_no: 5)
    FactoryBot.create(:course, :year_of_2018, id: 2)
    FactoryBot.create(:class_session, course_id: 2, class_session_no: 0)
    FactoryBot.create(:class_session, course_id: 2, class_session_no: 1)
  end

  describe "get /api/v1/class_sessions/:course_id" do
    before do
      authenticate
      get '/api/v1/class_sessions/1', headers: @headers
      @json = JSON.parse(response.body)
    end

    it 'status OK' do
      expect(response).to be_successful
      expect(response.status).to eq 200
    end

    it '全件取得できる' do
      expect(JSON.parse(response.body).count).to eq 6
    end
  end

  after do
    Course.destroy_all
  end
end
