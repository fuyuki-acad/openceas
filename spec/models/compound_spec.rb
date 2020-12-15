require 'rails_helper'

RSpec.describe Compound, type: :model do
  let(:test_file) { Rack::Test::UploadedFile.new(Rails.root.join('spec', 'fixtures', 'files', 'test.txt'), 'text/txt') }

  before do
    User.current_user = create(:teacher_user)
    @course = create(:course, :year_of_2019)
  end

  describe 'バリデーション' do
    before do
      @compound = build(:compound, course_id: @course.id)
    end

    it "正常" do
      @compound.valid?
      expect(@compound.errors.count).to eq 0
      expect(@compound).to be_valid
    end

    it "タイトル" do
      @compound.generic_page_title = nil
      @compound.valid?
      expect(@compound.errors.messages[:base]).to include I18n.t("common.COMMON_SUBJECTCHECK")
    end

    it "ファイル" do
      @compound.file = nil
      @compound.valid?
      expect(@compound.errors.count).to eq 0

      @compound.file = test_file
      @compound.valid?
      expect(@compound.errors.count).to eq 0
    end

    it "開始パスワード" do
      @compound.start_pass = "./123sa"
      @compound.valid?
      expect(@compound.errors.messages[:base]).to include I18n.t("materials_registration.COMMONMATERIALSREGISTRATION_ERRORTYPE3")

      @compound.start_pass = "pass12345"
      @compound.valid?
      expect(@compound.errors.count).to eq 0
    end

    it "採点開始パスワード" do
      @compound.self_pass = "./123sa"
      @compound.valid?
      expect(@compound.errors.messages[:base]).to include I18n.t("materials_registration.COMMONMATERIALSREGISTRATION_ERRORTYPE3")

      @compound.self_type = "2"
      @compound.self_pass = ""
      @compound.valid?
      expect(@compound.errors.messages[:base]).to include I18n.t("materials_registration.MAT_REG_COM_REGISTERCOMPOUND_STARTGRADEPASSWORD_ALERT")

      @compound.self_pass = "pass12345"
      @compound.valid?
      expect(@compound.errors.count).to eq 0
    end

    it "開始終了日時" do
      @compound.start_time = "2020/01/02"
      @compound.end_time = "2020/01/01"
      @compound.valid?
      expect(@compound.errors.messages[:start_time]).to include I18n.t("materials_registration.COMMONMATERIALSREGISTRATION_ERRORTYPE2")

      @compound.start_time = "2020/01/01"
      @compound.end_time = "2020/01/02"
      @compound.valid?
      expect(@compound.errors.count).to eq 0

      @compound.start_time = ""
      @compound.end_time = ""
      @compound.valid?
      expect(@compound.errors.count).to eq 0
    end

    it "公開メモ" do
      @compound.material_memo = "あ" * 4097
      @compound.valid?
      expect(@compound.errors.messages[:base]).to include I18n.t("page_management.MAT_REG_MAT_PAGEMANAGEMENT_COMMENT_TOO_LONG")

      @compound.material_memo = "あ" * 4096
      @compound.valid?
      expect(@compound.errors.count).to eq 0
    end
  end

  describe '登録' do
    it "ファイルアップロード成功" do
      file_name = 'test.txt'
      compound = build(:compound, course_id: @course.id, file: test_file,
        upload_flag: GenericPage::TYPE_FILEUPLOAD)

      expect{
        compound.save
      }.to change(GenericPage, :count).by(1)

      expect(compound.file_name).to eq file_name
    end
  end

  describe '更新' do
    it "ファイルアップロード成功" do
      file_name = 'test_update.txt'
      compound = create(:compound, course_id: @course.id, file: test_file,
        upload_flag: GenericPage::TYPE_FILEUPLOAD)

        compound.file = Rack::Test::UploadedFile.new(Rails.root.join('spec', 'fixtures', 'files', file_name), 'text/txt')
      expect{
        compound.save
      }.to change(GenericPage, :count).by(0)

      expect(compound.file_name).to eq file_name
    end
  end

  describe '他コースへコピー' do
    before do
      @compound = create(:compound, course_id: @course.id, file: test_file,
        upload_flag: GenericPage::TYPE_FILEUPLOAD,
        max_count: 2,
        pass_grade: 70,
        start_pass: "pass12345",
        start_time: "2020/01/01",
        end_time: "2020/01/31",
        self_type: "2",
        self_pass: "pass67890"
      )

      @other_course = create(:course, :year_of_2019)
    end

    it "成功" do
      new_compound = @compound.copy(@other_course)

      expect(@compound.course_id).to_not eq new_compound.course_id
      expect(@compound.get_material_file_path).to_not eq new_compound.get_material_file_path

      expect(@compound.type_cd).to eq new_compound.type_cd
      expect(@compound.generic_page_title).to eq new_compound.generic_page_title
      expect(@compound.max_count).to eq new_compound.max_count
      expect(@compound.pass_grade).to eq new_compound.pass_grade
      expect(@compound.upload_flag).to eq new_compound.upload_flag
      expect(@compound.file_name).to eq new_compound.file_name
      expect(@compound.start_pass).to eq new_compound.start_pass
      expect(@compound.start_time).to eq new_compound.start_time
      expect(@compound.end_time).to eq new_compound.end_time
      expect(@compound.self_type).to eq new_compound.self_type
      expect(@compound.self_pass).to eq new_compound.self_pass
      expect(@compound.material_memo).to eq new_compound.material_memo
      expect(@compound.material_memo_closed).to eq new_compound.material_memo_closed
    end
  end

  describe '他テストからの設問コピー' do
    before do
      @compound = create(:compound, course_id: @course.id, file: test_file,
        upload_flag: GenericPage::TYPE_FILEUPLOAD,
        max_count: 2,
        pass_grade: 70,
        start_pass: "pass12345",
        start_time: "2020/01/01",
        end_time: "2020/01/31",
        self_type: "2",
        self_pass: "pass67890"
      )

      @src_compound = create(:compound, course_id: @course.id, file: test_file,
        upload_flag: GenericPage::TYPE_FILEUPLOAD,
        max_count: 1,
        pass_grade: 65,
        start_pass: "pass12345",
        start_time: "2020/01/01",
        end_time: "2020/01/31",
        self_type: "0",
        self_pass: ""
      )
      parent_question = create(:parent_question)
      @src_compound.questions << parent_question
      create_list(:question, 2, parent_question_id: parent_question.id, generic_page_type_cd: Settings.GENERICPAGE_TYPECD_COMPOUNDCODE,
        pattern_cd: Settings.QUESTION_PATTERNCD_RADIO,
        quizzes_attributes: {
          "1" => { "content" => "選択肢１", 'select_correct_flag' => "0" },
          "2" => { "content" => "選択肢２", 'select_correct_flag' => "0" },
          "3" => { "content" => "選択肢３", 'select_correct_flag' => "0" },
          "4" => { "content" => "選択肢４", 'select_correct_flag' => "1" }
      })
    end

    it "成功" do
      expect{
        @compound.copy_questions(@src_compound)
      }.to change(Question, :count).by(3)

      expect(@compound.parent_questions.count).to eq 1
      expect(@compound.parent_questions.first.questions.count).to eq 2
      expect(@compound.parent_questions.first.questions.first.all_quizzes.count).to eq 4

      expect(@compound.parent_questions.first.id).to_not eq @src_compound.parent_questions.first.id
      expect(@compound.parent_questions.first.questions.first.id).to_not eq @src_compound.parent_questions.first.questions.first.id

      expect(@compound.parent_questions.first.content).to eq @src_compound.parent_questions.first.content
      expect(@compound.parent_questions.first.questions.first.content).to eq @src_compound.parent_questions.first.questions.first.content
    end
  end
end