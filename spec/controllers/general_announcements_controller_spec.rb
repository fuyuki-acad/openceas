require 'rails_helper'

RSpec.describe GeneralAnnouncementsController, type: :controller do
  let(:teacher) { create(:teacher_user) }

  before do
    sign_in teacher
  end

  describe 'システム情報' do
    before do
      create_list(:general_announcement, 3)
    end

    it "初期表示" do
      get :index

      expect(assigns(:general_announcements).count).to eq 3
      expect(response).to render_template("index")
    end
  end
end