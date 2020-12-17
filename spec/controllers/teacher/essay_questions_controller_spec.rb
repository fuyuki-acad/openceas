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

RSpec.describe Teacher::EssayQuestionsController, type: :controller do
  let(:teacher) { create(:teacher_user) }

  before do
    sign_in teacher
  end

  describe 'Teacher レポート 課題作成' do
    before do
      @course = create(:course, :year_of_2019)
      create(:course_assigned_user, course_id: @course.id, user_id: teacher.id)
      @essay = create(:essay, course_id: @course.id)
    end

    context "新規登録" do
      it "初期表示" do
        get :show, params: { generic_page_id: @essay.id }

        expect(response).to render_template("show")
      end

      it "失敗" do
        post :create, params: { generic_page_id: @essay.id, question: {
          content: ""
        } }

        expect(response).to render_template("show")
      end

      it "成功" do
        expect{
          post :create, params: { generic_page_id: @essay.id, question: {
            content: "レポート課題"
          } }
        }.to change(Question, :count).by(1)

        expect(response).to redirect_to teacher_essay_question_path(@essay.id)

        @essay.reload
        expect(@essay.questions.count).to eq 1
      end
    end
    context "編集" do
      before do
       @questions = create_list(:essay_question, 2)
       @essay.questions << @questions
      end

      it "画面表示" do
        get :show, params: { generic_page_id: @essay.id, id: @questions[0].id  }

        expect(assigns(:generic_page).questions.count).to eq 2
        expect(response).to render_template("show")
      end

      it "失敗" do
        patch :update, params: { generic_page_id: @essay.id, id: @questions[0].id, question: {
          content: ""
        } }

        expect(response).to render_template("show")
      end

      it "成功" do
        patch :update, params: { generic_page_id: @essay.id, id: @questions[0].id, question: {
          "1" => { content: "update essay content" }
        } }

        @questions[0].reload
        expect(@questions[0].content).to eq("update essay content")

        expect(response).to redirect_to teacher_essay_question_path(@essay.id)
      end
    end

    context "大問削除" do
      before do
        @questions = create_list(:essay_question, 3)
        @essay.questions << @questions
       end

      it "成功" do
        expect{
          delete :destroy, params: { generic_page_id: @essay.id, id: @questions[0].id }
        }.to change(Question, :count).by(-1)

        expect(response).to redirect_to teacher_essay_question_path(@essay.id)

        @essay.reload
        expect(@essay.questions.count).to eq 2
      end
    end
  end
end