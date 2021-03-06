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

RSpec.describe OpenCoursesController, type: :controller do
  let(:admin) { User.where(account: 'admin').first }
  let(:teacher) { create(:teacher_user) }
  let(:student) { create(:student_user) }

  before do
    sign_in teacher

    create_list(:course, 2, :year_of_2018, open_course_flag: Settings.COURSE_OPENCOURSEFLG_PUBLIC)
    create_list(:course, 3, :year_of_2019, open_course_flag: Settings.COURSE_OPENCOURSEFLG_PUBLIC)
    create_list(:course, 4, :year_of_2019, open_course_flag: Settings.COURSE_OPENCOURSEFLG_PUBLIC, course_name: "検索コース名").each.with_index do |course, index|
      #担任者アサイン済み
      create(:open_course_assigned_user, course_id: course.id, user_id: teacher.id)
    end
    create_list(:course, 5, :year_of_2019, open_course_flag: Settings.COURSE_OPENCOURSEFLG_PUBLIC, course_name: "検索コース名").each.with_index do |course, index|
      #生徒アサイン済み
      create(:open_course_assigned_user, course_id: course.id, user_id: student.id)
    end
    #対象外（非公開コース）
    create_list(:course, 6, :year_of_2019, open_course_flag: Settings.COURSE_OPENCOURSEFLG_PRIVATE, course_name: "検索コース名")
  end

  describe '公開科目一覧' do
    context "管理者ユーザ" do
      before do
        sign_in admin
      end

      it "初期表示" do
        get :index

        expect(assigns(:courses).count).to eq 14
        expect(response).to render_template("index")
      end

      it "検索" do
        get :index, params: { key_word: "検索コース名" }

        expect(assigns(:courses).to_a.count).to eq 9
        expect(response).to render_template("index")
      end
    end

    context "担任者ユーザ" do
      before do
        sign_in teacher
      end

      it "初期表示" do
        get :index

        expect(assigns(:courses).count).to eq 10
        expect(assigns(:assigned_courses).to_a.count).to eq 4
        expect(response).to render_template("index")
      end

      it "検索" do
        get :index, params: { key_word: "検索コース名" }

        expect(assigns(:courses).to_a.count).to eq 5
        expect(assigns(:assigned_courses).to_a.count).to eq 4
        expect(response).to render_template("index")
      end

      it "割付" do
        assign_courses = create_list(:course, 2, :year_of_2019, open_course_flag: Settings.COURSE_OPENCOURSEFLG_PUBLIC)
        post :assign, params: { assign: { assign_courses[0].id => assign_courses[0].id, assign_courses[1].id => assign_courses[1].id } }

        expect(assigns(:courses).count).to eq 10
        expect(assigns(:assigned_courses).to_a.count).to eq 6
        expect(response).to render_template("index")
      end

      it "解除" do
        open_course_assigned_users = teacher.open_course_assigned_users
        post :assign, params: { release: { 
          open_course_assigned_users[0].course_id => open_course_assigned_users[0].course_id,
          open_course_assigned_users[1].course_id => open_course_assigned_users[1].course_id
        } }

        expect(assigns(:courses).count).to eq 12
        expect(assigns(:assigned_courses).to_a.count).to eq 2
        expect(response).to render_template("index")
      end
    end

    context "生徒ユーザ" do
      before do
        sign_in student
      end

      it "初期表示" do
        post :index

        expect(assigns(:courses).count).to eq 9
        expect(assigns(:assigned_courses).to_a.count).to eq 5
        expect(response).to render_template("index")
      end

      it "検索" do
        get :index, params: { key_word: "検索コース名" }

        expect(assigns(:courses).to_a.count).to eq 4
        expect(assigns(:assigned_courses).to_a.count).to eq 5
        expect(response).to render_template("index")
      end

      it "割付" do
        assign_courses = create_list(:course, 2, :year_of_2019, open_course_flag: Settings.COURSE_OPENCOURSEFLG_PUBLIC)
        post :assign, params: { assign: { assign_courses[0].id => assign_courses[0].id, assign_courses[1].id => assign_courses[1].id } }

        expect(assigns(:courses).count).to eq 9
        expect(assigns(:assigned_courses).to_a.count).to eq 7
        expect(response).to render_template("index")
      end

      it "解除" do
        open_course_assigned_users = student.open_course_assigned_users
        post :assign, params: { release: { 
          open_course_assigned_users[0].course_id => open_course_assigned_users[0].course_id,
          open_course_assigned_users[1].course_id => open_course_assigned_users[1].course_id
        } }

        expect(assigns(:courses).count).to eq 11
        expect(assigns(:assigned_courses).to_a.count).to eq 3
        expect(response).to render_template("index")
      end
    end
  end
end