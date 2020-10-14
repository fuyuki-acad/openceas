require 'rails_helper'

RSpec.describe GenericPage, type: :model do
  before do
    User.current_user = create(:teacher_user)
    @course = create(:course, :year_of_2019)
  end

  describe 'バリデーション' do
    before do
      @questionnaire = build(:questionnaire, course_id: @course.id,)
    end

    it "正常" do
      @questionnaire.valid?
      expect(@questionnaire.errors.count).to eq 0
      expect(@questionnaire).to be_valid
    end

    it "タイトル" do
      @questionnaire.generic_page_title = nil
      @questionnaire.valid?
      expect(@questionnaire.errors.messages[:base]).to include I18n.t("common.COMMON_SUBJECTCHECK")
    end

    it "ファイル" do
      @questionnaire.upload_flag = GenericPage::TYPE_FILEUPLOAD

      #ファイル未設定
      @questionnaire.file = nil
      @questionnaire.valid?
      expect(@questionnaire.errors.messages[:file]).to include I18n.t("page_management.MAT_REG_MAT_PAGEMANAGEMENT_ERRORTYPE2")

      #ファイル拡張子なし
      @questionnaire.file = fixture_file_upload('test', 'text/txt')
      @questionnaire.valid?
      expect(@questionnaire.errors.messages[:file]).to include I18n.t("materials_registration.MAT_REG_MAT_PAGEMANAGEMENT_ERRORTYPE3")

      #ファイル拡張子（exe）
      @questionnaire.file = fixture_file_upload('test.exe', 'text/txt')
      @questionnaire.valid?
      expect(@questionnaire.errors.messages[:file]).to include I18n.t("materials_registration.MAT_REG_MAT_PAGEMANAGEMENT_ERRORTYPE4")

      @questionnaire.file = fixture_file_upload('test.txt', 'text/txt')
      @questionnaire.valid?
      expect(@questionnaire.errors.count).to eq 0
    end

    it "開始パスワード" do
      @questionnaire.start_pass = "./123sa"
      @questionnaire.valid?
      expect(@questionnaire.errors.messages[:base]).to include I18n.t("materials_registration.COMMONMATERIALSREGISTRATION_ERRORTYPE3")

      @questionnaire.start_pass = "pass12345"
      @questionnaire.valid?
      expect(@questionnaire.errors.count).to eq 0
    end

    it "開始終了日時" do
      @questionnaire.start_time = "2020/01/02"
      @questionnaire.end_time = "2020/01/01"
      @questionnaire.valid?
      expect(@questionnaire.errors.messages[:start_time]).to include I18n.t("materials_registration.COMMONMATERIALSREGISTRATION_ERRORTYPE2")

      @questionnaire.start_time = "2020/01/01"
      @questionnaire.end_time = "2020/01/02"
      @questionnaire.valid?
      expect(@questionnaire.errors.count).to eq 0

      @questionnaire.start_time = ""
      @questionnaire.end_time = ""
      @questionnaire.valid?
      expect(@questionnaire.errors.count).to eq 0
    end

    it "公開メモ" do
      @questionnaire.material_memo = "あ" * 4097
      @questionnaire.valid?
      expect(@questionnaire.errors.messages[:base]).to include I18n.t("page_management.MAT_REG_MAT_PAGEMANAGEMENT_COMMENT_TOO_LONG")

      @questionnaire.material_memo = "あ" * 4096
      @questionnaire.valid?
      expect(@questionnaire.errors.count).to eq 0
    end
  end

  describe '登録' do
    it "ファイルアップロード成功" do
      file_name = 'test.txt'
      questionnaire = build(:questionnaire, course_id: @course.id, file: fixture_file_upload('test.txt', 'text/txt'),
        upload_flag: GenericPage::TYPE_FILEUPLOAD)

      expect{
        questionnaire.save
      }.to change(GenericPage, :count).by(1)

      expect(questionnaire.file_name).to eq file_name
    end
  end

  describe '更新' do
    it "ファイルアップロード成功" do
      file_name = 'test_update.txt'
      questionnaire = create(:questionnaire, course_id: @course.id, file: fixture_file_upload('test.txt', 'text/txt'),
        upload_flag: GenericPage::TYPE_FILEUPLOAD)

      questionnaire.file = fixture_file_upload(file_name, 'text/txt')
      expect{
        questionnaire.save
      }.to change(GenericPage, :count).by(0)

      expect(questionnaire.file_name).to eq file_name
    end
  end

  describe '他コースへコピー' do
    before do
      @questionnaire = create(:questionnaire, course_id: @course.id, file: fixture_file_upload('test.txt', 'text/txt'),
        upload_flag: GenericPage::TYPE_FILEUPLOAD,
        start_pass: "pass12345",
        start_time: "2020/01/01",
        end_time: "2020/01/31",
        edit_flag: "0",
        anonymous_flag: "1"
      )

      @other_course = create(:course, :year_of_2019)
    end

    it "成功" do
      new_questionnaire = @questionnaire.copy(@other_course)

      expect(@questionnaire.course_id).to_not eq new_questionnaire.course_id
      expect(@questionnaire.get_material_file_path).to_not eq new_questionnaire.get_material_file_path

      expect(@questionnaire.type_cd).to eq new_questionnaire.type_cd
      expect(@questionnaire.generic_page_title).to eq new_questionnaire.generic_page_title
      expect(@questionnaire.upload_flag).to eq new_questionnaire.upload_flag
      expect(@questionnaire.file_name).to eq new_questionnaire.file_name
      expect(@questionnaire.start_pass).to eq new_questionnaire.start_pass
      expect(@questionnaire.start_time).to eq new_questionnaire.start_time
      expect(@questionnaire.end_time).to eq new_questionnaire.end_time
      expect(@questionnaire.edit_flag).to eq new_questionnaire.edit_flag
      expect(@questionnaire.anonymous_flag).to eq new_questionnaire.anonymous_flag
      expect(@questionnaire.material_memo).to eq new_questionnaire.material_memo
    end
  end

  describe '他テストからの設問コピー' do
    before do
      @questionnaire = create(:questionnaire, course_id: @course.id, file: fixture_file_upload('test.txt', 'text/txt'),
        upload_flag: GenericPage::TYPE_FILEUPLOAD,
        start_pass: "pass12345",
        start_time: "2020/03/01",
        end_time: "2020/03/31",
        edit_flag: "0",
        anonymous_flag: "1"
      )

      @src_questionnaire = create(:questionnaire, course_id: @course.id, file: fixture_file_upload('test.txt', 'text/txt'),
        upload_flag: GenericPage::TYPE_FILEUPLOAD,
        start_pass: "pass12345",
        start_time: "2020/01/01",
        end_time: "2020/01/31",
        edit_flag: "0",
        anonymous_flag: "1"
      )
      parent_question = create(:parent_question)
      @src_questionnaire.questions << parent_question
      create_list(:question, 2, parent_question_id: parent_question.id, generic_page_type_cd: Settings.GENERICPAGE_TYPECD_COMPOUNDCODE,
        pattern_cd: Settings.QUESTION_PATTERNCD_RADIO,
        quizzes_attributes: {
          "1" => { "content" => "選択肢１", 'select_mark_flag' => "0" },
          "2" => { "content" => "選択肢２", 'select_mark_flag' => "0" },
          "3" => { "content" => "選択肢３", 'select_mark_flag' => "0" },
          "4" => { "content" => "選択肢４", 'select_mark_flag' => "1" }
      })
    end

    it "成功" do
      expect{
        @questionnaire.copy_questions(@src_questionnaire)
      }.to change(Question, :count).by(3)

      expect(@questionnaire.parent_questions.count).to eq 1
      expect(@questionnaire.parent_questions.first.questions.count).to eq 2
      expect(@questionnaire.parent_questions.first.questions.first.all_quizzes.count).to eq 4

      expect(@questionnaire.parent_questions.first.id).to_not eq @src_questionnaire.parent_questions.first.id
      expect(@questionnaire.parent_questions.first.questions.first.id).to_not eq @src_questionnaire.parent_questions.first.questions.first.id

      expect(@questionnaire.parent_questions.first.content).to eq @src_questionnaire.parent_questions.first.content
      expect(@questionnaire.parent_questions.first.questions.first.content).to eq @src_questionnaire.parent_questions.first.questions.first.content
    end
  end
end