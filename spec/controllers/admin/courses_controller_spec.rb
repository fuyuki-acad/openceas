require 'rails_helper'

RSpec.describe Admin::CoursesController, type: :controller do
  describe 'Admin 科目管理' do
    before do
      @user = User.where(account: 'admin').first
      login_admin @user

      create_list(:course, 2, :year_of_2018)
      create_list(:course, 2, :year_of_2018, instructor_name: "担任 太郎")
      create_list(:course, 2, :year_of_2018, season_cd: 2, day_cd: 2)
      create_list(:course, 2, :year_of_2018, season_cd: 3, day_cd: 3, hour_cd: 3)
      create_list(:course, 2, :year_of_2019)
      create_list(:course, 2, :year_of_2019, instructor_name: "担任 太郎")
      create_list(:course, 2, :year_of_2019, season_cd: 2, day_cd: 2)
      create_list(:course, 2, :year_of_2019, season_cd: 3, day_cd: 3, hour_cd: 3)
    end

    context "index" do
      it "初期表示" do
        get :index

        expect(assigns(:courses).count).to eq 16
        expect(response).to render_template("index")
      end

      it "検索1" do
        get :index, params: { type1: "0", keyword: "course 2019", hour: "3" }

        expect(assigns(:courses).to_a.count).to eq 2
        expect(response).to render_template("index")
      end

      it "検索2" do
        get :index, params: { type1: "2", keyword: "2018", season: "1" }

        expect(assigns(:courses).to_a.count).to eq 4
        expect(response).to render_template("index")
      end

      it "検索3" do
        get :index, params: { type1: "1", keyword: "担任 太郎" }

        expect(assigns(:courses).to_a.count).to eq 4
        expect(response).to render_template("index")
      end

      it "検索4" do
        get :index, params: { type1: "0", keyword: "", season: "3", day: "3", hour: "3" }

        expect(assigns(:courses).to_a.count).to eq 4
        expect(response).to render_template("index")
      end
    end

    context "新規登録" do
      it "初期表示" do
        get :new
        
        expect(response).to render_template("new")
      end

      it "登録失敗：項目空値" do
        post :confirm, params: { course: attributes_for(:course,
          course_name: "", course_cd: "", indirect_use_flag: "", parent_course_id: "",
          overview: "", school_year: "", season_cd: "", day_cd: "", hour_cd: "", instructor_name: "",
          major: "", term_flag: "", class_session_count: "", group_folder_count: "", open_course_flag: "",
          open_course_pass: "", announcement_cd: "", open_course_announcement_flag: "", faq_cd: "",
          open_course_faq_flag: "", unread_assignment_display_cd: "", unread_faq_display_cd: "",
          attendance_ip1: "", attendance_ip2: "", attendance_ip3: "", attendance_ip4: "", delete_flag: ""
        ) }

        expect(response).to render_template("new")
      end

      it "登録成功" do
        post :confirm, params: { course: attributes_for(:course,
          course_name: "コース名", course_cd: "111111", indirect_use_flag: Settings.COURSE_INDIRECTUSEFLG_DIRECT, 
          parent_course_id: "", overview: "概要",
          school_year: "2020", season_cd: Settings.COURSE_SEASONCD_SPRING,
          day_cd: Settings.COURSE_DAYCD_MON, hour_cd: Settings.COURSE_HOURCD_FIRST, instructor_name: "",
          major: "", term_flag: "1", class_session_count: "15", group_folder_count: "0",
          open_course_flag: Settings.COURSE_OPENCOURSEFLG_PRIVATE,
          open_course_pass: "", announcement_cd: "1", open_course_announcement_flag: "0", faq_cd: "1",
          open_course_faq_flag: "0", unread_assignment_display_cd: "0", unread_faq_display_cd: "0",
          attendance_ip1: "", attendance_ip2: "", attendance_ip3: "", attendance_ip4: "", delete_flag: ""
        ) }

        expect{
          post :create
        }.to change(Course, :count).by(1)
      end

      it "確認画面" do
        post :confirm, params: { course: attributes_for(:course,
          course_name: "course name", course_cd: "111111", indirect_use_flag: Settings.COURSE_INDIRECTUSEFLG_DIRECT, 
          parent_course_id: "", overview: "概要",
          school_year: "2020", season_cd: Settings.COURSE_SEASONCD_SPRING,
          day_cd: Settings.COURSE_DAYCD_MON, hour_cd: Settings.COURSE_HOURCD_FIRST, instructor_name: "",
          major: "", term_flag: "1", class_session_count: "15", group_folder_count: "0",
          open_course_flag: Settings.COURSE_OPENCOURSEFLG_PRIVATE,
          open_course_pass: "", announcement_cd: "1", open_course_announcement_flag: "0", faq_cd: "1",
          open_course_faq_flag: "0", unread_assignment_display_cd: "0", unread_faq_display_cd: "0",
          attendance_ip1: "", attendance_ip2: "", attendance_ip3: "", attendance_ip4: "", delete_flag: ""
        ) }
      
        expect(response).to render_template("confirm")
      end
    end

    context "編集" do
      before do
        @course = create(:course, :year_of_2019)

      end

      it "初期表示" do
        get :edit,  params: { id: @course }
        
        expect(response).to render_template("edit")
      end

      it "更新失敗：必須項目空値" do
        post :confirm, params: { id: @course, course: attributes_for(:course,
          course_name: "", course_cd: "111111", indirect_use_flag: Settings.COURSE_INDIRECTUSEFLG_DIRECT, 
          parent_course_id: "", overview: "概要",
          school_year: "2020", season_cd: Settings.COURSE_SEASONCD_SPRING,
          day_cd: Settings.COURSE_DAYCD_MON, hour_cd: Settings.COURSE_HOURCD_FIRST, instructor_name: "",
          major: "", term_flag: "1", class_session_count: "15", group_folder_count: "0",
          open_course_flag: Settings.COURSE_OPENCOURSEFLG_PRIVATE,
          open_course_pass: "", announcement_cd: "1", open_course_announcement_flag: "0", faq_cd: "1",
          open_course_faq_flag: "0", unread_assignment_display_cd: "0", unread_faq_display_cd: "0",
          attendance_ip1: "", attendance_ip2: "", attendance_ip3: "", attendance_ip4: "", delete_flag: ""
        ) }

        expect(response).to render_template("edit")
      end

      it "更新成功" do
        post :confirm, params: { id: @course, course: attributes_for(:course, 
          course_name: "update course name", course_cd: "update111111", indirect_use_flag: Settings.COURSE_INDIRECTUSEFLG_DIRECT, 
          parent_course_id: "", overview: "概要",
          school_year: "2020", season_cd: Settings.COURSE_SEASONCD_SPRING,
          day_cd: Settings.COURSE_DAYCD_MON, hour_cd: Settings.COURSE_HOURCD_FIRST, instructor_name: "",
          major: "", term_flag: "1", class_session_count: "15", group_folder_count: "0",
          open_course_flag: Settings.COURSE_OPENCOURSEFLG_PRIVATE,
          open_course_pass: "", announcement_cd: "1", open_course_announcement_flag: "0", faq_cd: "1",
          open_course_faq_flag: "0", unread_assignment_display_cd: "0", unread_faq_display_cd: "0",
          attendance_ip1: "", attendance_ip2: "", attendance_ip3: "", attendance_ip4: "", delete_flag: ""
        ) }

        post :update, params: { id: @course }

        @course.reload
        expect(@course.course_name).to eq("update course name")
        expect(@course.course_cd).to eq("update111111")
      end

      it "確認画面" do
        post :confirm, params: { id: @course, course: @course.attributes }
      
        expect(response).to render_template("confirm")
      end
    end
  end
end