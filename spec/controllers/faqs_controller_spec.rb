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

RSpec.describe FaqsController, type: :controller do
  let(:admin) { User.where(account: 'admin').first }
  let(:teacher) { create(:teacher_user) }
  let(:student) { create(:student_user) }

  before do
    course1 = create(:course, :year_of_2019, course_name: "検索コース名", course_cd: "course-2019", season_cd: 2, day_cd: 2)
    course2 = create(:course, :year_of_2019, season_cd: 3, day_cd: 3, hour_cd: 3)
    course3 = create(:course, :year_of_2019)

    create(:course_assigned_user, course_id: course1.id, user_id: teacher.id)
    create_list(:faq, 2, course_id: course1.id, user_id: student.id, open_flag: true, response_flag: true).each do |faq|
      create(:faq_answer, faq_id: faq.id)
    end
    #対象外(open_flag:false)
    create_list(:faq, 3, course_id: course1.id, user_id: student.id, open_flag: false, response_flag: true).each do |faq|
      create(:faq_answer, faq_id: faq.id)
    end

    create(:course_enrollment_user, course_id: course2.id, user_id: student.id)
    create_list(:faq, 4, course_id: course2.id, user_id: student.id, open_flag: true, response_flag: true).each do |faq|
      create(:faq_answer, faq_id: faq.id)
    end
    #対象外(response_flag:false)
    create_list(:faq, 5, course_id: course2.id, user_id: student.id, open_flag: true, response_flag: false).each do |faq|
      create(:faq_answer, faq_id: faq.id)
    end

    create_list(:faq, 6, course_id: course3.id, user_id: student.id, open_flag: true, response_flag: true).each do |faq|
      create(:faq_answer, faq_id: faq.id)
    end
    #対象外(open_flag:false, response_flag:false)
    create_list(:faq, 7, course_id: course3.id, user_id: student.id, open_flag: false, response_flag: false).each do |faq|
      create(:faq_answer, faq_id: faq.id)
    end
  end

  describe 'お知らせ' do
    context "管理者ユーザ" do
      before do
        sign_in admin
      end

      it "初期表示" do
        get :index

        expect(assigns(:faq_answers).count).to eq 12
        expect(response).to render_template("index")
      end
    end

    context "担任者ユーザ" do
      before do
        sign_in teacher
      end

      it "初期表示" do
        get :index

        expect(assigns(:faq_answers).count).to eq 2
        expect(response).to render_template("index")
      end
    end

    context "生徒ユーザ" do
      before do
        sign_in student
      end

      it "初期表示" do
        get :index

        expect(assigns(:faq_answers).count).to eq 4
        expect(response).to render_template("index")
      end
    end
  end
end