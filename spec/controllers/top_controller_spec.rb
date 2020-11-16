require 'rails_helper'

RSpec.describe TopController, type: :controller do
  describe 'Topページ' do
    before do
      @user = User.where(account: 'admin').first
      login_admin @user
    end

    it "index" do
      get :index

      expect(response).to render_template("index")
    end
  end
end
