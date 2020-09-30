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

RSpec.describe "Users", type: :request do
  before :all do
    FactoryBot.create_list(:user, 4, :teacher)
    FactoryBot.create_list(:user, 5, :student)
    FactoryBot.create(:user, :teacher, account: "account_a", user_name: "user_name_a")
    FactoryBot.create(:user, :teacher, account: "account_b", user_name: "user_name_b")
    FactoryBot.create(:user, :teacher, account: "account_c", user_name: "test taro")
    FactoryBot.create(:user, :teacher, account: "account_d", user_name: "test jiro")
    FactoryBot.create(:user, :student, account: "account_e", user_name: "user_name_e")
    FactoryBot.create(:user, :student, account: "account_f", user_name: "user_name_f")
    FactoryBot.create(:user, :student, account: "account_g", user_name: "test taro")
    FactoryBot.create(:user, :student, account: "account_h", user_name: "test jiro")
  end

  describe "get /api/v1/users" do
    before do
      authenticate
      get '/api/v1/users', headers: @headers
      @json = JSON.parse(response.body)
    end

    it 'status OK' do
      expect(response).to be_successful
      expect(response.status).to eq 200
    end

    it '全件取得できる' do
      expect(JSON.parse(response.body).count).to eq 18
    end
  end

  describe "get /api/v1/users?account=account" do
    before do
      authenticate
      get '/api/v1/users?account=account', headers: @headers
      @json = JSON.parse(response.body)
    end

    it '取得件数' do
      expect(JSON.parse(response.body).count).to eq 8
    end
  end

  describe "get /api/v1/users?user_name=user_name" do
    before do
      authenticate
      get '/api/v1/users?user_name=user_name', headers: @headers
      @json = JSON.parse(response.body)
    end

    it '取得件数' do
      expect(JSON.parse(response.body).count).to eq 4
    end
  end

  describe "get /api/v1/users?user_name=user_name&role=2" do
    before do
      authenticate
      get '/api/v1/users?user_name=user_name&role=2', headers: @headers
      @json = JSON.parse(response.body)
    end

    it '取得件数' do
      expect(JSON.parse(response.body).count).to eq 2
    end
  end

  describe "get /api/v1/users?account=account&user_name=test taro" do
    before do
      authenticate
      get '/api/v1/users?account=account&user_name=test taro', headers: @headers
      @json = JSON.parse(response.body)
    end

    it '取得件数' do
      expect(JSON.parse(response.body).count).to eq 2
    end
  end

  describe "get /api/v1/users?account=account&user_name=test taro&role=2" do
    before do
      authenticate
      get '/api/v1/users?account=account&user_name=test taro&role=2s', headers: @headers
      @json = JSON.parse(response.body)
    end

    it '取得件数' do
      expect(JSON.parse(response.body).count).to eq 1
    end
  end

  describe "get /api/v1/user/:id" do
    before do
      authenticate
      get '/api/v1/user/1', headers: @headers
      @json = JSON.parse(response.body)
    end

    it 'status OK' do
      expect(response).to be_successful
      expect(response.status).to eq 200
    end

    it '取得したデータ' do
      expect(@json["user_name"]).to eq "admin"
    end
  end
end
