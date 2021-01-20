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

RSpec.describe MultiplefibsController, type: :controller do
  let(:student) { create(:student_user) }

  before do
    @course = create(:course, :year_of_2019)

    @class_session_no = 2

    @class_session = create(:class_session, course_id: @course.id, class_session_no: @class_session_no)
  end

  describe '記号入力式テスト実施' do
    context '生徒ユーザ' do
      before do
        sign_in student

        create(:course_enrollment_user, course_id: @course.id, user_id: student.id)
      end

      context '未回答' do
        context '期限前' do
          before do
            @multiplefib = create(:multiplefib, course_id: @course.id, start_time: Time.new + 1.day, end_time: Time.new + 2.day,
              file: fixture_file_upload('test.txt', 'text/txt'))
            create(:generic_page_class_session_association, class_session_id: @class_session.id, generic_page_id: @multiplefib.id)
          end

          it "表示" do
            get :show, params: { id: @multiplefib.id }

            expect(response).to render_template("error")
          end
        end

        context '期限終了' do
          before do
            @multiplefib = create(:multiplefib, course_id: @course.id, start_time: Time.new - 2.day, end_time: Time.new - 1.day,
              file: fixture_file_upload('test.txt', 'text/txt'))
            create(:generic_page_class_session_association, class_session_id: @class_session.id, generic_page_id: @multiplefib.id)
          end

          it "表示" do
            get :show, params: { id: @multiplefib.id }

            expect(response).to render_template("error")
          end
        end

        context '有効期間内' do
          before do
            @multiplefib = create(:multiplefib, course_id: @course.id, start_time: Time.new - 2.day, end_time: Time.new + 1.day,
              file: fixture_file_upload('test.txt', 'text/txt'))
            create(:generic_page_class_session_association, class_session_id: @class_session.id, generic_page_id: @multiplefib.id)
          end

          it "表示" do
            get :show, params: { id: @multiplefib.id }

            expect(response).to render_template("show")
          end
        end

        context 'パスワード有り' do
          before do
            @multiplefib = create(:multiplefib, course_id: @course.id, start_time: Time.new - 2.day, end_time: Time.new + 1.day, start_pass: "12345",
              file: fixture_file_upload('test.txt', 'text/txt'))
            create(:generic_page_class_session_association, class_session_id: @class_session.id, generic_page_id: @multiplefib.id)
          end

          it "表示" do
            get :show, params: { id: @multiplefib.id }

            expect(response).to render_template("password")
          end

          it "パスワード誤り" do
            post :password, params: { id: @multiplefib.id, class_session_no: @class_session_no, start_pass: "11111" }

            expect(response).to render_template("password")
          end

          it "パスワード一致" do
            post :password, params: { id: @multiplefib.id, class_session_no: @class_session_no, start_pass: "12345" }

            expect(response).to redirect_to multiplefib_path(@multiplefib)
          end
        end

        context '回答' do
          before do
            @multiplefib = create(:multiplefib, course_id: @course.id, start_time: Time.new - 2.day, end_time: Time.new + 1.day,
              file: fixture_file_upload('test.txt', 'text/txt'))
            @parent_question = create(:parent_question)
            3.times do |index|
              create(:question, parent_question_id: @parent_question.id, generic_page_type_cd: @multiplefib.type_cd,
                answer_memo: "#{index}", score: "5", random_cd: "6", answer_in_full_cd: "7")
            end
            @multiplefib.questions << @parent_question
            create(:generic_page_class_session_association, class_session_id: @class_session.id, generic_page_id: @multiplefib.id)
          end

          it "保存" do
            multiplefib_answers = {}
            @parent_question.reload
            @parent_question.questions.each.with_index do |question, index|
              multiplefib_answers[question.id] = index
            end

            expect{
              post :mark, params: { id: @multiplefib.id, answer: multiplefib_answers }
            }.to change(AnswerScore, :count).by(1)

            @multiplefib.reload
            count = @multiplefib.answer_score_histories.where(user_id: student.id).count
            expect(count).to eq 1
            expect(response).to render_template("mark")
          end
        end

        context '回答：期限切れ' do
          before do
            @multiplefib = create(:multiplefib, course_id: @course.id, start_time: Time.new - 2.day, end_time: Time.new - 1.day,
              file: fixture_file_upload('test.txt', 'text/txt'))
            @parent_question = create(:parent_question)
            3.times do |index|
              create(:question, parent_question_id: @parent_question.id, generic_page_type_cd: @multiplefib.type_cd,
                answer_memo: "#{index}", score: "5", random_cd: "6", answer_in_full_cd: "7")
            end
            @multiplefib.questions << @parent_question
            create(:generic_page_class_session_association, class_session_id: @class_session.id, generic_page_id: @multiplefib.id)
          end

          it "保存" do
            multiplefib_answers = {}
            @parent_question.reload
            @parent_question.questions.each.with_index do |question, index|
              multiplefib_answers[question.id] = index
            end

            expect{
              post :mark, params: { id: @multiplefib.id, answer: multiplefib_answers }
            }.to change(AnswerScore, :count).by(0)

            @multiplefib.reload
            count = @multiplefib.answer_score_histories.count
            expect(count).to eq 0
            expect(response).to render_template("redirect")
          end
        end
      end

      context '回答済み：最大回数以内' do
        before do
          @multiplefib = create(:multiplefib, course_id: @course.id, max_count: 3, start_time: Time.new - 2.day, end_time: Time.new + 1.day,
            file: fixture_file_upload('test.txt', 'text/txt'))
          @parent_question = create(:parent_question)
          3.times do |index|
            create(:question, parent_question_id: @parent_question.id, generic_page_type_cd: @multiplefib.type_cd,
              answer_memo: "#{index}", score: "5", random_cd: "6", answer_in_full_cd: "7")
          end
          @multiplefib.questions << @parent_question
          create(:generic_page_class_session_association, class_session_id: @class_session.id, generic_page_id: @multiplefib.id)

          @multiplefib_answers = {}
          @parent_question.reload
          @parent_question.questions.each.with_index do |question, index|
            @multiplefib_answers[question.id] = index
          end

          post :mark, params: { id: @multiplefib.id, answer: @multiplefib_answers }
        end

        it "保存" do
          expect{
            post :mark, params: { id: @multiplefib.id, answer: @multiplefib_answers }
          }.to change(AnswerScore, :count).by(0)

          @multiplefib.reload
          count = @multiplefib.answer_score_histories.count
          expect(count).to eq 2
          expect(response).to render_template("mark")
        end
      end

      context '回答済み：最大回数' do
        before do
          @multiplefib = create(:multiplefib, course_id: @course.id, max_count: 1, start_time: Time.new - 2.day, end_time: Time.new + 1.day,
            file: fixture_file_upload('test.txt', 'text/txt'))
          @parent_question = create(:parent_question)
          3.times do |index|
            create(:question, parent_question_id: @parent_question.id, generic_page_type_cd: @multiplefib.type_cd,
              answer_memo: "#{index}", score: "5", random_cd: "6", answer_in_full_cd: "7")
          end
          @multiplefib.questions << @parent_question
          create(:generic_page_class_session_association, class_session_id: @class_session.id, generic_page_id: @multiplefib.id)

          @multiplefib_answers = {}
          @parent_question.reload
          @parent_question.questions.each.with_index do |question, index|
            @multiplefib_answers[question.id] = index
          end

          post :mark, params: { id: @multiplefib.id, answer: @multiplefib_answers }
        end

        it "保存" do
          expect{
            post :mark, params: { id: @multiplefib.id, answer: @multiplefib_answers }
          }.to change(AnswerScore, :count).by(0)

          @multiplefib.reload
          count = @multiplefib.answer_score_histories.count
          expect(count).to eq 1
          expect(response).to render_template("redirect")
        end
      end
    end
  end
end