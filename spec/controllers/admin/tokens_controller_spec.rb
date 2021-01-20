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

RSpec.describe Admin::TokensController, type: :controller do
  describe "トークン管理" do
    let(:token) { create(:admitted_token, :token_test) }

    before do
      @user = User.where(account: 'admin').first
      login_admin @user
    end
  
    it "初期表示" do
      get :index
      
      expect(response).to render_template("index")
    end

    context "新規登録" do
      it "初期表示" do
        get :new
        
        expect(response).to render_template("new")
      end

      it "登録失敗：必須項目空値" do
        post :create, params: { token: {description: "", expire_date: ""} }

        expect(response).to render_template("new")
      end

      it "登録成功" do
        expect{
          post :create, params: { token: attributes_for(:admitted_token, description: "test new token", expire_date: "") }
        }.to change(AdmittedToken, :count).by(1)
      end

      it "登録成功：画面遷移" do
        post :create, params: { token: attributes_for(:admitted_token, description: "test new token", expire_date: "") }
        
        expect(response).to redirect_to admin_tokens_path
      end
    end

    context "編集" do
      it "初期表示" do
        post :edit, params: { id: token.id }
        expect(assigns(:token)).to eq token
      end

      it "更新失敗：必須項目空値" do
        post :update, params: { id: token.id, token: {description: "", expire_date: ""} }
        
        expect(response).to render_template("edit")
      end

      it "更新成功" do
        post :update, params: { id: token.id, token: attributes_for(:admitted_token, description: "test update token", expire_date: "") }
        
        token.reload
        expect(token.description).to eq("test update token")
      end

      it "更新成功：画面遷移" do
        post :update, params: { id: token.id, token: attributes_for(:admitted_token, description: "test update token", expire_date: "") }
        
        expect(response).to redirect_to admin_tokens_path
      end
    end

    it "トークン再生成" do
      post :regenerate_token, params: { id: token.id }
      
      expect(response).to redirect_to admin_tokens_path
    end

    context "削除" do
      it "削除成功" do
        delete_token = create(:admitted_token, :token_test) 
        expect{
          post :destroy, params: { id: delete_token.id }
        }.to change(AdmittedToken, :count).by(-1)
      end

      it "削除成功：画面遷移" do
        post :destroy, params: { id: token.id }
        
        expect(response).to redirect_to admin_tokens_path
      end
    end
  end
end
