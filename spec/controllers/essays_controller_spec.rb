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

RSpec.describe EssaysController, type: :controller do
  let(:student) { create(:student_user) }

  before do
    @course = create(:course, :year_of_2019)

    @class_session_no = 2

    @class_session = create(:class_session, course_id: @course.id, class_session_no: @class_session_no)
  end

  describe 'レポート' do
    context '生徒ユーザ' do
      before do
        sign_in student

        create(:course_enrollment_user, course_id: @course.id, user_id: student.id)
      end

      context '未提出' do
        context '期限前' do
          before do
            @essay = create(:essay, course_id: @course.id, start_time: Time.new + 1.day, end_time: Time.new + 2.day)
            create(:generic_page_class_session_association, class_session_id: @class_session.id, generic_page_id: @essay.id)
          end

          it "表示" do
            get :show, params: { id: @essay.id }

            expect(assigns(:assignmentEssayStatus)).to eq AssignmentEssay::STATUS_BEFORE_START
            expect(response).to render_template("show")
          end
        end

        context '期限終了' do
          before do
            @essay = create(:essay, course_id: @course.id, start_time: Time.new - 2.day, end_time: Time.new - 1.day)
            create(:generic_page_class_session_association, class_session_id: @class_session.id, generic_page_id: @essay.id)
          end

          it "表示" do
            get :show, params: { id: @essay.id }

            expect(assigns(:assignmentEssayStatus)).to eq AssignmentEssay::STATUS_AFTER_END
            expect(response).to render_template("show")
          end
        end

        context '有効期間内' do
          before do
            @essay = create(:essay, course_id: @course.id, start_time: Time.new - 2.day, end_time: Time.new + 1.day)
            create(:generic_page_class_session_association, class_session_id: @class_session.id, generic_page_id: @essay.id)
          end

          it "表示" do
            get :show, params: { id: @essay.id }

            expect(assigns(:assignmentEssayStatus)).to eq AssignmentEssay::STATUS_NOTPRESENT
            expect(response).to render_template("show")
          end
        end

        context 'パスワード有り' do
          before do
            @essay = create(:essay, course_id: @course.id, start_time: Time.new - 2.day, end_time: Time.new + 1.day, start_pass: "12345")
            create(:generic_page_class_session_association, class_session_id: @class_session.id, generic_page_id: @essay.id)
          end

          it "表示" do
            get :show, params: { id: @essay.id }

            expect(assigns(:assignmentEssayStatus)).to eq AssignmentEssay::STATUS_NOTPRESENT
            expect(response).to render_template("password")
          end

          it "パスワード誤り" do
            post :password, params: { id: @essay.id, class_session_no: @class_session_no, start_pass: "11111" }

            expect(response).to render_template("password")
          end

          it "パスワード一致" do
            post :password, params: { id: @essay.id, class_session_no: @class_session_no, start_pass: "12345" }

            expect(response).to redirect_to essays_path(@essay)
          end
        end
      end

      context '提出済み' do
        context '期限終了' do
          before do
            @essay = create(:essay, course_id: @course.id, start_time: Time.new - 2.day, end_time: Time.new - 1.day)
            create(:generic_page_class_session_association, class_session_id: @class_session.id, generic_page_id: @essay.id)
          end

          it "表示" do
            get :show, params: { id: @essay.id }

            expect(assigns(:assignmentEssayStatus)).to eq AssignmentEssay::STATUS_AFTER_END
            expect(response).to render_template("show")
          end
        end
      end

      context '提出' do
        context '期限内' do
          before do
            @essay = create(:essay, course_id: @course.id, start_time: Time.new - 2.day, end_time: Time.new + 1.day)
            create(:generic_page_class_session_association, class_session_id: @class_session.id, generic_page_id: @essay.id)
          end
  
          it "アップロード成功" do
            post :upload, params: { id: @essay.id, file: fixture_file_upload('test.txt', 'text/txt') }

            expect(response).to redirect_to essays_path(@essay)
          end
        end
  
        context '期限終了' do
          before do
            @essay = create(:essay, course_id: @course.id, start_time: Time.new - 2.day, end_time: Time.new - 1.day)
            create(:generic_page_class_session_association, class_session_id: @class_session.id, generic_page_id: @essay.id)
          end
  
          it "アップロードエラー" do
            post :upload, params: { id: @essay.id, file: fixture_file_upload('test.txt', 'text/txt') }
  
            expect(response).to render_template("error")
          end
        end
      end
  
      context '受理済み：返却の方法ー返却しない' do
        before do
          @essay = create(:essay, course_id: @course.id, start_time: Time.new - 2.day, end_time: Time.new + 1.day)
          create(:generic_page_class_session_association, class_session_id: @class_session.id, generic_page_id: @essay.id)
        end

        it "採点済（再提出）" do
          # アップロード
          post :upload, params: { id: @essay.id, file: fixture_file_upload('test.txt', 'text/txt') }
          answer_score = @course.essays.first.answer_scores.first
          answer_score.total_score = 30
          answer_score.pass_cd = Settings.ANSWERSCORE_PASSCD_UNSUBMITTING
          answer_score.save!(validate: false)

          get :show, params: { id: @essay.id }

          expect(assigns(:assignmentEssayStatus)).to eq AssignmentEssay::STATUS_GRADED_REPRESENT
          expect(assigns(:is_can_submit)).to eq true
          expect(response).to render_template("show")
        end

        it "採点済（受理）" do
          # アップロード
          post :upload, params: { id: @essay.id, file: fixture_file_upload('test.txt', 'text/txt') }
          answer_score = @essay.answer_scores.first
          answer_score.total_score = 100
          answer_score.pass_cd = Settings.ANSWERSCORE_PASSCD_SUBMITTED
          answer_score.save(validate: false)
      
          get :show, params: { id: @essay.id }

          expect(assigns(:assignmentEssayStatus)).to eq AssignmentEssay::STATUS_GRADED_ACCEPTANCE
          expect(assigns(:is_can_submit)).to eq false
          expect(response).to render_template("show")
        end
      end
  
      context '受理済み：返却の方法ー個別に遂次返却' do
        before do
          @essay = create(:essay, course_id: @course.id, start_time: Time.new - 2.day, end_time: Time.new + 1.day,
            assignment_essay_return_method_cd: Settings.GENERICPAGE_RETURN_METHOD_INDIVIDUALLY)
          create(:generic_page_class_session_association, class_session_id: @class_session.id, generic_page_id: @essay.id)
        end

        it "採点済（受理）" do
          # アップロード
          post :upload, params: { id: @essay.id, file: fixture_file_upload('test.txt', 'text/txt') }
          answer_score = @course.essays.first.answer_scores.first
          answer_score.total_score = 100
          answer_score.pass_cd = Settings.ANSWERSCORE_PASSCD_SUBMITTED
          answer_score.save!(validate: false)
          answer_score.latest_comment.return_flag = Settings.ASSIGNMENTESSAYMAILCOMMENT_RETURNFLG_NOTRETURN
          answer_score.latest_comment.save!

          get :show, params: { id: @essay.id }

          expect(assigns(:assignmentEssayStatus)).to eq AssignmentEssay::STATUS_GRADED_ACCEPTANCE_FEEDBACK
          expect(assigns(:is_can_submit)).to eq false
          expect(response).to render_template("show")
        end

        it "返却済（受理）" do
          # アップロード
          post :upload, params: { id: @essay.id, file: fixture_file_upload('test.txt', 'text/txt') }
          answer_score = @essay.answer_scores.first
          answer_score.total_score = 100
          answer_score.pass_cd = Settings.ANSWERSCORE_PASSCD_SUBMITTED
          answer_score.save(validate: false)
          answer_score.latest_comment.return_flag = Settings.ASSIGNMENTESSAYMAILCOMMENT_RETURNFLG_RETURNED
          answer_score.latest_comment.save!
      
          get :show, params: { id: @essay.id }

          expect(assigns(:assignmentEssayStatus)).to eq AssignmentEssay::STATUS_RETURNED_ACCEPTANCE_FEEDBACK
          expect(assigns(:is_can_submit)).to eq false
          expect(response).to render_template("show")
        end
      end
    end
  end
end