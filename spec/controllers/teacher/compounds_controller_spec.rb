#--
# Copyright (c) 2019 Fuyuki Academy
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#++

require 'rails_helper'

RSpec.describe Teacher::CompoundsController, type: :controller do
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

  describe 'Teacher 複合式テスト' do
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
            type_cd: Settings.GENERICPAGE_TYPECD_COMPOUNDCODE,
            generic_page_title: "",
            max_count: "1",
            pass_grade: "60",
            file: "",
            start_pass: "",
            start_time: "",
            end_time: "",
            self_type: "0",
            self_pass: "",
            material_memo: ""
           } }
  
          expect(response).to render_template("new")
        end

        it "成功" do
          expect{
            post :create, params: { course_id: @course.id, generic_page: {
              course_id: @course.id,
              type_cd: Settings.GENERICPAGE_TYPECD_COMPOUNDCODE,
              generic_page_title: "複合式テストタイトル",
              max_count: "1",
              pass_grade: "60",
              file: "",
              start_pass: "",
              start_time: "",
              end_time: "",
              self_type: "0",
              self_pass: "",
              material_memo: "メモ"
            } }
          }.to change(GenericPage, :count).by(1)

          expect(response).to redirect_to teacher_compound_path(@course.id)
        end
      end

      context "編集" do
        let(:compound) { create(:compound, course_id: @course.id) }

        it "画面表示" do
          get :edit, params: { id: compound.id }

          expect(response).to render_template("edit")
        end

        it "失敗" do
          post :update, params: { id: compound.id, generic_page: {
            course_id: @course.id,
            type_cd: Settings.GENERICPAGE_TYPECD_COMPOUNDCODE,
            generic_page_title: "",
            max_count: "1",
            pass_grade: "60",
            file: "",
            start_pass: "",
            start_time: "",
            end_time: "",
            self_type: "0",
            self_pass: "",
            material_memo: ""
        } }

          expect(response).to render_template("edit")
        end

        it "更新成功" do
          post :update, params: { id: compound.id, generic_page: {
            course_id: @course.id,
            type_cd: Settings.GENERICPAGE_TYPECD_COMPOUNDCODE,
            generic_page_title: "update compound title",
            max_count: "1",
            pass_grade: "60",
            file: "",
            start_pass: "",
            start_time: "",
            end_time: "",
            self_type: "0",
            self_pass: "",
            material_memo: "update compound memo"
          } }

          compound.reload
          expect(compound.generic_page_title).to eq("update compound title")
          expect(compound.material_memo).to eq("update compound memo")
          expect(response).to redirect_to teacher_compound_path(@course.id)
        end
      end

      context "削除" do
        before do
          @compound1 = create(:compound, course_id: @course.id)
          @compound2 = create(:compound, course_id: @course.id)
        end

        it "成功" do
          expect{
            delete :destroy, params: { course_id: @course.id, compound: { @compound1.id => @compound1.id, @compound2.id => @compound2.id } }
          }.to change(GenericPage, :count).by(-2)

          expect(response).to redirect_to teacher_compound_path(@course.id)
        end
      end

      context "他の科目からコピー" do
        let(:target_course) { Course.where(course_name: "検索コース名").first }

        before do
          @compounds = create_list(:compound, 3, course_id: @course.id)

          @compounds.each do |compound|
            parents = create_list(:parent_question, 2)
            compound.questions << parents
            parents.each do |parent|
              create_list(:question, 3, parent_question_id: parent.id, generic_page_type_cd: compound.type_cd, 
                quizzes_attributes: {
                  "1" => { 'content' => "選択肢１", 'select_correct_flag' => "0" },
                  "2" => { 'content' => "選択肢２", 'select_correct_flag' => "0" },
                  "3" => { 'content' => "選択肢３", 'select_correct_flag' => "0" },
                  "4" => { 'content' => "選択肢４", 'select_correct_flag' => "1" }
                }
              )
            end
          end
        end

        it "初期表示" do
          get :select_course, params: { course_id: target_course.id }

          expect(response).to render_template("select_course")
        end

        it "科目選択" do
          get :select_page, params: { course_id: target_course.id, origin_id: @course.id }

          expect(assigns(:origin).compounds.count).to eq 3
          expect(assigns(:origin).compounds[0].parent_questions.count).to eq 2
          expect(response).to render_template("select_page")
        end

        it "授業資料コピー" do

          expect{
              post :copy, params: { course_id: target_course.id, origin_id: @course.id, 
                compound: { @compounds[0].id => @compounds[0].id, @compounds[1].id => @compounds[1].id } }
          }.to change(GenericPage, :count).by(2)

          expect(response).to redirect_to teacher_compound_path(target_course.id)

          target_course.reload
          expect(target_course.compounds.count).to eq 2
          expect(target_course.compounds[0].parent_questions.count).to eq 2
          expect(target_course.compounds[0].parent_questions[0].questions.count).to eq 3
          expect(target_course.compounds[0].parent_questions[0].questions[0].all_quizzes.count).to eq 4
        end
      end
    end
  end
end