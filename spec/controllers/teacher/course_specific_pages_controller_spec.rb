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

RSpec.describe Teacher::CourseSpecificPagesController, type: :controller do
  let(:teacher) { create(:teacher_user) }

  before do
    sign_in teacher

    create_list(:course, 2, :year_of_2018)
    create_list(:course, 3, :year_of_2019)
    create_list(:course, 4, :year_of_2019, course_name: "検索コース名")

    Course.all.each.with_index do |course, index|
      create(:course_assigned_user, course_id: course.id, user_id: teacher.id)
    end

    other_teacher = create(:teacher_user)
    #対象外（非アサイン）
    create_list(:course, 5, :year_of_2019, course_name: "検索コース名").each.with_index do |course, index|
      create(:course_assigned_user, course_id: course.id, user_id: other_teacher.id)
    end
  end

  describe 'Teacher 科目独自のページ' do
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

    context "ファイルアップロード" do
      before do
        @course = Course.joins(:course_assigned_users).where("course_assigned_users.user_id = ?", teacher.id).first
      end
      
      it "初期表示" do
        get :show, params: { course_id: @course.id }

        expect(response).to render_template("show")
      end

      context "アップロード" do
        before do
          @course = create(:course, :year_of_2019)
          create(:course_assigned_user, course_id: @course.id, user_id: teacher.id)
        end
  
        it "失敗" do
          post :upload, params: { course_id: @course, file: "" }
  
          expect(response).to render_template("show")
        end
  
        it "成功" do
          post :upload, params: { course_id: @course, file: fixture_file_upload('test_html.zip', 'application/zip') }
    
          expect(response).to redirect_to teacher_course_specific_page_path(@course.id)
        end
      end
    end
  end
end