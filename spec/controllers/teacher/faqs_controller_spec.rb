require 'rails_helper'

RSpec.describe Teacher::FaqsController, type: :controller do
  let(:teacher) { create(:teacher_user) }
  let(:student) { create(:student_user) }

  before do
    create_list(:course, 5, :year_of_2018)
    create_list(:course, 6, :year_of_2019)

    courses = Course.where(school_year: 2018)
    courses.each.with_index do |course, index|
      create(:course_assigned_user, course_id: course.id, user_id: teacher.id)
    end

    courses = Course.where(school_year: 2019)
    courses.each.with_index do |course, index|
      create(:course_assigned_user, course_id: course.id, user_id: teacher.id)
      create_list(:faq, 5, course_id: course.id, user_id: student.id)
      create_list(:faq, 1, course_id: course.id, user_id: student.id, response_flag: Settings.FAQ_RESPONSEFLG_UNREPLY)
    end

    create_list(:course, 5, :year_of_2018)
    create_list(:course, 4, :year_of_2019)
  end

  describe 'Teacher FAQ管理' do
    before do
      sign_in teacher

      @course = Course.where(school_year: 2019).first
      @faq = @course.faqs.first
    end

    context "index" do
      it "初期表示" do
        get :index

        expect(assigns(:courses).count).to eq 11
        expect(response).to render_template("index")
      end

      it "検索" do
        get :index, params: { course_name: "course 2019" }

        expect(assigns(:courses).to_a.count).to eq 6
        expect(response).to render_template("index")
      end
    end

    context "回答" do
      it "FAQ質問選択" do
        get :show, params: { course_id: @course.id }
  
        expect(response).to render_template("show")
      end
  
      it "FAQ回答入力表示" do
        get :edit, params: { id: @faq.id }

        expect(assigns(:faq)).to eq @faq
        expect(response).to render_template("edit")
      end

      it "FAQ回答入力確認画面" do
        post :confirm, params: { id: @faq.id, faq: { open_flag: Settings.COURSE_OPENCOURSEFAQFLG_ON,
          faq_answer_attributes: {
            answer_title: "FAQ回答タイトル", answer: "FAQ回答", open_question: "公開用FAQ", open_answer: "公開用FAQ回答"
          }
        } }

        expect(response).to render_template("confirm")
      end

      it "FAQ回答入力確認画面" do
        post :confirm, params: { id: @faq.id, faq: { open_flag: Settings.COURSE_OPENCOURSEFAQFLG_ON,
          faq_answer_attributes: {
            answer_title: "FAQ回答タイトル", answer: "FAQ回答", open_question: "公開用FAQ", open_answer: "公開用FAQ回答"
          }
        } }
        post :update, params: { id: @faq.id }

        expect(response).to redirect_to teacher_faq_path(@course.id)

        @faq.reload
        expect(@faq.open_flag).to eq Settings.COURSE_OPENCOURSEFAQFLG_ON
        expect(@faq.faq_answer.answer_title).to eq "FAQ回答タイトル"
        expect(@faq.faq_answer.answer).to eq "FAQ回答"
        expect(@faq.faq_answer.open_question).to eq "公開用FAQ"
        expect(@faq.faq_answer.open_answer).to eq "公開用FAQ回答"

      end

      it "FAQ質問選択(FAQ_RESPONSEFLG_UNREPLY)" do
        unreply_faq = @course.faqs.where(response_flag: Settings.FAQ_RESPONSEFLG_UNREPLY).first
        post :replied, params: { id: unreply_faq.id, course_id: @course.id }

        expect(response).to redirect_to teacher_faq_path(unreply_faq.course_id)

        unreply_faq.reload
        expect(unreply_faq.open_flag).to eq Settings.COURSE_OPENCOURSEFAQFLG_OFF
        expect(unreply_faq.response_flag).to eq Settings.FAQ_RESPONSEFLG_REPLIED
        expect(unreply_faq.faq_answer.answer_title).to eq unreply_faq.faq_title
        expect(unreply_faq.faq_answer.answer).to eq I18n.t("faq.COMMONFAQ_SEPARATEANSWERED")
        expect(unreply_faq.faq_answer.open_question).to eq ""
        expect(unreply_faq.faq_answer.open_answer).to eq ""

      end
    end
  end
end
