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

RSpec.describe UsersController, type: :controller do
  describe 'User管理' do
    let(:user) { create_list(:user, 1, :teacher)[0] }

    before do
      sign_in user
    end

    it "初期表示" do
      get :index

      expect(response).to render_template("index")
    end

    context "パスワード更新" do
      it "失敗：必須項目空値" do
        post :update_password, params: { user: attributes_for(:user, 
          password: "hogehoge123", password_confirmation: "", current_password: "hogehoge", updated_type: User::UPDATED_TYPE_PASSWORD
        ) }

        expect(response).to render_template("index")
      end

      it "成功：画面遷移" do
        post :update_password, params: { user: attributes_for(:user, 
          password: "hogehoge123", password_confirmation: "hogehoge123", current_password: "hogehoge", updated_type: User::UPDATED_TYPE_PASSWORD
        ) }
      
        expect(response).to redirect_to users_path
      end
    end

    context "メール１更新" do
      it "失敗：必須項目空値" do
        post :update_email, params: { user: attributes_for(:user, 
          new_email: "updatemail@test.co.jp", email_confirmation: "", updated_type: User::UPDATED_TYPE_EMAIL
        ) }

        expect(response).to render_template("index")
      end

      it "成功" do
        post :update_email, params: { user: attributes_for(:user, 
          new_email: "updatemail@test.co.jp", email_confirmation: "updatemail@test.co.jp", updated_type: User::UPDATED_TYPE_EMAIL
        ) }
      
        user.reload
        expect(user.email).to eq("updatemail@test.co.jp")
        expect(response).to render_template("index")
      end
    end

    context "メール２更新" do
      it "失敗：必須項目空値" do
        post :update_email_mobile, params: { user: attributes_for(:user, 
          new_email_mobile: "updatemail@test.co.jp", email_mobile_confirmation: "", updated_type: User::UPDATED_TYPE_EMAIL_MOBILE
        ) }

        expect(response).to render_template("index")
      end

      it "成功" do
        post :update_email_mobile, params: { user: attributes_for(:user, 
          new_email_mobile: "updatemail@test.co.jp", email_mobile_confirmation: "updatemail@test.co.jp", updated_type: User::UPDATED_TYPE_EMAIL_MOBILE
        ) }
      
        user.reload
        expect(user.email_mobile).to eq("updatemail@test.co.jp")
        expect(response).to render_template("index")
      end

      it "削除成功" do
        post :update_email_mobile, params: { user: attributes_for(:user, 
          new_email_mobile: "updatemail@test.co.jp", email_mobile_confirmation: "updatemail@test.co.jp", updated_type: User::UPDATED_TYPE_EMAIL_MOBILE
        ) }
      
        user.reload
        expect(user.email_mobile).to eq("updatemail@test.co.jp")

        delete :delete_email_mobile, params: { id: user }

        user.reload
        expect(user.email_mobile).to eq("")

        expect(response).to render_template("index")
      end
    end

    context "ロケール更新" do
      it "成功" do
        post :update_locale, params: { user: attributes_for(:user, 
          locale: "en"
        ) }
      
        user.reload
        expect(user.locale).to eq("en")

        post :update_locale, params: { user: attributes_for(:user, 
          locale: "ja"
        ) }
      
        user.reload
        expect(user.locale).to eq("ja")
        
        expect(response).to redirect_to users_path
      end
    end
  end
end
