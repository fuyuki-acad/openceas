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

RSpec.describe Teacher::MultiplefibQuestionsController, type: :controller do
  let(:teacher) { create(:teacher_user) }

  before do
    sign_in teacher
  end

  describe 'Teacher 記号入力式テスト解答記入部' do
    before do
      @course = create(:course, :year_of_2019)
      create(:course_assigned_user, course_id: @course.id, user_id: teacher.id)
      @multiplefib = create(:multiplefib, course_id: @course.id, file: fixture_file_upload('test.txt', 'text/txt'))
    end

    context "大問作成" do
      it "初期表示" do
        get :show, params: { generic_page_id: @multiplefib.id }

        expect(response).to render_template("show")
      end

      it "成功" do
        expect{
          post :create_parent, params: { generic_page_id: @multiplefib.id }
        }.to change(Question, :count).by(1)

        expect(response).to redirect_to action: :show, generic_page_id: @multiplefib

        @multiplefib.reload
        expect(@multiplefib.parent_questions.count).to eq 1
      end
    end

    context "大問削除" do
      before do
       @parents = create_list(:parent_question, 3)
       @multiplefib.questions << @parents
      end

      it "成功" do
        expect{
          delete :destroy_parent, params: { generic_page_id: @multiplefib.id, id: @parents[0].id }
        }.to change(Question, :count).by(-1)

        expect(response).to redirect_to action: :show, generic_page_id: @multiplefib

        @multiplefib.reload
        expect(@multiplefib.parent_questions.count).to eq 2
      end
    end

    context "設問作成" do
      before do
        @parent = create(:parent_question)
        @multiplefib.questions << @parent
       end

      it "成功" do
        expect{
          post :create, params: { generic_page_id: @multiplefib.id, parent_id: @parent.id }
        }.to change(Question, :count).by(1)

        expect(response).to have_http_status(:ok)

        @parent.reload
        expect(@parent.questions.count).to eq 1
      end
    end

    context "設問削除" do
      before do
        @parent = create(:parent_question)
        @multiplefib.questions << @parent
        @questions = create_list(:question, 3, parent_question_id: @parent.id, generic_page_type_cd: @multiplefib.type_cd)
      end

      it "成功" do
        expect{
          delete :destroy, params: { generic_page_id: @multiplefib.id, parent_id: @parent.id, 
            delete: { @questions[0].id => @questions[0].id, @questions[1].id => @questions[1].id }
          }
        }.to change(Question, :count).by(-2)

        expect(response).to have_http_status(:ok)

        @parent.reload
        expect(@parent.questions.count).to eq 1
      end
    end

    context "大問登録" do
      before do
        @multiplefib_questions = {}
        parents = create_list(:parent_question, 2)
        @multiplefib.questions << parents
        parents.each do |parent|
          questions = create_list(:question, 3, parent_question_id: parent.id, generic_page_type_cd: @multiplefib.type_cd)
          questions.each.with_index do |question, index|
            @multiplefib_questions[question.id] = {answer_memo: "#{index}", score: "5", random_cd: "6", answer_in_full_cd: "7"}
          end
        end
      end

      it "成功" do
        patch :update, params: { generic_page_id: @multiplefib.id, question: @multiplefib_questions }

        expect(response).to redirect_to action: :show, generic_page_id: @multiplefib

        @multiplefib.reload
        expect(@multiplefib.parent_questions.count).to eq 2
        expect(@multiplefib.parent_questions[0].questions.count).to eq 3
        expect(@multiplefib.parent_questions[0].questions[0].answer_memo).to eq "0"
        expect(@multiplefib.parent_questions[0].questions[0].score).to eq 5
        expect(@multiplefib.parent_questions[0].questions[0].random_cd).to eq 6
        expect(@multiplefib.parent_questions[0].questions[0].answer_in_full_cd).to eq 7
        expect(@multiplefib.parent_questions[0].questions[1].answer_memo).to eq "1"
      end
    end

  end
end