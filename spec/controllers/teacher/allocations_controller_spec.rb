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

RSpec.describe Teacher::AllocationsController, type: :controller do
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

  describe 'Teacher 教材割付' do
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

    context "授業別教材割付" do
      before do
        @course = Course.joins(:course_assigned_users).where("course_assigned_users.user_id = ?", teacher.id).first

        @material1 = create(:material, course_id: @course.id, file: fixture_file_upload('test.txt', 'text/txt'))
        @material2 = create(:material, course_id: @course.id, file: fixture_file_upload('test.txt', 'text/txt'))

        @url_link1 = create(:url_link, course_id: @course.id)
        @url_link2 = create(:url_link, course_id: @course.id)

        @compound1 = create(:compound, course_id: @course.id)
        @compound2 = create(:compound, course_id: @course.id)

        @multiplefib1 = create(:multiplefib, course_id: @course.id, file: fixture_file_upload('test.txt', 'text/txt'))
        @multiplefib2 = create(:multiplefib, course_id: @course.id, file: fixture_file_upload('test.txt', 'text/txt'))

        @questionnaire1 = create(:questionnaire, course_id: @course.id)
        @questionnaire2 = create(:questionnaire, course_id: @course.id)

        @essay1 = create(:essay, course_id: @course.id)
        @essay2 = create(:essay, course_id: @course.id)

        @evaluation1 = create(:evaluation, course_id: @course.id)
        @evaluation2 = create(:evaluation, course_id: @course.id)
      end
      
      it "初期表示" do
        get :show, params: { course_id: @course.id }

        expect(response).to render_template("show")
      end

      context "共通ページ" do
        before do
          @class_session_no = 0
        end

        context "新規作成" do
          it "失敗" do
            post :create, params: { course_id: @course.id, class_session: {
              class_session_no: @class_session_no,
              class_session_title: "",
              overview: "",
              class_session_memo_closed: "",
              class_session_memo: ""
            } }
    
            expect(response).to render_template("show")
          end

          it "成功" do
            expect{
              post :create, params: { course_id: @course.id, class_session: {
                class_session_no: @class_session_no,
                class_session_title: "共通ページ",
                overview: "授業概要",
                class_session_memo_closed: "非公開メモ",
                class_session_memo: "授業メモ(公開メモ)"
              } }
            }.to change(ClassSession, :count).by(1)

            expect(response).to redirect_to teacher_allocation_path({course_id: @course.id, session_no: @class_session_no})
          end
        end

        context "更新" do
          before do
            @class_session = create(:class_session, course_id: @course.id, class_session_no: @class_session_no)
          end

          it "失敗" do
            patch :update, params: { id: @class_session.id, class_session: {
              class_session_title: "",
              overview: "",
              class_session_memo_closed: "",
              class_session_memo: ""
            } }
    
            expect(response).to render_template("show")
          end

          it "成功" do
            patch :update, params: { id: @class_session.id, class_session: {
              class_session_title: "update common title",
              overview: "update overview",
              class_session_memo_closed: "update closed memo",
              class_session_memo: "update memo"
            } }

            @class_session.reload
            expect(@class_session.class_session_title).to eq "update common title"
            expect(@class_session.overview).to eq "update overview"

            expect(response).to redirect_to teacher_allocation_path({course_id: @course.id, session_no: @class_session_no})
          end
        end

        context "資料割付" do
          before do
            @class_session = create(:class_session, course_id: @course.id, class_session_no: @class_session_no)
          end

          it "割付成功" do
            expect{
              patch :assign, params: { course_id: @course.id, session_no: @class_session_no,
                allocation: { @material1.id => { assign: "0" }, @material2.id => { assign: "1" } }
              }
            }.to change(GenericPageClassSessionAssociation, :count).by(1)

            expect(response).to render_template("show")
          end

          it "割付解除" do
            create(:generic_page_class_session_association, class_session_id: @class_session.id, generic_page_id: @material1.id)

            expect{
              patch :assign, params: { course_id: @course.id, session_no: @class_session_no,
                allocation: { @material1.id => { assign: "0" }, @material2.id => { assign: "0" } }
              }
            }.to change(GenericPageClassSessionAssociation, :count).by(-1)

            expect(response).to render_template("show")
          end
        end

        context "リンク割付" do
          before do
            @class_session = create(:class_session, course_id: @course.id, class_session_no: @class_session_no)
          end

          it "割付成功" do
            expect{
              patch :assign, params: { course_id: @course.id, session_no: @class_session_no,
                allocation: { @url_link1.id => { assign: "0" }, @url_link2.id => { assign: "1" } }
              }
            }.to change(GenericPageClassSessionAssociation, :count).by(1)

            expect(response).to render_template("show")
          end

          it "割付解除" do
            create(:generic_page_class_session_association, class_session_id: @class_session.id, generic_page_id: @url_link1.id)

            expect{
              patch :assign, params: { course_id: @course.id, session_no: @class_session_no,
                allocation: { @url_link1.id => { assign: "0" }, @url_link2.id => { assign: "0" } }
              }
            }.to change(GenericPageClassSessionAssociation, :count).by(-1)

            expect(response).to render_template("show")
          end
        end

        context "リンク割付" do
          before do
            @class_session = create(:class_session, course_id: @course.id, class_session_no: @class_session_no)
          end

          it "割付成功" do
            expect{
              patch :assign, params: { course_id: @course.id, session_no: @class_session_no,
                allocation: { @url_link1.id => { assign: "0" }, @url_link2.id => { assign: "1" } }
              }
            }.to change(GenericPageClassSessionAssociation, :count).by(1)

            expect(response).to render_template("show")
          end

          it "割付解除" do
            create(:generic_page_class_session_association, class_session_id: @class_session.id, generic_page_id: @url_link1.id)

            expect{
              patch :assign, params: { course_id: @course.id, session_no: @class_session_no,
                allocation: { @url_link1.id => { assign: "0" }, @url_link2.id => { assign: "0" } }
              }
            }.to change(GenericPageClassSessionAssociation, :count).by(-1)

            expect(response).to render_template("show")
          end
        end

        context "アンケート割付" do
          before do
            @class_session = create(:class_session, course_id: @course.id, class_session_no: @class_session_no)
          end

          it "割付成功" do
            expect{
              patch :assign, params: { course_id: @course.id, session_no: @class_session_no,
                allocation: { @questionnaire1.id => { assign: "0" }, @questionnaire2.id => { assign: "1" } }
              }
            }.to change(GenericPageClassSessionAssociation, :count).by(1)

            expect(response).to render_template("show")
          end

          it "割付解除" do
            create(:generic_page_class_session_association, class_session_id: @class_session.id, generic_page_id: @questionnaire1.id)

            expect{
              patch :assign, params: { course_id: @course.id, session_no: @class_session_no,
                allocation: { @questionnaire1.id => { assign: "0" }, @questionnaire2.id => { assign: "0" } }
              }
            }.to change(GenericPageClassSessionAssociation, :count).by(-1)

            expect(response).to render_template("show")
          end
        end

        context "複合式テスト割付" do
          before do
            @class_session = create(:class_session, course_id: @course.id, class_session_no: @class_session_no)
          end

          it "割付成功" do
            expect{
              patch :assign, params: { course_id: @course.id, session_no: @class_session_no,
                allocation: { @compound1.id => { assign: "0" }, @compound2.id => { assign: "1" } }
              }
            }.to change(GenericPageClassSessionAssociation, :count).by(1)

            expect(response).to render_template("show")
          end

          it "割付解除" do
            create(:generic_page_class_session_association, class_session_id: @class_session.id, generic_page_id: @compound1.id)

            expect{
              patch :assign, params: { course_id: @course.id, session_no: @class_session_no,
                allocation: { @compound1.id => { assign: "0" }, @compound2.id => { assign: "0" } }
              }
            }.to change(GenericPageClassSessionAssociation, :count).by(-1)

            expect(response).to render_template("show")
          end
        end

        context "記号式テスト割付" do
          before do
            @class_session = create(:class_session, course_id: @course.id, class_session_no: @class_session_no)
          end

          it "割付成功" do
            expect{
              patch :assign, params: { course_id: @course.id, session_no: @class_session_no,
                allocation: { @multiplefib1.id => { assign: "0" }, @multiplefib2.id => { assign: "1" } }
              }
            }.to change(GenericPageClassSessionAssociation, :count).by(1)

            expect(response).to render_template("show")
          end

          it "割付解除" do
            create(:generic_page_class_session_association, class_session_id: @class_session.id, generic_page_id: @multiplefib1.id)

            expect{
              patch :assign, params: { course_id: @course.id, session_no: @class_session_no,
                allocation: { @multiplefib1.id => { assign: "0" }, @multiplefib2.id => { assign: "0" } }
              }
            }.to change(GenericPageClassSessionAssociation, :count).by(-1)

            expect(response).to render_template("show")
          end
        end

        context "レポート割付" do
          before do
            @class_session = create(:class_session, course_id: @course.id, class_session_no: @class_session_no)
          end

          it "割付成功" do
            expect{
              patch :assign, params: { course_id: @course.id, session_no: @class_session_no,
                allocation: { @essay1.id => { assign: "0" }, @essay1.id => { assign: "1" } }
              }
            }.to change(GenericPageClassSessionAssociation, :count).by(1)

            expect(response).to render_template("show")
          end

          it "割付解除" do
            create(:generic_page_class_session_association, class_session_id: @class_session.id, generic_page_id: @essay1.id)

            expect{
              patch :assign, params: { course_id: @course.id, session_no: @class_session_no,
                allocation: { @essay1.id => { assign: "0" }, @essay1.id => { assign: "0" } }
              }
            }.to change(GenericPageClassSessionAssociation, :count).by(-1)

            expect(response).to render_template("show")
          end
        end

        context "評価記入リスト割付" do
          before do
            @class_session = create(:class_session, course_id: @course.id, class_session_no: @class_session_no)
          end

          it "割付成功" do
            expect{
              patch :assign, params: { course_id: @course.id, session_no: @class_session_no,
                allocation: { @evaluation1.id => { assign: "0" }, @evaluation1.id => { assign: "1" } }
              }
            }.to change(GenericPageClassSessionAssociation, :count).by(1)

            expect(response).to render_template("show")
          end

          it "割付解除" do
            create(:generic_page_class_session_association, class_session_id: @class_session.id, generic_page_id: @evaluation1.id)

            expect{
              patch :assign, params: { course_id: @course.id, session_no: @class_session_no,
                allocation: { @evaluation1.id => { assign: "0" }, @evaluation1.id => { assign: "0" } }
              }
            }.to change(GenericPageClassSessionAssociation, :count).by(-1)

            expect(response).to render_template("show")
          end
        end
      end

      context "授業回ページ" do
        context "新規作成" do
          it "失敗" do
            post :create, params: { course_id: @course.id, class_session: {
              class_session_no: "1",
              class_session_title: "授業第１回",
              class_session_day: "",
              overview: "",
              class_session_memo_closed: "",
              class_session_memo: ""
            } }
    
            expect(response).to render_template("show")
          end

          it "成功" do
            expect{
              post :create, params: { course_id: @course.id, class_session: {
                class_session_no: "1",
                class_session_title: "授業第１回",
                class_session_day: "１回目",
                overview: "授業第１回概要",
                class_session_memo_closed: "非公開メモ",
                class_session_memo: "授業メモ(公開メモ)"
              } }
            }.to change(ClassSession, :count).by(1)

            expect(response).to redirect_to teacher_allocation_path({course_id: @course.id, session_no: "1"})
          end
        end

        context "更新" do
          before do
            @class_session = create(:class_session, course_id: @course.id, class_session_no: "1")
          end

          it "失敗" do
            patch :update, params: { id: @class_session.id, class_session: {
              class_session_title: "",
              class_session_day: "",
              overview: @class_session.overview,
              class_session_memo_closed: @class_session.class_session_memo_closed,
              class_session_memo: @class_session.class_session_memo
            } }
    
            expect(response).to render_template("show")
          end

          it "成功" do
            patch :update, params: { id: @class_session.id, class_session: {
              class_session_title: "update class session 1 title",
              class_session_day: "update class session 1 class_session_day",
              overview: "update class session 1 overview",
              class_session_memo_closed: "update class session 1 closed memo",
              class_session_memo: "update class session 1 memo"
            } }

            @class_session.reload
            expect(@class_session.class_session_title).to eq "update class session 1 title"
            expect(@class_session.class_session_day).to eq "update class session 1 class_session_day"
            expect(@class_session.overview).to eq "update class session 1 overview"

            expect(response).to redirect_to teacher_allocation_path({course_id: @course.id, session_no: "1"})
          end
        end
      end
    end
  end
end