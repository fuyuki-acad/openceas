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

RSpec.describe Admin::UsersController, type: :controller do
  describe 'Admin User管理' do
    before do
      @user = User.where(account: 'admin').first
      login_admin @user
    end

    it "初期表示" do
      get :index

      expect(response).to render_template(:index)
    end

    context "新規登録" do
      it "初期表示" do
        get :new
        
        expect(response).to render_template("new")
      end

      it "登録失敗：必須項目空値" do
        post :confirm, params: { user: attributes_for(:user, account: "", user_name: "", email: "", role_id: 2) }

        expect(response).to render_template("new")
      end

      it "登録成功" do
        post :confirm, params: { user: attributes_for(:user, 
          account: "testuser1", user_name: "test user1", email: "testuser1@hogehoge.co.jp", role_id: 2,
          name_no_prefix: "", sex_cd: 1, term_flag: 1, password: "hogehoge", delete_flag: 0
        ) }

        expect{
          post :create
        }.to change(User, :count).by(1)
      end

      it "確認画面" do
        post :confirm, params: { user: attributes_for(:user, 
          account: "testuser1", user_name: "test user1", email: "testuser1@hogehoge.co.jp", role_id: 2,
          name_no_prefix: "", sex_cd: 1, term_flag: 1, password: "hogehoge", delete_flag: 0
        ) }
      
        expect(response).to render_template("confirm")
      end
    end

    context "編集" do
      before do
        @edit_user = create(:test_user)
      end

      it "初期表示" do
        get :edit,  params: { id: @edit_user }
        
        expect(response).to render_template("edit")
      end

      it "更新失敗：必須項目空値" do
        post :confirm, params: { id: @edit_user, user: attributes_for(:user, account: "", user_name: "", email: "", role_id: 2) }

        expect(response).to render_template("edit")
      end

      it "更新成功" do
        post :confirm, params: { id: @edit_user, user: attributes_for(:user, 
          account: "testuser", user_name: "test user1", email: "testuser1@hogehoge.co.jp", role_id: 2,
          name_no_prefix: "", sex_cd: 1, term_flag: 1, password: "hogehoge", delete_flag: 0
        ) }

        post :update, params: { id: @edit_user }

        @edit_user.reload
        expect(@edit_user.user_name).to eq("test user1")
        expect(@edit_user.email).to eq("testuser1@hogehoge.co.jp")
      end

      it "確認画面" do
        post :confirm, params: { id: @edit_user, user: @edit_user.attributes }
      
        expect(response).to render_template("confirm")
      end
    end
  end
end
