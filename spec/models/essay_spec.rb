require 'rails_helper'

RSpec.describe Essay, type: :model do
  before do
    User.current_user = create(:teacher_user)
    @course = create(:course, :year_of_2019)
  end

  describe 'バリデーション' do
    before do
      @essay = build(:essay, course_id: @course.id)
    end

    it "正常" do
      @essay.valid?
      expect(@essay.errors.count).to eq 0
      expect(@essay).to be_valid
    end

    it "タイトル" do
      @essay.generic_page_title = nil
      @essay.valid?
      expect(@essay.errors.messages[:base]).to include I18n.t("common.COMMON_SUBJECTCHECK")
    end

    it "ファイル" do
      @essay.upload_flag = GenericPage::TYPE_FILEUPLOAD

      #ファイル未設定
      @essay.file = nil
      @essay.valid?
      expect(@essay.errors.messages[:file]).to include I18n.t("page_management.MAT_REG_MAT_PAGEMANAGEMENT_ERRORTYPE2")

      #ファイル拡張子なし
      @essay.file = fixture_file_upload('test', 'text/txt')
      @essay.valid?
      expect(@essay.errors.messages[:file]).to include I18n.t("materials_registration.MAT_REG_MAT_PAGEMANAGEMENT_ERRORTYPE3")

      #ファイル拡張子（exe）
      @essay.file = fixture_file_upload('test.exe', 'text/txt')
      @essay.valid?
      expect(@essay.errors.messages[:file]).to include I18n.t("materials_registration.MAT_REG_MAT_PAGEMANAGEMENT_ERRORTYPE4")

      @essay.file = fixture_file_upload('test.txt', 'text/txt')
      @essay.valid?
      expect(@essay.errors.count).to eq 0
    end

    it "開始パスワード" do
      @essay.start_pass = "./123sa"
      @essay.valid?
      expect(@essay.errors.messages[:base]).to include I18n.t("materials_registration.COMMONMATERIALSREGISTRATION_ERRORTYPE3")

      @essay.start_pass = "pass12345"
      @essay.valid?
      expect(@essay.errors.count).to eq 0
    end

    it "開始終了日時" do
      @essay.start_time = ""
      @essay.end_time = "2020/01/02"
      @essay.valid?
      expect(@essay.errors.messages[:base]).to include I18n.t("materials_registration.COMMONMATERIALSREGISTRATION_ERRORTYPE2")

      @essay.start_time = "2020/01/01"
      @essay.end_time = ""
      @essay.valid?
      expect(@essay.errors.messages[:base]).to include I18n.t("materials_registration.COMMONMATERIALSREGISTRATION_ERRORTYPE2")

      @essay.start_time = "2020/01/02"
      @essay.end_time = "2020/01/01"
      @essay.valid?
      expect(@essay.errors.messages[:start_time]).to include I18n.t("materials_registration.COMMONMATERIALSREGISTRATION_ERRORTYPE2")

      @essay.start_time = "2020/01/01"
      @essay.end_time = "2020/01/02"
      @essay.valid?
      expect(@essay.errors.count).to eq 0
    end

    it "公開メモ" do
      @essay.material_memo = "あ" * 4097
      @essay.valid?
      expect(@essay.errors.messages[:base]).to include I18n.t("page_management.MAT_REG_MAT_PAGEMANAGEMENT_COMMENT_TOO_LONG")

      @essay.material_memo = "あ" * 4096
      @essay.valid?
      expect(@essay.errors.count).to eq 0
    end
  end

  describe '登録' do
    it "ファイルアップロード成功" do
      file_name = 'test.txt'
      essay = build(:essay, course_id: @course.id, file: fixture_file_upload('test.txt', 'text/txt'),
        upload_flag: GenericPage::TYPE_FILEUPLOAD)

      expect{
        essay.save
      }.to change(GenericPage, :count).by(1)

      expect(essay.file_name).to eq file_name
    end
  end

  describe '更新' do
    it "ファイルアップロード成功" do
      file_name = 'test_update.txt'
      essay = create(:essay, course_id: @course.id, file: fixture_file_upload('test.txt', 'text/txt'),
        upload_flag: GenericPage::TYPE_FILEUPLOAD)

        essay.file = fixture_file_upload(file_name, 'text/txt')
      expect{
        essay.save
      }.to change(GenericPage, :count).by(0)

      expect(essay.file_name).to eq file_name
    end
  end

  describe '他コースへコピー' do
    before do
      @essay = create(:essay, course_id: @course.id, file: fixture_file_upload('test.txt', 'text/txt'),
        upload_flag: GenericPage::TYPE_FILEUPLOAD,
        max_count: 2,
        pass_grade: 70,
        assignment_essay_return_method_cd: Settings.GENERICPAGE_RETURN_METHOD_NOT_RETURN,
        start_pass: "pass12345",
        start_time: "2020/01/01",
        end_time: "2020/01/31",
        pre_grading_enable_flag: Settings.GENERICPAGE_PREGRADINGENABLEFLG_ON
      )

      @other_course = create(:course, :year_of_2019)
    end

    it "成功" do
      new_essay = @essay.copy(@other_course)

      expect(@essay.course_id).to_not eq new_essay.course_id
      expect(@essay.get_material_file_path).to_not eq new_essay.get_material_file_path

      expect(@essay.type_cd).to eq new_essay.type_cd
      expect(@essay.generic_page_title).to eq new_essay.generic_page_title
      expect(@essay.assignment_essay_return_method_cd).to eq new_essay.assignment_essay_return_method_cd
      expect(@essay.max_count).to eq new_essay.max_count
      expect(@essay.pass_grade).to eq new_essay.pass_grade
      expect(@essay.upload_flag).to eq new_essay.upload_flag
      expect(@essay.file_name).to eq new_essay.file_name
      expect(@essay.start_pass).to eq new_essay.start_pass
      expect(@essay.start_time).to eq new_essay.start_time
      expect(@essay.end_time).to eq new_essay.end_time
      expect(@essay.pre_grading_enable_flag).to eq new_essay.pre_grading_enable_flag
      expect(@essay.material_memo).to eq new_essay.material_memo
    end
  end

  describe '他テストからの設問コピー' do
    before do
      @essay = create(:essay, course_id: @course.id, file: fixture_file_upload('test.txt', 'text/txt'),
        upload_flag: GenericPage::TYPE_FILEUPLOAD,
        max_count: 2,
        pass_grade: 70,
        assignment_essay_return_method_cd: Settings.GENERICPAGE_RETURN_METHOD_NOT_RETURN,
        start_pass: "pass12345",
        start_time: "2020/03/01",
        end_time: "2020/03/31",
        pre_grading_enable_flag: Settings.GENERICPAGE_PREGRADINGENABLEFLG_ON
      )

      @src_essay = create(:essay, course_id: @course.id, file: fixture_file_upload('test.txt', 'text/txt'),
        upload_flag: GenericPage::TYPE_FILEUPLOAD,
        max_count: 2,
        pass_grade: 70,
        assignment_essay_return_method_cd: Settings.GENERICPAGE_RETURN_METHOD_NOT_RETURN,
        start_pass: "pass12345",
        start_time: "2020/01/01",
        end_time: "2020/01/31",
        pre_grading_enable_flag: Settings.GENERICPAGE_PREGRADINGENABLEFLG_ON
      )
      @src_essay.questions << create_list(:essay_question, 2, generic_page_type_cd: @src_essay.type_cd)
      
    end

    it "成功" do
      expect{
        @essay.copy_questions(@src_essay)
      }.to change(Question, :count).by(2)

      expect(@essay.questions.first.id).to_not eq @src_essay.questions.first.id

      expect(@essay.questions.first.content).to eq @src_essay.questions.first.content
    end
  end
end