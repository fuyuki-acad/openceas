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

RSpec.describe Admin::AccessLogsController, type: :controller do
  describe 'Admin アクセスログ' do
    before do
      @user = User.where(account: 'admin').first
      login_admin @user

      # システムログ
      create_list(:system_log, 2, user_id: @user.id, account: @user.account, password: "", ip: "192.168.0.1")
      create_list(:system_log, 3, user_id: @user.id, account: @user.account, password: "", ip: "192.168.0.2")

      teacher_user = create(:user, :teacher)
      create_list(:system_log, 6, user_id: teacher_user.id, account: teacher_user.account, password: "", ip: "192.168.0.2")

      student_user = create(:user, :student)
      create_list(:system_log, 7, user_id: student_user.id, account: student_user.account, password: "", ip: "192.168.0.3")

      # アクセスログ
      course1 = create(:course, :year_of_2019, course_name: "検索コース名", course_cd: "course-2019", instructor_name: "検索担任者名")
      course2 = create(:course, :year_of_2019, course_name: "検索コース名", course_cd: "course-2019", season_cd: 2, day_cd: 2)
      course3 = create(:course, :year_of_2019, season_cd: 3, day_cd: 3, hour_cd: 3)

      create_list(:course_access_log, 2, course_id: course1.id, user_id: @user.id, ip: "192.168.0.1")
      create_list(:course_access_log, 3, course_id: course1.id, user_id: @user.id, ip: "192.168.0.2")
      create_list(:course_access_log, 2, course_id: course2.id, user_id: @user.id, ip: "192.168.0.1")
      create_list(:course_access_log, 3, course_id: course2.id, user_id: @user.id, ip: "192.168.0.2")
      create_list(:course_access_log, 2, course_id: course3.id, user_id: @user.id, ip: "192.168.0.1")
      create_list(:course_access_log, 3, course_id: course3.id, user_id: @user.id, ip: "192.168.0.2")

      teacher_user = create(:user, :teacher)
      create_list(:course_access_log, 4, course_id: course1.id, user_id: teacher_user.id, ip: "192.168.0.2")
      create_list(:course_access_log, 5, course_id: course2.id, user_id: teacher_user.id, ip: "192.168.0.2")

      student_user = create(:user, :student)
      create_list(:course_access_log, 6, course_id: course1.id, user_id: student_user.id, ip: "192.168.0.3")
      create_list(:course_access_log, 7, course_id: course3.id, user_id: student_user.id, ip: "192.168.0.3")
    end

    it "初期表示" do
      get :index

      expect(response).to render_template("index")
    end

    context "システムログ" do
      it "検索1" do
        get :index, params: { type: "0" }

        expect(assigns(:logs).to_a.count).to eq 18
        expect(response).to render_template("index")
      end

      it "検索2" do
        get :index, params: { type: "0", access_ip: "192.168.0.2" }

        expect(assigns(:logs).to_a.count).to eq 9
        expect(response).to render_template("index")
      end

      it "検索3" do
        get :index, params: { type: "0", role: "2", access_ip: "192.168.0.2" }

        expect(assigns(:logs).to_a.count).to eq 6
        expect(response).to render_template("index")
      end
    end

    context "アクセスログ" do
      it "検索1" do
        get :index, params: { type: "1" }

        expect(assigns(:logs).to_a.count).to eq 37
        expect(response).to render_template("index")
      end

      it "検索2" do
        get :index, params: { type: "1", access_ip: "192.168.0.2" }

        expect(assigns(:logs).to_a.count).to eq 18
        expect(response).to render_template("index")
      end

      it "検索3" do
        get :index, params: { type: "1", role: "2", access_ip: "192.168.0.2" }

        expect(assigns(:logs).to_a.count).to eq 9
        expect(response).to render_template("index")
      end

      it "検索4" do
        get :index, params: { type: "1", search_type: "0", keyword: "検索コース名", day: "2" }

        expect(assigns(:logs).to_a.count).to eq 10
        expect(response).to render_template("index")
      end

      it "検索5" do
        get :index, params: { type: "1", search_type: "2", keyword: "course-2019", season: "2" }

        expect(assigns(:logs).to_a.count).to eq 10
        expect(response).to render_template("index")
      end

      it "検索6" do
        get :index, params: { type: "1", search_type: "1", keyword: "検索担任者名", role: "1" }

        expect(assigns(:logs).to_a.count).to eq 5
        expect(response).to render_template("index")
      end
    end
  end
end