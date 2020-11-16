require 'rails_helper'

RSpec.describe Teacher::MultiplefibsController, type: :controller do
  let(:teacher) { create(:teacher_user) }

  before do
    sign_in teacher

    create_list(:course, 2, :year_of_2018)
    create_list(:course, 3, :year_of_2019)
    create_list(:course, 4, :year_of_2019, course_name: "検索コース名")

    Course.all.each.with_index do |course, index|
      create(:course_assigned_user, course_id: course.id, user_id: teacher.id)
    end
  end

  describe 'Teacher 記号入力式テスト' do
    context "科目選択" do
      it "初期表示" do
        get :index

        expect(assigns(:courses).count).to eq 9
        expect(response).to render_template("index")
      end

      it "検索" do
        get :index, params: { course_name: "検索コース名" }

        expect(assigns(:courses).to_a.count).to eq 4
        expect(response).to render_template("index")
      end
    end

    context "複合式テスト登録" do
      before do
        @course = Course.first
      end
      
      it "初期表示" do
        get :show, params: { course_id: @course.id }

        expect(response).to render_template("show")
      end

      context "新規登録" do
        it "画面表示" do
          get :new, params: { course_id: @course.id }

          expect(response).to render_template("new")
        end

        it "失敗" do
          post :create, params: { course_id: @course.id, generic_page: {
            course_id: @course.id,
            type_cd: Settings.GENERICPAGE_TYPECD_MULTIPLEFIBCODE,
            generic_page_title: "",
            max_count: "1",
            pass_grade: "60",
            upload_flag: GenericPage::TYPE_FILEUPLOAD,
            file: "",
            explanation_file: "",
            start_pass: "",
            start_time: "",
            end_time: "",
            material_memo: ""
           } }
  
          expect(response).to render_template("new")
        end

        it "成功" do
          expect{
            post :create, params: { course_id: @course.id, generic_page: {
              course_id: @course.id,
              type_cd: Settings.GENERICPAGE_TYPECD_MULTIPLEFIBCODE,
              generic_page_title: "複合式テストタイトル",
              max_count: "1",
              pass_grade: "60",
              upload_flag: GenericPage::TYPE_FILEUPLOAD,
              file: fixture_file_upload('test.txt', 'text/txt'),
              explanation_file: fixture_file_upload('test.txt', 'text/txt'),
              start_pass: "",
              start_time: "",
              end_time: "",
              material_memo: "メモ"
            } }
          }.to change(GenericPage, :count).by(1)

          expect(response).to redirect_to teacher_multiplefib_path(@course.id)
        end
      end

      context "編集" do
        let(:multiplefib) { create(:multiplefib, course_id: @course.id, file: fixture_file_upload('test.txt', 'text/txt')) }

        it "画面表示" do
          get :edit, params: { id: multiplefib.id }

          expect(response).to render_template("edit")
        end

        it "失敗" do
          post :update, params: { id: multiplefib.id, generic_page: {
            course_id: @course.id,
            type_cd: Settings.GENERICPAGE_TYPECD_MULTIPLEFIBCODE,
            generic_page_title: "",
            max_count: "1",
            pass_grade: "60",
            start_pass: "",
            start_time: "",
            end_time: "",
            material_memo: ""
          } }

          expect(response).to render_template("edit")
        end

        it "更新成功" do
          post :update, params: { id: multiplefib.id, generic_page: {
            course_id: @course.id,
            type_cd: Settings.GENERICPAGE_TYPECD_MULTIPLEFIBCODE,
            generic_page_title: "update multiplefib title",
            max_count: "1",
            pass_grade: "60",
            start_pass: "",
            start_time: "",
            end_time: "",
            material_memo: "update multiplefib memo"
          } }

          multiplefib.reload
          expect(multiplefib.generic_page_title).to eq("update multiplefib title")
          expect(multiplefib.material_memo).to eq("update multiplefib memo")
          expect(response).to redirect_to teacher_multiplefib_path(@course.id)
        end
      end

      context "削除" do
        before do
          @multiplefibs = create_list(:multiplefib, 3, course_id: @course.id, file: fixture_file_upload('test.txt', 'text/txt'))
        end

        it "成功" do
          expect{
            delete :destroy, params: { course_id: @course.id,
              multiplefib: { @multiplefibs[0].id => @multiplefibs[0].id, @multiplefibs[1].id => @multiplefibs[1].id } }
          }.to change(GenericPage, :count).by(-2)

          @course.reload
          expect(@course.multiplefibs.count).to eq 1
          expect(response).to redirect_to teacher_multiplefib_path(@course.id)
        end
      end

      context "他の科目からコピー" do
        let(:target_course) { Course.where(course_name: "検索コース名").first }

        before do
          @multiplefibs = create_list(:multiplefib, 3, course_id: @course.id, file: fixture_file_upload('test.txt', 'text/txt'))

          @multiplefibs.each do |multiplefib|
            parents = create_list(:parent_question, 2)
            multiplefib.questions << parents
            parents.each do |parent|
              questions = create_list(:question, 3, parent_question_id: parent.id, generic_page_type_cd: multiplefib.type_cd)
            end
          end
        end

        it "初期表示" do
          get :select_course, params: { course_id: target_course.id }

          expect(response).to render_template("select_course")
        end

        it "科目選択" do
          get :select_page, params: { course_id: target_course.id, origin_id: @course.id }

          expect(assigns(:origin).multiplefibs.count).to eq 3
          expect(assigns(:origin).multiplefibs[0].parent_questions.count).to eq 2
          expect(response).to render_template("select_page")
        end

        it "授業資料コピー" do

          expect{
              post :copy, params: { course_id: target_course.id, origin_id: @course.id, 
                multiplefib: { @multiplefibs[0].id => @multiplefibs[0].id, @multiplefibs[1].id => @multiplefibs[1].id } }
          }.to change(GenericPage, :count).by(2)

          expect(response).to redirect_to teacher_multiplefib_path(target_course.id)

          target_course.reload
          expect(target_course.multiplefibs.count).to eq 2
          expect(target_course.multiplefibs[0].parent_questions.count).to eq 2
          expect(target_course.multiplefibs[0].parent_questions[0].questions.count).to eq 3
        end
      end
    end
  end
end