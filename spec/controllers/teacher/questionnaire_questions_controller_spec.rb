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

RSpec.describe Teacher::QuestionsController, type: :controller do
  let(:teacher) { create(:teacher_user) }

  before do
    sign_in teacher
  end

  describe 'Teacher アンケート 設問作成' do
    before do
      @course = create(:course, :year_of_2019)
      create(:course_assigned_user, course_id: @course.id, user_id: teacher.id)
      @questionnaire = create(:questionnaire, course_id: @course.id)
    end

    context "大問作成" do
      it "初期表示" do
        get :show, params: { generic_page_id: @questionnaire.id }

        expect(response).to render_template("show")
      end

      it "失敗" do
        post :create_parent, params: { generic_page_id: @questionnaire.id, question: {
          content: ""
        } }

        expect(response).to render_template("show")
      end

      it "成功" do
        expect{
          post :create_parent, params: { generic_page_id: @questionnaire.id, question: {
            content: "アンケート大問１"
          } }
        }.to change(Question, :count).by(1)

        expect(response).to redirect_to teacher_question_path(@questionnaire.id)

        @questionnaire.reload
        expect(@questionnaire.parent_questions.count).to eq 1
      end
    end

    context "大問編集" do
      before do
       @parent = create(:parent_question)
       @questionnaire.questions << @parent
      end

      it "画面表示" do
        get :edit_parent, params: { generic_page_id: @questionnaire.id, id: @parent.id  }

        expect(response).to render_template("edit_parent")
      end

      it "失敗" do
        patch :update_parent, params: { generic_page_id: @questionnaire.id, id: @parent.id, question: {
          content: ""
        } }

        expect(response).to render_template("edit_parent")
      end

      it "成功" do
        patch :update_parent, params: { generic_page_id: @questionnaire.id, id: @parent.id, question: {
          content: "update parent content"
        } }

        @parent.reload
        expect(@parent.content).to eq("update parent content")

        expect(response).to redirect_to teacher_question_path(@questionnaire.id)
      end
    end

    context "大問削除" do
      before do
       @parents = create_list(:parent_question, 3)
       @questionnaire.questions << @parents
      end

      it "成功" do
        expect{
          delete :destroy, params: { generic_page_id: @questionnaire.id, parent_id: @parents[0].id }
        }.to change(Question, :count).by(-1)

        expect(response).to redirect_to teacher_question_path(@questionnaire.id)

        @questionnaire.reload
        expect(@questionnaire.parent_questions.count).to eq 2
      end
    end

    context "設問作成" do
      before do
        @parent = create(:parent_question)
        @questionnaire.questions << @parent
       end

       it "画面表示" do
        get :new, params: { generic_page_id: @questionnaire.id, parent_id: @parent.id }

        expect(response).to render_template("new")
      end

      it "失敗" do
        post :create, params: { generic_page_id: @questionnaire.id, parent_id: @parent.id, question: {
          content: "",
          must_flag: "0",
          pattern_cd: Settings.QUESTION_PATTERNCD_RADIO,
          text_count: "",
          text_flag: "0",
          answer_memo: "",
          quizzes_attributes: {
            "1" => { content: "", select_mark_flag: "" }
          }
        } }

        expect(response).to render_template("new")
      end

      it "成功" do
        expect{
          post :create, params: { generic_page_id: @questionnaire.id, parent_id: @parent.id, question: {
            content: "設問１",
            must_flag: "0",
            pattern_cd: Settings.QUESTION_PATTERNCD_RADIO,
            text_count: "4",
            text_flag: "0",
            answer_memo: "メモ",
            quizzes_attributes: {
              "1" => { content: "選択肢１", select_mark_flag: "0" },
              "2" => { content: "選択肢２", select_mark_flag: "0" },
              "3" => { content: "選択肢３", select_mark_flag: "0" },
              "4" => { content: "選択肢４", select_mark_flag: "1" }
            }
          } }
        }.to change(Question, :count).by(1)

        expect(response).to redirect_to teacher_question_path(@questionnaire.id)

        @parent.reload
        expect(@parent.questions.count).to eq 1
      end
    end

    context "設問編集" do
      before do
        @parent = create(:parent_question)
        @questionnaire.questions << @parent
        @question = create(:questionnaire_question, parent_question_id: @parent.id, generic_page_type_cd: @questionnaire.type_cd, 
          quizzes_attributes: {
            "1" => { 'content' => "選択肢１", 'select_mark_flag' => "0" },
            "2" => { 'content' => "選択肢２", 'select_mark_flag' => "0" },
            "3" => { 'content' => "選択肢３", 'select_mark_flag' => "0" },
            "4" => { 'content' => "選択肢４", 'select_mark_flag' => "1" }
          }
        )
       end

       it "画面表示" do
        get :edit, params: { generic_page_id: @questionnaire.id, id: @question.id }

        expect(response).to render_template("edit")
      end

      it "失敗" do
        patch :update, params: { generic_page_id: @questionnaire.id, id: @question.id, question: {
          content: "",
          must_flag: "0",
          pattern_cd: Settings.QUESTION_PATTERNCD_RADIO,
          text_count: "",
          text_flag: "0",
          answer_memo: "",
          quizzes_attributes: {
            "1" => { content: "", select_mark_flag: "" }
          }
        } }

        expect(response).to render_template("edit")
      end

      it "成功" do
        patch :update, params: { generic_page_id: @questionnaire.id, id: @question.id, question: {
          content: "update questoin content",
          must_flag: "0",
          pattern_cd: Settings.QUESTION_PATTERNCD_RADIO,
          text_count: "4",
          text_flag: "0",
          answer_memo: "update answer_memo",
          quizzes_attributes: {
            "1" => { id: @question.all_quizzes[0], content: "update select quiz 1", select_mark_flag: "1" },
            "2" => { id: @question.all_quizzes[1], content: "update select quiz 2", select_mark_flag: "0" },
            "3" => { id: @question.all_quizzes[2], content: "update select quiz 3", select_mark_flag: "0" },
            "4" => { id: @question.all_quizzes[3], content: "update select quiz 4", select_mark_flag: "0" }
          }
        } }

        @question.reload
        expect(@question.content).to eq("update questoin content")
        expect(@question.answer_memo).to eq("update answer_memo")
        expect(@question.all_quizzes[0].content).to eq("update select quiz 1")
        expect(@question.all_quizzes[0].select_mark_flag).to eq 1

        expect(response).to redirect_to teacher_question_path(@questionnaire.id)
      end
    end

    context "設問削除" do
      before do
        @parent = create(:parent_question)
        @questionnaire.questions << @parent
        @questions = create_list(:questionnaire_question, 3, parent_question_id: @parent.id, generic_page_type_cd: @questionnaire.type_cd, 
          quizzes_attributes: {
            "1" => { 'content' => "選択肢１", 'select_mark_flag' => "0" },
            "2" => { 'content' => "選択肢２", 'select_mark_flag' => "0" },
            "3" => { 'content' => "選択肢３", 'select_mark_flag' => "0" },
            "4" => { 'content' => "選択肢４", 'select_mark_flag' => "1" }
          }
        )
      end

      it "成功" do
        expect{
          delete :destroy, params: { generic_page_id: @questionnaire.id, parent_id: @parent.id, question: {
            @parent.id => { @questions[0].id => @questions[0].id, @questions[1].id => @questions[1].id }
          } }
        }.to change(Question, :count).by(-2)

        expect(response).to redirect_to teacher_question_path(@questionnaire.id)

        @parent.reload
        expect(@parent.questions.count).to eq 1
      end
    end
  end
end