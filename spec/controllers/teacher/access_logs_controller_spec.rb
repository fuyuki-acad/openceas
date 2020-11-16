require 'rails_helper'

RSpec.describe Teacher::AccessLogsController, type: :controller do
  let(:teacher) { create(:teacher_user) }

  describe 'Admin アクセスログ' do
    before do
      sign_in teacher

      # アクセスログ
      @course1 = create(:course, :year_of_2019, course_name: "検索コース名", course_cd: "course-2019", instructor_name: "検索担任者名")
      @course2 = create(:course, :year_of_2019, course_name: "検索コース名", course_cd: "course-2019", season_cd: 2, day_cd: 2)
      @course3 = create(:course, :year_of_2019, season_cd: 3, day_cd: 3, hour_cd: 3)

      create(:course_assigned_user, course_id: @course1.id, user_id: teacher.id)
      create(:course_assigned_user, course_id: @course2.id, user_id: teacher.id)
  
      create_list(:course_access_log, 1, course_id: @course1.id, user_id: teacher.id, ip: "192.168.0.1")
      create_list(:course_access_log, 2, course_id: @course2.id, user_id: teacher.id, ip: "192.168.0.1")

      other_teacher = create(:user, :teacher)
      create_list(:course_access_log, 3, course_id: @course1.id, user_id: other_teacher.id, ip: "192.168.0.2")
      create_list(:course_access_log, 4, course_id: @course2.id, user_id: other_teacher.id, ip: "192.168.0.2")

      student1 = create(:user, :student)
      create_list(:course_access_log, 5, course_id: @course1.id, user_id: student1.id, ip: "192.168.0.3")
      create_list(:course_access_log, 6, course_id: @course3.id, user_id: student1.id, ip: "192.168.0.3")

      student2 = create(:user, :student)
      create_list(:course_access_log, 7, course_id: @course1.id, user_id: student2.id, ip: "192.168.0.3")
      create_list(:course_access_log, 8, course_id: @course3.id, user_id: student2.id, ip: "192.168.0.3")
    end

    it "初期表示" do
      get :index

      expect(response).to render_template("index")
    end

    context "アクセスログ" do
      it "検索1" do
        get :index, params: { type: @course1.id }

        expect(assigns(:logs).to_a.count).to eq 16
        expect(response).to render_template("index")
      end

      it "検索2" do
        get :index, params: { type: @course2.id }

        expect(assigns(:logs).to_a.count).to eq 6
        expect(response).to render_template("index")
      end

      it "検索3" do
        get :index, params: { type: @course3.id }

        expect(response.status).to eq 403
      end
    end
  end
end