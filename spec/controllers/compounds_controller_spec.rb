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

RSpec.describe CompoundsController, type: :controller do
  let(:student) { create(:student_user) }

  before do
    @course = create(:course, :year_of_2019)

    @class_session_no = 2

    @class_session = create(:class_session, course_id: @course.id, class_session_no: @class_session_no)
  end

  describe '複合式テスト実施' do
    context '生徒ユーザ' do
      before do
        sign_in student

        create(:course_enrollment_user, course_id: @course.id, user_id: student.id)
      end

      context '未受験' do
        context '期限前' do
          before do
            @compound = create(:compound, course_id: @course.id, start_time: Time.new + 1.day)
            create(:generic_page_class_session_association, class_session_id: @class_session.id, generic_page_id: @compound.id)
          end

          it "表示" do
            get :show, params: { id: @compound.id, class_session_no: @class_session_no }

            expect(response).to render_template("error")
          end
        end

        context '期限終了' do
          before do
            @compound = create(:compound, course_id: @course.id, end_time: Time.new - 1.day)
            create(:generic_page_class_session_association, class_session_id: @class_session.id, generic_page_id: @compound.id)
          end

          it "表示" do
            get :show, params: { id: @compound.id, class_session_no: @class_session_no }

            expect(response).to render_template("error")
          end
        end

        context '有効期間内' do
          before do
            @compound = create(:compound, course_id: @course.id, start_time: Time.new - 1.day, end_time: Time.new + 1.day)
            create(:generic_page_class_session_association, class_session_id: @class_session.id, generic_page_id: @compound.id)
          end

          it "表示" do
            get :show, params: { id: @compound.id, class_session_no: @class_session_no }

            expect(response).to render_template("show")
          end
        end

        context '開始パスワード有り' do
          before do
            @compound = create(:compound, course_id: @course.id, start_pass: "12345")
            create(:generic_page_class_session_association, class_session_id: @class_session.id, generic_page_id: @compound.id)
          end

          it "表示" do
            get :show, params: { id: @compound.id, class_session_no: @class_session_no }

            expect(response).to render_template("start_password")
          end

          it "パスワード誤り" do
            post :password, params: { id: @compound.id, class_session_no: @class_session_no, start_pass: "11111" }

            expect(response).to render_template("start_password")
          end

          it "パスワード一致" do
            post :password, params: { id: @compound.id, class_session_no: @class_session_no, start_pass: "12345" }

            expect(response).to render_template("show")
          end
        end

        context '回答' do
          before do
            @compound = create(:compound, course_id: @course.id, start_time: Time.new - 1.day, end_time: Time.new + 1.day)
            @parent_question = create(:parent_question)
            @compound.questions << @parent_question
            create_list(:question, 3, parent_question_id: @parent_question.id, generic_page_type_cd: @compound.type_cd, 
              quizzes_attributes: {
                "1" => { 'content' => "選択肢１", 'select_correct_flag' => "0" },
                "2" => { 'content' => "選択肢２", 'select_correct_flag' => "0" },
                "3" => { 'content' => "選択肢３", 'select_correct_flag' => "0" },
                "4" => { 'content' => "選択肢４", 'select_correct_flag' => "1" }
              }
            )
            create(:generic_page_class_session_association, class_session_id: @class_session.id, generic_page_id: @compound.id)
          end

          it "確認＆保存" do
            compound_answers = {}
            @parent_question.questions.each do |question|
              compound_answers[question.id] = { select_answer_id: question.all_quizzes[0].id }
            end

            patch :confirm, params: { id: @compound.id, answers: compound_answers }
            expect(response).to render_template("confirm")

            expect{
              patch :save, params: { id: @compound.id }
            }.to change(AnswerScore, :count).by(1)

            expect(response).to redirect_to action: :mark, id: @compound.id
          end

          it "一時保存後＆保存" do
            compound_answers = {}
            @parent_question.questions.each do |question|
              compound_answers[question.id] = { select_answer_id: question.all_quizzes[0].id }
            end

            #一次保存
            expect{
              patch :save, params: { id: @compound.id, answers: compound_answers }
            }.to change(AnswerScore, :count).by(1)

            @compound.reload
            expect(@compound.latest_score(student.id).total_score).to eq Settings.ANSWERSCORE_TMP_SAVED_SCORE
            expect(response).to redirect_to compound_path(@compound)


            @parent_question.questions.each do |question|
              compound_answers[question.id] = { select_answer_id: question.all_quizzes[1].id }
            end

            #確認
            patch :confirm, params: { id: @compound.id, answers: compound_answers }
            expect(response).to render_template("confirm")

            #保存
            expect{
              patch :save, params: { id: @compound.id }
            }.to change(AnswerScore, :count).by(0)

            @compound.reload
            expect(@compound.latest_score(student.id).total_score).to_not eq Settings.ANSWERSCORE_TMP_SAVED_SCORE
            expect(response).to redirect_to action: :mark, id: @compound.id
          end
        end

        context '回答：期限切れ' do
          before do
            @compound = create(:compound, course_id: @course.id, start_time: Time.new - 1.day, end_time: Time.new - 1.day)
            @parent_question = create(:parent_question)
            @compound.questions << @parent_question
            create_list(:question, 3, parent_question_id: @parent_question.id, generic_page_type_cd: @compound.type_cd, 
              quizzes_attributes: {
                "1" => { 'content' => "選択肢１", 'select_correct_flag' => "0" },
                "2" => { 'content' => "選択肢２", 'select_correct_flag' => "0" },
                "3" => { 'content' => "選択肢３", 'select_correct_flag' => "0" },
                "4" => { 'content' => "選択肢４", 'select_correct_flag' => "1" }
              }
            )
            create(:generic_page_class_session_association, class_session_id: @class_session.id, generic_page_id: @compound.id)
          end

          it "確認＆保存" do
            compound_answers = {}
            @parent_question.questions.each do |question|
              compound_answers[question.id] = { select_answer_id: question.all_quizzes[0].id }
            end

            patch :confirm, params: { id: @compound.id, answers: compound_answers }
            expect(response).to render_template("confirm")

            expect{
              patch :save, params: { id: @compound.id }
            }.to change(AnswerScore, :count).by(0)

            expect(response).to render_template("error")
          end
        end
      end

      context '1回受験済み：期限終了：最大受験回数１回' do
        before do
          @compound = create(:compound, course_id: @course.id, end_time: Time.new - 1.day)
          parent_question = create(:parent_question)
          @compound.questions << parent_question
          create_list(:question, 3, parent_question_id: parent_question.id, generic_page_type_cd: @compound.type_cd, 
            quizzes_attributes: {
              "1" => { 'content' => "選択肢１", 'select_correct_flag' => "0" },
              "2" => { 'content' => "選択肢２", 'select_correct_flag' => "0" },
              "3" => { 'content' => "選択肢３", 'select_correct_flag' => "0" },
              "4" => { 'content' => "選択肢４", 'select_correct_flag' => "1" }
            }
          )
          create(:generic_page_class_session_association, class_session_id: @class_session.id, generic_page_id: @compound.id)
        end

        context '期限終了：合格' do
          before do
            create(:passed_answer_score, page_id:@compound.id, user_id: student.id)
          end

          it "表示" do
            get :show, params: { id: @compound.id, class_session_no: @class_session_no }

            expect(response).to render_template("mark")
          end
        end

        context '期限終了：不合格' do
          before do
            create(:failed_answer_score, page_id:@compound.id, user_id: student.id)
          end

          it "表示" do
            get :show, params: { id: @compound.id, class_session_no: @class_session_no }

            expect(response).to render_template("mark")
          end
        end
      end

      context '1回受験済み：期限終了：最大受験回数２回' do
        before do
          @compound = create(:compound, course_id: @course.id, end_time: Time.new - 1.day, max_count: 2)
          @parent_question = create(:parent_question)
          @compound.questions << @parent_question
          create_list(:question, 3, parent_question_id: @parent_question.id, generic_page_type_cd: @compound.type_cd, 
            quizzes_attributes: {
              "1" => { 'content' => "選択肢１", 'select_correct_flag' => "0" },
              "2" => { 'content' => "選択肢２", 'select_correct_flag' => "0" },
              "3" => { 'content' => "選択肢３", 'select_correct_flag' => "0" },
              "4" => { 'content' => "選択肢４", 'select_correct_flag' => "1" }
            }
          )
          create(:generic_page_class_session_association, class_session_id: @class_session.id, generic_page_id: @compound.id)
        end

        context '期限終了：合格' do
          before do
            create(:passed_answer_score, page_id:@compound.id, user_id: student.id)
          end

          it "表示" do
            get :show, params: { id: @compound.id, class_session_no: @class_session_no }

            expect(response).to render_template("mark")
          end
        end

        context '期限終了：不合格' do
          before do
            create(:failed_answer_score, page_id:@compound.id, user_id: student.id)
          end

          it "表示" do
            get :show, params: { id: @compound.id, class_session_no: @class_session_no }

            expect(response).to render_template("mark")
          end
        end

        it "確認＆保存" do
          create(:failed_answer_score, page_id:@compound.id, user_id: student.id)

          compound_answers = {}
          @parent_question.questions.each do |question|
            compound_answers[question.id] = { select_answer_id: question.all_quizzes[0].id }
          end

          patch :confirm, params: { id: @compound.id, answers: compound_answers }
          expect(response).to render_template("confirm")

          expect{
            patch :save, params: { id: @compound.id }
          }.to change(AnswerScore, :count).by(0)

          @compound.reload
          count = @compound.answer_score_histories.count
          expect(count).to eq 1
          expect(response).to render_template("error")
        end
      end

      context '1回受験済み：有効期間内：最大受験回数２回' do
        before do
          @compound = create(:compound, course_id: @course.id, start_time: Time.new - 1.day, end_time: Time.new + 1.day, max_count: 2)
          @parent_question = create(:parent_question)
          @compound.questions << @parent_question
          create_list(:question, 3, parent_question_id: @parent_question.id, generic_page_type_cd: @compound.type_cd, 
            quizzes_attributes: {
              "1" => { 'content' => "選択肢１", 'select_correct_flag' => "0" },
              "2" => { 'content' => "選択肢２", 'select_correct_flag' => "0" },
              "3" => { 'content' => "選択肢３", 'select_correct_flag' => "0" },
              "4" => { 'content' => "選択肢４", 'select_correct_flag' => "1" }
            }
          )
          create(:generic_page_class_session_association, class_session_id: @class_session.id, generic_page_id: @compound.id)
        end

        context '期限終了：合格' do
          before do
            create(:passed_answer_score, page_id:@compound.id, user_id: student.id)
          end

          it "表示" do
            get :show, params: { id: @compound.id, class_session_no: @class_session_no }

            expect(response).to render_template("mark")
          end
        end

        context '期限終了：不合格' do
          before do
            create(:failed_answer_score, page_id:@compound.id, user_id: student.id)
          end

          it "表示" do
            get :show, params: { id: @compound.id, class_session_no: @class_session_no }

            expect(response).to render_template("show")
          end
        end

        it "確認＆保存" do
          create(:failed_answer_score, page_id:@compound.id, user_id: student.id)

          compound_answers = {}
          @parent_question.questions.each do |question|
            compound_answers[question.id] = { select_answer_id: question.all_quizzes[0].id }
          end

          patch :confirm, params: { id: @compound.id, answers: compound_answers }
          expect(response).to render_template("confirm")

          expect{
            patch :save, params: { id: @compound.id }
          }.to change(AnswerScore, :count).by(0)

          @compound.reload
          count = @compound.answer_score_histories.count
          expect(count).to eq 2
          expect(response).to redirect_to action: :mark, id: @compound.id
        end
      end
    end
  end
end
