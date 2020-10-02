require 'rails_helper'

RSpec.describe AnnouncementsController, type: :controller do
  let(:admin) { User.where(account: 'admin').first }
  let(:teacher) { create(:teacher_user) }
  let(:student) { create(:student_user) }

  before do
    course1 = create(:course, :year_of_2019, course_name: "検索コース名", course_cd: "course-2019", season_cd: 2, day_cd: 2)
    course2 = create(:course, :year_of_2019, season_cd: 3, day_cd: 3, hour_cd: 3)
    course3 = create(:course, :year_of_2019)

    create(:course_assigned_user, course_id: course1.id, user_id: teacher.id)
    create(:course_enrollment_user, course_id: course2.id, user_id: student.id)

    create_list(:announcement, 3, course_id: course1.id)
    create_list(:announcement, 5, course_id: course2.id)
    create_list(:announcement, 6, course_id: course3.id)
  end

  describe 'お知らせ' do
    context "管理者ユーザ" do
      before do
        sign_in admin
      end

      it "初期表示" do
        get :index

        expect(assigns(:announcements).count).to eq 14
        expect(response).to render_template("index")
      end
    end

    context "担任者ユーザ" do
      before do
        sign_in teacher
      end

      it "初期表示" do
        get :index

        expect(assigns(:announcements).count).to eq 3
        expect(response).to render_template("index")
      end
    end

    context "生徒ユーザ" do
      before do
        sign_in student
      end

      it "初期表示" do
        get :index

        expect(assigns(:announcements).count).to eq 5
        expect(response).to render_template("index")
      end
    end
  end
end