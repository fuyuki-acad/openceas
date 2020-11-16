require 'rails_helper'

RSpec.describe Admin::GeneralAnnouncementsController, type: :controller do
  describe 'Admin 告知機能' do
    before do
      @user = User.where(account: 'admin').first
      login_admin @user

      create_list(:general_announcement, 5)
    end

    it "初期表示" do
      get :index

      expect(assigns(:announcements).to_a.count).to eq 5
      expect(response).to render_template("index")
    end

    context "新規登録" do
      it "初期表示" do
        get :index
        
        expect(response).to render_template("index")
      end

      it "登録失敗：項目空値" do
        post :create, params: { announcement: attributes_for(:general_announcement,
          title: "", content: "", type_cd: ""
        ) }

        expect(response).to render_template("index")
      end

      it "登録成功" do
        expect{
          post :create, params: { announcement: attributes_for(:general_announcement,
            title: "announcement title", content: "announcement content", type_cd: GeneralAnnouncement::TYPE_LOGIN
          ) }
        }.to change(GeneralAnnouncement, :count).by(1)

        expect(response).to redirect_to admin_general_announcements_path
      end
    end

    context "編集" do
      before do
        @announcement = create(:general_announcement)
      end

      it "初期表示" do
        get :edit,  params: { id: @announcement }
        
        expect(response).to render_template("edit")
      end

      it "更新失敗：必須項目空値" do
        post :update, params: { id: @announcement, announcement: attributes_for(:general_announcement,
          title: "", content: "", type_cd: ""
        ) }

        expect(response).to render_template("edit")
      end

      it "更新成功" do
        patch :update, params: { id: @announcement, announcement: attributes_for(:general_announcement, 
          title: "update announcement title", content: "update announcement content", type_cd: GeneralAnnouncement::TYPE_LOGIN
        ) }

        @announcement.reload
        expect(@announcement.title).to eq("update announcement title")
        expect(@announcement.content).to eq("update announcement content")

        expect(response).to redirect_to admin_general_announcements_path
      end
    end

    context "削除" do
      before do
        @announcement1 = create(:general_announcement)
        @announcement2 = create(:general_announcement)
        @announcement3 = create(:general_announcement)
      end

      it "成功" do
        expect{
          delete :destroy, params: { announcement: { @announcement1.id => @announcement1.id, @announcement2.id => @announcement2.id } }
        }.to change(GeneralAnnouncement, :count).by(-2)

        expect(response).to redirect_to admin_general_announcements_path
      end
    end
  end
end