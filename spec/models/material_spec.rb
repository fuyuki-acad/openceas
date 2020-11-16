require 'rails_helper'

RSpec.describe GenericPage, type: :model do
  before do
    @course = create(:course, :year_of_2019)
  end

  describe 'バリデーション' do
    before do
      @material = build(:material, course_id: @course.id, file: fixture_file_upload('test.txt', 'text/txt'),
        upload_flag: GenericPage::TYPE_FILEUPLOAD)
    end

    it "正常" do
      @material.valid?
      expect(@material.errors.count).to eq 0
      expect(@material).to be_valid
    end

    it "タイトル" do
      @material.generic_page_title = nil
      @material.valid?
      expect(@material.errors.messages[:base]).to include I18n.t("page_management.MAT_REG_MAT_PAGEMANAGEMENT_ERRORTYPE1")
    end

    it "ファイル" do
      #ファイル未設定
      @material.file = nil
      @material.valid?
      expect(@material.errors.messages[:file]).to include I18n.t("page_management.MAT_REG_MAT_PAGEMANAGEMENT_ERRORTYPE2")

      #ファイル拡張子なし
      @material.file = fixture_file_upload('test', 'text/txt')
      @material.valid?
      expect(@material.errors.messages[:file_name]).to include I18n.t("page_management.MAT_REG_MAT_PAGEMANAGEMENT_ERRORTYPE3")

      #ファイル拡張子（exe）
      @material.file = fixture_file_upload('test.exe', 'text/txt')
      @material.valid?
      expect(@material.errors.messages[:file_name]).to include I18n.t("page_management.MAT_REG_MAT_PAGEMANAGEMENT_ERRORTYPE4")
    end

    it "ファイル解凍" do
      @material.extract_flag = "true"

      #ファイル名対象外
      @material.file = fixture_file_upload('test.txt', 'text/txt')
      @material.valid?
      expect(@material.errors.messages[:file_name]).to include I18n.t("page_management.MAT_REG_MAT_PAGEMANAGEMENT_ERRORTYPE5")

      #解凍失敗（対象外ファイル）
      @material.file = fixture_file_upload('test_fail.zip', 'text/txt')
      expect {
        @material.valid?
      }.to raise_error(Exception)

      #解凍成功
      @material.file = fixture_file_upload('test_html.zip', 'text/txt')
      @material.valid?
      expect(@material.errors.count).to eq 0
      expect(@material).to be_valid
    end

    it "html" do
      @html_material = build(:material, course_id: @course.id, upload_flag: GenericPage::TYPE_CREATEHTML)

      #ファイル名未設定
      @html_material.valid?
      expect(@html_material.errors.messages[:base]).to include I18n.t("page_management.MAT_REG_MAT_PAGEMANAGEMENT_ERRORTYPE2")

      #ファイル名対象外
      @html_material.file_name = "+123.123"
      @html_material.valid?
      expect(@html_material.errors.messages[:base]).to include I18n.t("page_management.MAT_REG_MAT_PAGEMANAGEMENT_ERRORTYPE16")

      #ファイル名対象
      @html_material.file_name = "html_text"
      @html_material.valid?
      expect(@material.errors.count).to eq 0
    end

    it "公開メモ" do
      @material.material_memo = "あ" * 4097
      @material.valid?
      expect(@material.errors.messages[:base]).to include I18n.t("page_management.MAT_REG_MAT_PAGEMANAGEMENT_COMMENT_TOO_LONG")

      @material.material_memo = "あ" * 4096
      @material.valid?
      expect(@material.errors.count).to eq 0
    end

    it "非公開メモ" do
      @material.material_memo_closed = "あ" * 4097
      @material.valid?
      expect(@material.errors.messages[:base]).to include I18n.t("page_management.MAT_REG_MAT_PAGEMANAGEMENT_COMMENT_TOO_LONG2")

      @material.material_memo_closed = "あ" * 4096
      @material.valid?
      expect(@material.errors.count).to eq 0
    end
  end

  describe '登録' do
    it "ファイルアップロード成功" do
      file_name = 'test.txt'
      material = build(:material, course_id: @course.id, file: fixture_file_upload('test.txt', 'text/txt'),
        upload_flag: GenericPage::TYPE_FILEUPLOAD)

      expect{
        material.save
      }.to change(GenericPage, :count).by(1)

      expect(material.file_name).to eq file_name
    end

    it "html作成成功" do
      file_name = 'test'
      material = build(:material, course_id: @course.id, file_name: file_name, upload_flag: GenericPage::TYPE_CREATEHTML,
        html_text: "test text")
  
      expect{
        material.save
      }.to change(GenericPage, :count).by(1)

      expect(material.file_name).to eq file_name + ".html"
    end
  end

  describe '更新' do
    it "ファイルアップロード成功" do
      file_name = 'test_update.txt'
      material = create(:material, course_id: @course.id, file: fixture_file_upload('test.txt', 'text/txt'),
        upload_flag: GenericPage::TYPE_FILEUPLOAD)

      material.file = fixture_file_upload(file_name, 'text/txt')
      expect{
        material.save
      }.to change(GenericPage, :count).by(0)

      expect(material.file_name).to eq file_name
    end

    it "ファイルアップロード成功" do
      file_name = 'test_update.txt'
      material = create(:material, course_id: @course.id, file_name: file_name, upload_flag: GenericPage::TYPE_CREATEHTML,
        html_text: "test text")
  
      material.file = fixture_file_upload(file_name, 'text/txt')
      expect{
        material.save
      }.to change(GenericPage, :count).by(0)

      expect(material.file_name).to eq file_name
    end
  end

  describe 'コピー' do
    before do
      @material = create(:material, course_id: @course.id, file: fixture_file_upload('test.txt', 'text/txt'),
        upload_flag: GenericPage::TYPE_FILEUPLOAD)

      @other_course = create(:course, :year_of_2019)
    end

    it "成功" do
      new_material = @material.copy(@other_course)

      expect(@material.course_id).to_not eq new_material.course_id
      expect(@material.get_material_file_path).to_not eq new_material.get_material_file_path

      expect(@material.type_cd).to eq new_material.type_cd
      expect(@material.generic_page_title).to eq new_material.generic_page_title
      expect(@material.upload_flag).to eq new_material.upload_flag
      expect(@material.file_name).to eq new_material.file_name
      expect(@material.extract_flag).to eq new_material.extract_flag
      expect(@material.material_memo).to eq new_material.material_memo
    end
  end
end