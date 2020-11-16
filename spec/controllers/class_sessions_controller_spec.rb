require 'rails_helper'

RSpec.describe ClassSessionsController, type: :controller do
  let(:student) { create(:student_user) }

  before do
    @course = create(:course, :year_of_2019)

    @class_session_no0 = 0
    @class_session_no1 = 1

    @class_session1 = create(:class_session, course_id: @course.id, class_session_no: @class_session_no0)
    @class_session2 = create(:class_session, course_id: @course.id, class_session_no: @class_session_no1)

    @material1 = create(:material, course_id: @course.id, file: fixture_file_upload('test.txt', 'text/txt'))
    create(:generic_page_class_session_association, class_session_id: @class_session1.id, generic_page_id: @material1.id)

    @material2 = create(:material, course_id: @course.id, file: fixture_file_upload('test.txt', 'text/txt'))
    create(:generic_page_class_session_association, class_session_id: @class_session2.id, generic_page_id: @material2.id)

    @url_link1 = create(:url_link, course_id: @course.id)
    create(:generic_page_class_session_association, class_session_id: @class_session1.id, generic_page_id: @url_link1.id)

    @url_link2 = create(:url_link, course_id: @course.id)
    create(:generic_page_class_session_association, class_session_id: @class_session2.id, generic_page_id: @url_link2.id)

    @compound1 = create(:compound, course_id: @course.id)
    create(:generic_page_class_session_association, class_session_id: @class_session1.id, generic_page_id: @compound1.id)

    @compound2 = create(:compound, course_id: @course.id)
    create(:generic_page_class_session_association, class_session_id: @class_session2.id, generic_page_id: @compound2.id)

    @multiplefib1 = create(:multiplefib, course_id: @course.id, file: fixture_file_upload('test.txt', 'text/txt'))
    create(:generic_page_class_session_association, class_session_id: @class_session1.id, generic_page_id: @multiplefib1.id)

    @multiplefib2 = create(:multiplefib, course_id: @course.id, file: fixture_file_upload('test.txt', 'text/txt'))
    create(:generic_page_class_session_association, class_session_id: @class_session2.id, generic_page_id: @multiplefib2.id)

    @questionnaire1 = create(:questionnaire, course_id: @course.id)
    create(:generic_page_class_session_association, class_session_id: @class_session1.id, generic_page_id: @questionnaire1.id)

    @questionnaire2 = create(:questionnaire, course_id: @course.id)
    create(:generic_page_class_session_association, class_session_id: @class_session2.id, generic_page_id: @questionnaire2.id)

    @essay1 = create(:essay, course_id: @course.id)
    create(:generic_page_class_session_association, class_session_id: @class_session1.id, generic_page_id: @essay1.id)

    @essay2 = create(:essay, course_id: @course.id)
    create(:generic_page_class_session_association, class_session_id: @class_session2.id, generic_page_id: @essay2.id)

    @evaluation1 = create(:evaluation, course_id: @course.id)
    create(:generic_page_class_session_association, class_session_id: @class_session1.id, generic_page_id: @evaluation1.id)

    @evaluation2 = create(:evaluation, course_id: @course.id)
    create(:generic_page_class_session_association, class_session_id: @class_session2.id, generic_page_id: @evaluation2.id)
  end

  describe '授業実施画面' do
    context '生徒ユーザ' do
      before do
        sign_in student

        create(:course_enrollment_user, course_id: @course.id, user_id: student.id)
      end

      context '一覧画面' do
        it "初期表示" do
          get :index, params: { course_id: @course.id }

          expect(response).to render_template("index")
        end

        it "共通画面" do
          get :show, params: { course_id: @course.id, session_no: @class_session_no0 }

          expect(assigns(:class_session).materials.count).to eq 1
          expect(assigns(:class_session).urls.count).to eq 1
          expect(assigns(:class_session).questionnaires.count).to eq 1
          expect(assigns(:class_session).componds.count).to eq 1
          expect(assigns(:class_session).multiplefibs.count).to eq 1
          expect(assigns(:class_session).essays.count).to eq 1
          expect(assigns(:class_session).evaluations.count).to eq 1
          expect(response).to render_template("show")
        end

        it "第1回目" do
          get :show, params: { course_id: @course.id, session_no: @class_session_no1 }

          expect(assigns(:class_session).materials.count).to eq 1
          expect(assigns(:class_session).urls.count).to eq 1
          expect(assigns(:class_session).questionnaires.count).to eq 1
          expect(assigns(:class_session).componds.count).to eq 1
          expect(assigns(:class_session).multiplefibs.count).to eq 1
          expect(assigns(:class_session).essays.count).to eq 1
          expect(assigns(:class_session).evaluations.count).to eq 1
          expect(response).to render_template("show")
        end
      end
    end
  end
end
