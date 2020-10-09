require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'バリデーション' do
    before do
      @user = build(:student_user)
    end

    it "正常" do
      @user.valid?
      expect(@user.errors.count).to eq 0
      expect(@user).to be_valid
    end

    it "氏名" do
      @user.user_name = nil
      @user.valid?
      expect(@user.errors.messages[:base]).to include I18n.t("admin.user.PRI_ADM_USR_REGISTERUST_ERROR1")
    end

    it "アカウント" do
      @user.account = nil
      @user.valid?
      expect(@user.errors.messages[:base]).to include I18n.t("admin.user.PRI_ADM_USR_REGISTERUST_ERROR2")

      other_user = create(:student_user, account: "spec_user")
      @user.account = "spec_user"
      @user.valid?
      expect(@user.errors.messages[:base]).to include I18n.t("admin.user.PRI_ADM_USR_REGISTERUST_ERROR9")
    end

    it "パスワード" do
      @user.password = nil
      @user.valid?
      expect(@user.errors.messages[:base]).to include I18n.t("admin.user.PRI_ADM_USR_REGISTERUST_ERROR3")

      @user.password = "12345"
      @user.valid?
      expect(@user.errors.messages[:base]).to include I18n.t("admin.user.PRI_ADM_USR_REGISTERUST_ERROR6")


      @user.password = "123456"
      @user.valid?
      expect(@user.errors.messages[:base].empty?).to eq true

      @user.password = "1" * 128
      @user.valid?
      expect(@user.errors.messages[:base].empty?).to eq true

      @user.password = "1" * 129
      @user.valid?
      expect(@user.errors.messages[:base]).to include I18n.t("admin.user.PRI_ADM_USR_REGISTERUST_ERROR6")
    end

    it "メールアドレス" do
      @user.email = ""
      @user.valid?
      expect(@user.errors.count).to eq 0

      @user.email = "12345"
      @user.valid?
      expect(@user.errors.messages[:base]).to include I18n.t("admin.user.PRI_ADM_USR_REGISTERUST_ERROR7")

      other_user = create(:student_user, email: "spec_user@test.co.jp")
      @user.email = "spec_user@test.co.jp"
      @user.valid?
      expect(@user.errors.messages[:email]).to include I18n.t("views.message.exist", item: "")
    end

    it "誕生日" do
      @user.birth_date = "1995/10/08"
      @user.valid?
      expect(@user.errors.count).to eq 0

      @user.birth_date = "2000/99/99"
      @user.valid?
      expect(@user.errors.messages[:base]).to include I18n.t("admin.user.PRI_ADM_USR_REGISTERUST_ERROR8")
    end

    it "性別" do
      @user.sex_cd = "1"
      @user.valid?
      expect(@user.errors.count).to eq 0

      @user.sex_cd = ""
      @user.valid?
      expect(@user.errors.messages[:base]).to include I18n.t("admin.user.PRI_ADM_USR_REGISTERUST_ERROR10")
    end
  end

  describe '更新処理' do
    before do
      @user = create(:student_user, password: "111111")
    end

    context 'パスワード更新' do
      context "失敗" do
        it "未入力" do
          params = {password: "", password_confirmation: "", current_password: ""}
          @user.update_with_password(params)
          expect(@user.errors.messages[:base]).to include I18n.t("change_personal_data.PRI_ADM_USR_CHANGEPERSONALDATA_ERRORTYPE1")
        end

        it "パスワード未入力" do
          params = {password: "", password_confirmation: "", current_password: "111111"}
          @user.update_with_password(params)
          expect(@user.errors.messages[:base]).to include I18n.t("change_personal_data.PRI_ADM_USR_CHANGEPERSONALDATA_ERRORTYPE2")
        end

        it "パスワード桁数" do
          params = {password: "12345", password_confirmation: "", current_password: "111111"}
          @user.update_with_password(params)
          expect(@user.errors.messages[:base]).to include I18n.t("change_personal_data.PRI_ADM_USR_CHANGEPERSONALDATA_ERRORTYPE10")
        end

        it "パスワード桁数" do
          params = {password: "1" * 257, password_confirmation: "", current_password: "111111"}
          @user.update_with_password(params)
          expect(@user.errors.messages[:base]).to include I18n.t("change_personal_data.PRI_ADM_USR_CHANGEPERSONALDATA_ERRORTYPE10")
        end

        it "現行パスワード未入力" do
          params = {password: "1" * 256, password_confirmation: "1" * 256, current_password: ""}
          @user.update_with_password(params)
          expect(@user.errors.messages[:base]).to include I18n.t("change_personal_data.PRI_ADM_USR_CHANGEPERSONALDATA_ERRORTYPE1")

          params = {password: "123456", password_confirmation: "123456", current_password: ""}
          @user.update_with_password(params)
          expect(@user.errors.messages[:base]).to include I18n.t("change_personal_data.PRI_ADM_USR_CHANGEPERSONALDATA_ERRORTYPE1")
        end

        it "確認パスワード不一致" do
          params = {password: "123456", password_confirmation: "123457", current_password: "111111"}
          @user.update_with_password(params)
          expect(@user.errors.messages[:base]).to include I18n.t("change_personal_data.PRI_ADM_USR_CHANGEPERSONALDATA_ERRORTYPE11")
        end
      end

      it "成功" do
        params = {password: "123456", password_confirmation: "123456", current_password: "111111"}
        @user.update_with_password(params)
        expect(@user.errors.count).to eq 0
      end
    end

    context 'email更新' do
      context "失敗" do
        it "未入力" do
          params = {new_email: "", email_confirmation: ""}
          @user.update_with_email(params)
          expect(@user.errors.messages[:base]).to include I18n.t("change_personal_data.PRI_ADM_USR_CHANGEPERSONALDATA_ERRORTYPE4")
        end

        it "メール形式誤り" do
          params = {new_email: "update", email_confirmation: "update"}
          @user.update_with_email(params)
          expect(@user.errors.messages[:base]).to include I18n.t("change_personal_data.PRI_ADM_USR_CHANGEPERSONALDATA_ERRORTYPE12")
        end

        it "確認パスワード不一致" do
          params = {new_email: "update@test.co.jp", email_confirmation: "notupdate@test.co.jp"}
          @user.update_with_email(params)
          expect(@user.errors.messages[:base]).to include I18n.t("change_personal_data.PRI_ADM_USR_CHANGEPERSONALDATA_ERRORTYPE14")
        end

        it "メールアドレス重複" do
          other_user = create(:student_user, email: "spec_user@test.co.jp", email_mobile: "spec_user_m@test.co.jp")
          params = {new_email: "spec_user@test.co.jp", email_confirmation: "spec_user@test.co.jp"}
          @user.update_with_email(params)
          expect(@user.errors.messages[:base]).to include I18n.t("views.message.exist", item: I18n.t("activerecord.attributes.user.email"))

          params = {new_email: "spec_user_m@test.co.jp", email_confirmation: "spec_user_m@test.co.jp"}
          @user.update_with_email(params)
          expect(@user.errors.messages[:base]).to include I18n.t("views.message.exist", item: I18n.t("activerecord.attributes.user.email"))
        end
      end

      it "成功" do
        params = {new_email: "update@test.co.jp", email_confirmation: "update@test.co.jp"}
        @user.update_with_email(params)
        expect(@user.errors.count).to eq 0
      end
    end

    context 'update_with_email_mobile更新' do
      context "失敗" do
        it "未入力" do
          params = {new_email_mobile: "", email_mobile_confirmation: ""}
          @user.update_with_email_mobile(params)
          expect(@user.errors.messages[:base]).to include I18n.t("change_personal_data.PRI_ADM_USR_CHANGEPERSONALDATA_ERRORTYPE6")
        end

        it "メール形式誤り" do
          params = {new_email_mobile: "update", email_mobile_confirmation: "update"}
          @user.update_with_email_mobile(params)
          expect(@user.errors.messages[:base]).to include I18n.t("change_personal_data.PRI_ADM_USR_CHANGEPERSONALDATA_ERRORTYPE13")
        end

        it "確認パスワード不一致" do
          params = {new_email_mobile: "update@test.co.jp", email_mobile_confirmation: "notupdate@test.co.jp"}
          @user.update_with_email_mobile(params)
          expect(@user.errors.messages[:base]).to include I18n.t("change_personal_data.PRI_ADM_USR_CHANGEPERSONALDATA_ERRORTYPE15")
        end

        it "メールアドレス重複" do
          other_user = create(:student_user, email: "spec_user@test.co.jp", email_mobile: "spec_user_m@test.co.jp")
          params = {new_email_mobile: "spec_user@test.co.jp", email_mobile_confirmation: "spec_user@test.co.jp"}
          @user.update_with_email_mobile(params)
          expect(@user.errors.messages[:base]).to include I18n.t("views.message.exist", item: I18n.t("activerecord.attributes.user.email_mobile"))

          params = {new_email_mobile: "spec_user_m@test.co.jp", email_mobile_confirmation: "spec_user_m@test.co.jp"}
          @user.update_with_email_mobile(params)
          expect(@user.errors.messages[:base]).to include I18n.t("views.message.exist", item: I18n.t("activerecord.attributes.user.email_mobile"))
        end
      end

      it "成功" do
        params = {new_email_mobile: "update@test.co.jp", email_mobile_confirmation: "update@test.co.jp"}
        @user.update_with_email_mobile(params)
        expect(@user.errors.count).to eq 0
      end
    end

    context 'email登録' do
      context "失敗" do
        it "未入力" do
          params = {new_email: "", email_confirmation: ""}
          @user.update_unset_email(params)
          expect(@user.errors.messages[:base]).to include I18n.t("login.LOG_REGISTERMAIL_JAVASCRIPT1")
        end

        it "メール形式誤り" do
          params = {new_email: "update", email_confirmation: "update"}
          @user.update_unset_email(params)
          expect(@user.errors.messages[:base]).to include I18n.t("login.LOG_REGISTERMAIL_JAVASCRIPT3")
        end

        it "確認パスワード不一致" do
          params = {new_email: "update@test.co.jp", email_confirmation: "notupdate@test.co.jp"}
          @user.update_unset_email(params)
          expect(@user.errors.messages[:base]).to include I18n.t("login.LOG_REGISTERMAIL_JAVASCRIPT5")
        end
      end

      it "成功" do
        params = {new_email: "update@test.co.jp", email_confirmation: "update@test.co.jp"}
        @user.update_unset_email(params)
        expect(@user.errors.count).to eq 0
      end
    end
  end

  context 'コース追加・削除' do
    let(:teacher) { create(:teacher_user) }
    let(:student) { create(:student_user) }

    before do
      @courses = create_list(:course, 4, :year_of_2019)

      @params = {
        user_name: "add user",
        kana_name: "add user",
        email: "adduser@test.co.jp",
        email_mobile: "",
        sex_cd: "1",
        account: "adduser",
        password: "hogehoge",
        role_id: teacher.role_id,
        add_courses: [@courses[0].id, @courses[1].id, @courses[2].id],
        delete_courses: []
      }
    end

    context 'ユーザ新規追加' do
      it "担任者" do
        new_user = User.new(@params)
        expect{
          new_user.save
        }.to change(User, :count).by(1)

        expect(new_user.assigned_courses.count).to eq 3
      end

      it "生徒" do
        @params["role_id"] = student.role_id
        new_user = User.new(@params)
        expect{
          new_user.save
        }.to change(User, :count).by(1)

        expect(new_user.enrollment_courses.count).to eq 3
      end
    end

    context 'ユーザ更新' do
      it "担任者" do
        user = User.new(@params)

        expect{
          user.save(@params)
        }.to change(User, :count).by(1)

        expect(user.assigned_courses.count).to eq 3

        @params["add_courses"] = [@courses[3].id]
        @params["delete_courses"] = [@courses[0].id, @courses[2].id]
        expect{
          user.update(@params)
        }.to change(User, :count).by(0)

        expect(user.assigned_courses.count).to eq 2
      end

      it "生徒" do
        @params["role_id"] = student.role_id
        user = User.new(@params)

        expect{
          user.update(@params)
        }.to change(User, :count).by(1)

        expect(user.enrollment_courses.count).to eq 3

        @params["add_courses"] = [@courses[3].id]
        @params["delete_courses"] = [@courses[0].id, @courses[2].id]
        expect{
          user.update(@params)
        }.to change(User, :count).by(0)

        expect(user.enrollment_courses.count).to eq 2
      end
    end
  end
end