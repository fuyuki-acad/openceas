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

RSpec.describe "Courses", type: :request do
  before do
    FactoryBot.create_list(:course, 5, :year_of_2018)
    FactoryBot.create_list(:course, 5, :year_of_2019)
  end

  describe "get /api/v1/courses" do
    before do
      authenticate
      get '/api/v1/courses', headers: @headers
      @json = JSON.parse(response.body)
    end

    it 'status OK' do
      expect(response).to be_successful
      expect(response.status).to eq 200
    end

    it '全件取得できる' do
      expect(JSON.parse(response.body).count).to eq 10
    end
  end

  describe "get /api/v1/courses?school_year=2019" do
    before do
      authenticate

      get '/api/v1/courses?school_year=2019', headers: @headers
      @json = JSON.parse(response.body)
    end

    it 'status OK' do
      expect(response).to be_successful
      expect(response.status).to eq 200
    end

    it '取得件数' do
      expect(JSON.parse(response.body).count).to eq 5
    end

    it '取得したデータ' do
      @json.each do |data|
        expect(data["school_year"]).to eq 2019
      end
    end
  end

  describe "get /api/v1/course/:id" do
    before do
      authenticate

      @course = Course.all.first
      get "/api/v1/course/#{@course.id}", headers: @headers
      @json = JSON.parse(response.body)
    end

    it 'status OK' do
      expect(response).to be_successful
      expect(response.status).to eq 200
    end

    it '取得したデータ' do
      expect(@json["id"]).to eq @course.id
    end
  end
end
