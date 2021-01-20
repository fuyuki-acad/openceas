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

  describe 'Teacher 複合式テスト 設問作成' do
    before do
      @course = create(:course, :year_of_2019)
      create(:course_assigned_user, course_id: @course.id, user_id: teacher.id)
      @compound = create(:compound, course_id: @course.id)
    end

    context "大問作成" do
      it "初期表示" do
        get :show, params: { generic_page_id: @compound.id }

        expect(response).to render_template("show")
      end

      it "失敗" do
        post :create_parent, params: { generic_page_id: @compound.id, question: {
          content: ""
        } }

        expect(response).to render_template("show")
      end

      it "成功" do
        expect{
          post :create_parent, params: { generic_page_id: @compound.id, question: {
            content: "大問１"
          } }
        }.to change(Question, :count).by(1)

        expect(response).to redirect_to teacher_question_path(@compound.id)

        @compound.reload
        expect(@compound.parent_questions.count).to eq 1
      end
    end

    context "大問編集" do
      before do
       @parent = create(:parent_question)
       @compound.questions << @parent
      end

      it "画面表示" do
        get :edit_parent, params: { generic_page_id: @compound.id, id: @parent.id  }

        expect(response).to render_template("edit_parent")
      end

      it "失敗" do
        patch :update_parent, params: { generic_page_id: @compound.id, id: @parent.id, question: {
          content: ""
        } }

        expect(response).to render_template("edit_parent")
      end

      it "成功" do
        patch :update_parent, params: { generic_page_id: @compound.id, id: @parent.id, question: {
          content: "update parent content"
        } }

        @parent.reload
        expect(@parent.content).to eq("update parent content")

        expect(response).to redirect_to teacher_question_path(@compound.id)
      end
    end

    context "大問削除" do
      before do
       @parent = create(:parent_question)
       @compound.questions << @parent
      end

      it "成功" do
        expect{
          delete :destroy, params: { generic_page_id: @compound.id, parent_id: @parent.id }
        }.to change(Question, :count).by(-1)

        expect(response).to redirect_to teacher_question_path(@compound.id)

        @compound.reload
        expect(@compound.parent_questions.count).to eq 0
      end
    end

    context "設問作成" do
      before do
        @parent = create(:parent_question)
        @compound.questions << @parent
       end

       it "画面表示" do
        get :new, params: { generic_page_id: @compound.id, parent_id: @parent.id }

        expect(response).to render_template("new")
      end

      it "失敗" do
        post :create, params: { generic_page_id: @compound.id, parent_id: @parent.id, question: {
          content: "",
          score: "10",
          pattern_cd: Settings.QUESTION_PATTERNCD_RADIO,
          text_count: "",
          correct_answer_memo: "",
          wrong_answer_memo: "",
          quizzes_attributes: {
            "1" => { content: "", select_correct_flag: "" }
          }
        } }

        expect(response).to render_template("new")
      end

      it "成功" do
        expect{
          post :create, params: { generic_page_id: @compound.id, parent_id: @parent.id, question: {
            content: "設問１",
            score: "10",
            pattern_cd: Settings.QUESTION_PATTERNCD_RADIO,
            text_count: "4",
            correct_answer_memo: "正解メモ",
            wrong_answer_memo: "不正解メモ",
            quizzes_attributes: {
              "1" => { content: "選択肢１", select_correct_flag: "0" },
              "2" => { content: "選択肢２", select_correct_flag: "0" },
              "3" => { content: "選択肢３", select_correct_flag: "0" },
              "4" => { content: "選択肢４", select_correct_flag: "1" }
            }
          } }
        }.to change(Question, :count).by(1)

        expect(response).to redirect_to teacher_question_path(@compound.id)

        @parent.reload
        expect(@parent.questions.count).to eq 1
      end
    end

    context "設問編集" do
      before do
        @parent = create(:parent_question)
        @compound.questions << @parent
        @question = create(:question, parent_question_id: @parent.id, generic_page_type_cd: @compound.type_cd, 
          quizzes_attributes: {
            "1" => { 'content' => "選択肢１", 'select_correct_flag' => "0" },
            "2" => { 'content' => "選択肢２", 'select_correct_flag' => "0" },
            "3" => { 'content' => "選択肢３", 'select_correct_flag' => "0" },
            "4" => { 'content' => "選択肢４", 'select_correct_flag' => "1" }
          }
        )
       end

       it "画面表示" do
        get :edit, params: { generic_page_id: @compound.id, id: @question.id }

        expect(response).to render_template("edit")
      end

      it "失敗" do
        patch :update, params: { generic_page_id: @compound.id, id: @question.id, question: {
          content: "",
          score: "10",
          pattern_cd: Settings.QUESTION_PATTERNCD_RADIO,
          text_count: "",
          correct_answer_memo: "",
          wrong_answer_memo: "",
          quizzes_attributes: {
            "1" => { content: "", select_correct_flag: "" }
          }
        } }

        expect(response).to render_template("edit")
      end

      it "成功" do
        patch :update, params: { generic_page_id: @compound.id, id: @question.id, question: {
          content: "update questoin content",
          score: "10",
          pattern_cd: Settings.QUESTION_PATTERNCD_RADIO,
          text_count: "4",
          correct_answer_memo: "update correct_answer_memo",
          wrong_answer_memo: "update wrong_answer_memo",
          quizzes_attributes: {
            "1" => { id: @question.all_quizzes[0], content: "update select quiz 1", select_correct_flag: "1" },
            "2" => { id: @question.all_quizzes[1], content: "update select quiz 2", select_correct_flag: "0" },
            "3" => { id: @question.all_quizzes[2], content: "update select quiz 3", select_correct_flag: "0" },
            "4" => { id: @question.all_quizzes[3], content: "update select quiz 4", select_correct_flag: "0" }
          }
        } }

        @question.reload
        expect(@question.content).to eq("update questoin content")
        expect(@question.correct_answer_memo).to eq("update correct_answer_memo")
        expect(@question.all_quizzes[0].content).to eq("update select quiz 1")
        expect(@question.all_quizzes[0].select_correct_flag).to eq 1

        expect(response).to redirect_to teacher_question_path(@compound.id)
      end
    end

    context "設問削除" do
      before do
        @parent = create(:parent_question)
        @compound.questions << @parent
        @questions = create_list(:question, 3, parent_question_id: @parent.id, generic_page_type_cd: @compound.type_cd, 
          quizzes_attributes: {
            "1" => { 'content' => "選択肢１", 'select_correct_flag' => "0" },
            "2" => { 'content' => "選択肢２", 'select_correct_flag' => "0" },
            "3" => { 'content' => "選択肢３", 'select_correct_flag' => "0" },
            "4" => { 'content' => "選択肢４", 'select_correct_flag' => "1" }
          }
        )
      end

      it "成功" do
        expect{
          delete :destroy, params: { generic_page_id: @compound.id, parent_id: @parent.id, question: {
            @parent.id => { @questions[0].id => @questions[0].id, @questions[1].id => @questions[1].id }
          } }
        }.to change(Question, :count).by(-2)

        expect(response).to redirect_to teacher_question_path(@compound.id)

        @parent.reload
        expect(@parent.questions.count).to eq 1
      end
    end
  end
end