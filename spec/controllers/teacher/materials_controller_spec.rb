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

RSpec.describe Teacher::MaterialsController, type: :controller do
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

  describe 'Teacher 授業資料' do
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

    context "授業資料登録" do
      before do
        @course = Course.first
      end
      
      it "初期表示" do
        get :show, params: { course_id: @course.id }

        expect(response).to render_template("show")
      end

      context "新規登録" do
        it "画面表示" do
          get :new, params: { course_id: @course.id }

          expect(response).to render_template("new")
        end

        it "失敗" do
          post :create, params: { course_id: @course.id, generic_page: {
            course_id: @course.id,
            type_cd: Settings.GENERICPAGE_TYPECD_MATERIALCODE,
            generic_page_title: "",
            upload_flag: "",
            file: "",
            extract_flag: "",
            material_memo_closed: "",
            material_memo: ""
           } }
  
          expect(response).to render_template("new")
        end

        it "ファイルアップロード成功" do
          expect{
            post :create, params: { course_id: @course.id, generic_page: {
              course_id: @course.id,
              type_cd: Settings.GENERICPAGE_TYPECD_MATERIALCODE,
              generic_page_title: "授業資料タイトル",
              upload_flag: GenericPage::TYPE_FILEUPLOAD,
              file: fixture_file_upload('test.txt', 'text/txt'),
              extract_flag: false,
              material_memo_closed: "非公開メモ",
              material_memo: "メモ"
             } }
          }.to change(GenericPage, :count).by(1)

          expect(response).to redirect_to teacher_material_path(@course.id)
        end

        it "HTMLファイル作成画面遷移" do
          post :create, params: { course_id: @course.id, generic_page: {
            course_id: @course.id,
            type_cd: Settings.GENERICPAGE_TYPECD_MATERIALCODE,
            generic_page_title: "授業資料タイトル（HTMLファイル作成）",
            upload_flag: GenericPage::TYPE_CREATEHTML,
            file_name: "test_html",
            extract_flag: false,
            material_memo_closed: "非公開メモ",
            material_memo: "メモ"
          } }

          expect(response).to render_template("create_html")
        end

        it "HTMLファイル作成失敗（html_text空白）" do
          post :create_html, params: { course_id: @course.id, generic_page: {
            course_id: @course.id,
            type_cd: Settings.GENERICPAGE_TYPECD_MATERIALCODE,
            generic_page_title: "授業資料タイトル（HTMLファイル作成）",
            upload_flag: GenericPage::TYPE_CREATEHTML,
            file_name: "test_html",
            html_text: "",
            extract_flag: false,
            material_memo_closed: "非公開メモ",
            material_memo: "メモ"
            } }
          
          expect(response).to render_template("create_html")
        end

        it "HTMLファイル作成成功" do
          expect{
            post :create_html, params: { course_id: @course.id, generic_page: {
              course_id: @course.id,
              type_cd: Settings.GENERICPAGE_TYPECD_MATERIALCODE,
              generic_page_title: "授業資料タイトル（HTMLファイル作成）",
              upload_flag: GenericPage::TYPE_CREATEHTML,
              file_name: "test_html",
              html_text: "<h4>test html</h4><br><p>create html file</p>",
              extract_flag: false,
              material_memo_closed: "非公開メモ",
              material_memo: "メモ"
             } }
          }.to change(GenericPage, :count).by(1)
          
          expect(response).to redirect_to teacher_material_path(@course.id)
        end
      end

      context "編集" do
        let(:material) { create(:material, course_id: @course.id, file: fixture_file_upload('test.txt', 'text/txt')) }

        it "画面表示" do
          get :edit, params: { id: material.id }

          expect(response).to render_template("edit")
        end

        it "失敗" do
          post :update, params: { id: material.id, generic_page: {
            course_id: material.course.id,
            type_cd: Settings.GENERICPAGE_TYPECD_MATERIALCODE,
            generic_page_title: "",
            material_memo_closed: "",
            material_memo: ""
           } }
  
          expect(response).to render_template("edit")
        end

        it "更新成功" do
          post :update, params: { id: material.id, generic_page: {
            course_id: material.course.id,
            type_cd: Settings.GENERICPAGE_TYPECD_MATERIALCODE,
            generic_page_title: "update title",
            material_memo_closed: "",
            material_memo: "update material_memo"
            } }

          material.reload
          expect(material.generic_page_title).to eq("update title")
          expect(material.material_memo).to eq("update material_memo")
          expect(response).to redirect_to teacher_material_path(@course.id)
        end
      end

      context "削除" do
        before do
          @material1 = create(:material, course_id: @course.id, file: fixture_file_upload('test.txt', 'text/txt'))
          @material2 = create(:material, course_id: @course.id, file: fixture_file_upload('test.txt', 'text/txt'))
        end
  
        it "成功" do
          expect{
            delete :destroy, params: { course_id: @course.id, material: { @material1.id => @material1.id, @material2.id => @material2.id } }
          }.to change(GenericPage, :count).by(-2)
  
          expect(response).to redirect_to teacher_material_path(@course.id)
        end
      end

      context "一括コピー" do
        let(:target_course) { Course.where(course_name: "検索コース名").first }

        before do
          @materials = create_list(:material, 2, course_id: @course.id, file: fixture_file_upload('test.txt', 'text/txt'))
        end
  
        it "科目選択画面" do
          material = @materials[0]
          get :select_copy_to, params: { id: material.id }
  
          expect(response).to render_template("select_copy_to")
        end

        it "失敗：科目未選択" do
          material = @materials[0]
          post :copy_to, params: { id: material.id, dest: { } }
  
          expect(response).to redirect_to teacher_select_copy_to_material_path(material.id)
        end

        it "成功" do
          material = @materials[0]
          expect{
            post :copy_to, params: { id: material.id, dest: { target_course.id => target_course.id } }
          }.to change(GenericPage, :count).by(1)
  
          expect(response).to redirect_to teacher_material_path(@course.id)
        end
      end

      context "他の科目からコピー" do
        let(:target_course) { Course.where(course_name: "検索コース名").first }

        before do
          @materials = create_list(:material, 3, course_id: @course.id, file: fixture_file_upload('test.txt', 'text/txt'))
        end

        it "初期表示" do
          get :select_course, params: { course_id: target_course.id }
  
          expect(response).to render_template("select_course")
        end

        it "科目選択" do
          get :select_page, params: { course_id: target_course.id, origin_id: @course.id }
  
          expect(assigns(:origin).materials.count).to eq 3
          expect(response).to render_template("select_page")
        end

        it "授業資料コピー" do

          expect{
              post :copy, params: { course_id: target_course.id, origin_id: @course.id, 
              material: { @materials[0].id => @materials[0].id, @materials[1].id => @materials[1].id } }
          }.to change(GenericPage, :count).by(2)
  
          expect(response).to redirect_to teacher_material_path(target_course.id)

          target_course.reload
          expect(target_course.materials.count).to eq 2
        end
      end
    end

    context "リンク登録" do
      before do
        @course = Course.first
      end
      
      context "新規登録" do
        it "画面表示" do
          get :new_url, params: { course_id: @course.id }

          expect(response).to render_template("new_url")
        end

        it "失敗" do
          post :create, params: { course_id: @course.id, generic_page: {
            course_id: @course.id,
            type_cd: Settings.GENERICPAGE_TYPECD_URLCODE,
            generic_page_title: "",
            url_content: "",
            material_memo: "",
            content: ""
           } }
  
          expect(response).to render_template("new_url")
        end

        it "リンク作成成功" do
          expect{
            post :create, params: { course_id: @course.id, generic_page: {
              course_id: @course.id,
              type_cd: Settings.GENERICPAGE_TYPECD_URLCODE,
              generic_page_title: "新規リンク",
              url_content: "https://www.google.co.jp/",
              material_memo: "公開メモ",
              content: ""
            } }
          }.to change(GenericPage, :count).by(1)

          expect(response).to redirect_to teacher_material_path(@course.id)
        end

        it "リンク組込成功" do
          expect{
            post :create, params: { course_id: @course.id, generic_page: {
              course_id: @course.id,
              type_cd: Settings.GENERICPAGE_TYPECD_URLCODE,
              generic_page_title: "新規組込リンク",
              url_content: "",
              material_memo: "公開メモ",
              content: "<a hred='https://www.google.co.jp/'>リンク</a>"
            } }
          }.to change(GenericPage, :count).by(1)

          expect(response).to redirect_to teacher_material_path(@course.id)
        end
      end

      context "編集" do
        let(:url_link) { create(:url_link, course_id: @course.id) }

        it "画面表示" do
          get :edit_url, params: { id: url_link.id }

          expect(response).to render_template("edit_url")
        end

        it "失敗" do
          post :update, params: { id: url_link.id, generic_page: {
            course_id: @course.id,
            type_cd: Settings.GENERICPAGE_TYPECD_URLCODE,
            generic_page_title: "",
            url_content: "",
            material_memo: "",
            content: ""
          } }

          expect(response).to render_template("edit_url")
        end

        it "更新成功" do
          post :update, params: { id: url_link.id, generic_page: {
            course_id: @course.id,
            type_cd: Settings.GENERICPAGE_TYPECD_URLCODE,
            generic_page_title: "update url link",
            url_content: "https://www.yahoo.co.jp",
            material_memo: "update link memo",
            content: ""
          } }

          url_link.reload
          expect(url_link.generic_page_title).to eq("update url link")
          expect(url_link.url_content).to eq("https://www.yahoo.co.jp")
          expect(url_link.material_memo).to eq("update link memo")
          expect(response).to redirect_to teacher_material_path(@course.id)
        end
      end

      context "削除" do
        before do
          @url_link1 = create(:url_link, course_id: @course.id)
          @url_link2 = create(:url_link, course_id: @course.id)
        end

        it "成功" do
          expect{
            delete :destroy, params: { course_id: @course.id, url: { @url_link1.id => @url_link1.id, @url_link2.id => @url_link2.id } }
          }.to change(GenericPage, :count).by(-2)

          expect(response).to redirect_to teacher_material_path(@course.id)
        end
      end

      context "他の科目からコピー" do
        let(:target_course) { Course.where(course_name: "検索コース名").first }

        before do
          @url_links = create_list(:url_link, 3, course_id: @course.id)
        end

        it "初期表示" do
          get :select_url_course, params: { course_id: target_course.id }

          expect(response).to render_template("select_url_course")
        end

        it "科目選択" do
          get :select_url_page, params: { course_id: target_course.id, origin_id: @course.id }

          expect(assigns(:origin).urls.count).to eq 3
          expect(response).to render_template("select_url_page")
        end

        it "授業資料コピー" do

          expect{
              post :url_copy, params: { course_id: target_course.id, origin_id: @course.id, 
              url: { @url_links[0].id => @url_links[0].id, @url_links[1].id => @url_links[1].id } }
          }.to change(GenericPage, :count).by(2)

          expect(response).to redirect_to teacher_material_path(target_course.id)

          target_course.reload
          expect(target_course.urls.count).to eq 2
        end
      end
    end
  end
end
