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

RSpec.describe Teacher::AnnouncementsController, type: :controller do
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

  describe 'Teacher お知らせ／メール' do
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
    
    context "お知らせ登録" do
      before do
        @course = Course.first
        @announcements = create_list(:announcement, 3, course_id: @course.id)
      end

      context "新規登録" do
        it "画面表示" do
          get :new, params: { course_id: @course.id }

          expect(response).to render_template("new")
        end

        it "失敗" do
          post :create, params: { course_id: @course.id, announcement: {
            course_id: @course.id,
            subject: "",
            content: "",
            announcement_state: "1"
          } }
  
          expect(response).to render_template("new")
        end

        it "成功" do
          expect{
            post :create, params: { course_id: @course.id, announcement: {
              course_id: @course.id,
              subject: "お知らせタイトル",
              content: "お知らせ内容",
              announcement_state: "1"
              } }
          }.to change(Announcement, :count).by(1)

          expect(response).to redirect_to teacher_announcements_path
        end
      end
      
      it "お知らせ閲覧" do
        get :show, params: { course_id: @course.id }

        expect(assigns(:course).announcements.count).to eq 3
        expect(response).to render_template("show")
      end

      context "編集" do
        it "画面表示" do
          get :edit, params: { id: @announcements[0].id }

          expect(response).to render_template("edit")
        end

        it "失敗" do
          post :update, params: { id: @announcements[0].id, announcement: {
            course_id: @course.id,
            subject: "",
            content: "",
            announcement_state: "1"
          } }

          expect(response).to render_template("edit")
        end

        it "更新成功" do
          post :update, params: { id: @announcements[0].id, announcement: {
            course_id: @course.id,
            subject: "update subject",
            content: "update content",
            announcement_state: "1"
          } }

          @announcements[0].reload
          expect(@announcements[0].subject).to eq("update subject")
          expect(@announcements[0].content).to eq("update content")
          expect(response).to redirect_to teacher_announcement_path(@course.id)
        end
      end

      context "削除" do
        it "成功" do
          expect{
            delete :destroy, params: { course_id: @course.id,
              announcement: { @announcements[0].id => @announcements[0].id, @announcements[1].id => @announcements[1].id }
            }
          }.to change(Announcement, :count).by(-2)

          @course.reload
          expect(@course.announcements.count).to eq 1
          expect(response).to redirect_to teacher_announcement_path(@course.id)
        end
      end
    end
  end
end