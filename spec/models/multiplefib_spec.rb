require 'rails_helper'

RSpec.describe Multiplefib, type: :model do
  let(:test_file) { Rack::Test::UploadedFile.new(Rails.root.join('spec', 'fixtures', 'files', 'test.txt'), 'text/txt') }
  let(:test_update_file) { Rack::Test::UploadedFile.new(Rails.root.join('spec', 'fixtures', 'files', 'test_update.txt'), 'text/txt') }

  before do
    User.current_user = create(:teacher_user)
    @course = create(:course, :year_of_2019)
  end

  describe 'バリデーション' do
    before do
      @multiplefib = build(:multiplefib, course_id: @course.id,
        file: test_file,
        explanation_file: test_file)
    end

    it "正常" do
      @multiplefib.valid?
      expect(@multiplefib.errors.count).to eq 0
      expect(@multiplefib).to be_valid
    end

    it "タイトル" do
      @multiplefib.generic_page_title = nil
      @multiplefib.valid?
      expect(@multiplefib.errors.messages[:base]).to include I18n.t("common.COMMON_SUBJECTCHECK")
    end

    it "ファイル" do
      @multiplefib.file = nil
      @multiplefib.valid?
      expect(@multiplefib.errors.messages[:file]).to include I18n.t("materials_registration.COMMONMATERIALSREGISTRATION_ERRORTYPE6")

      @multiplefib.file = test_file
      @multiplefib.valid?
      expect(@multiplefib.errors.count).to eq 0
    end

    it "開始パスワード" do
      @multiplefib.start_pass = "./123sa"
      @multiplefib.valid?
      expect(@multiplefib.errors.messages[:base]).to include I18n.t("materials_registration.COMMONMATERIALSREGISTRATION_ERRORTYPE3")

      @multiplefib.start_pass = "pass12345"
      @multiplefib.valid?
      expect(@multiplefib.errors.count).to eq 0
    end

    it "開始終了日時" do
      @multiplefib.start_time = "2020/01/02"
      @multiplefib.end_time = "2020/01/01"
      @multiplefib.valid?
      expect(@multiplefib.errors.messages[:start_time]).to include I18n.t("materials_registration.COMMONMATERIALSREGISTRATION_ERRORTYPE2")

      @multiplefib.start_time = "2020/01/01"
      @multiplefib.end_time = "2020/01/02"
      @multiplefib.valid?
      expect(@multiplefib.errors.count).to eq 0

      @multiplefib.start_time = ""
      @multiplefib.end_time = ""
      @multiplefib.valid?
      expect(@multiplefib.errors.count).to eq 0
    end

    it "公開メモ" do
      @multiplefib.material_memo = "あ" * 4097
      @multiplefib.valid?
      expect(@multiplefib.errors.messages[:base]).to include I18n.t("page_management.MAT_REG_MAT_PAGEMANAGEMENT_COMMENT_TOO_LONG")

      @multiplefib.material_memo = "あ" * 4096
      @multiplefib.valid?
      expect(@multiplefib.errors.count).to eq 0
    end
  end

  describe '登録' do
    it "ファイルアップロード成功" do
      file_name = 'test.txt'
      multiplefib = build(:multiplefib, course_id: @course.id, file: test_file,
        explanation_file: test_file)

      expect{
        multiplefib.save
      }.to change(GenericPage, :count).by(1)

      expect(multiplefib.file_name).to eq file_name
    end
  end

  describe '更新' do
    it "ファイルアップロード成功" do
      file_name = 'test_update.txt'
      multiplefib = create(:multiplefib, course_id: @course.id, file: test_file,
        explanation_file: test_file)

      multiplefib.file = Rack::Test::UploadedFile.new(Rails.root.join('spec', 'fixtures', 'files', file_name), 'text/txt')
      expect{
        multiplefib.save
      }.to change(GenericPage, :count).by(0)

      expect(multiplefib.file_name).to eq file_name
    end
  end

  describe '他コースへコピー' do
    before do
      @fine_name = 'test.txt'
      @explanation_file_name = 'test_update.txt'
      @multiplefib = create(:multiplefib, course_id: @course.id, file: test_file,
        explanation_file: test_update_file,
        upload_flag: GenericPage::TYPE_FILEUPLOAD,
        max_count: 2,
        pass_grade: 70,
        start_pass: "pass12345",
        start_time: "2020/01/01",
        end_time: "2020/01/31",
      )

      @other_course = create(:course, :year_of_2019)
    end

    it "成功" do
      new_multiplefib = @multiplefib.copy(@other_course)

      expect(@multiplefib.file_name).to eq @fine_name
      expect(@multiplefib.explanation_file_name).to eq @explanation_file_name

      expect(@multiplefib.course_id).to_not eq new_multiplefib.course_id
      expect(@multiplefib.get_material_file_path).to_not eq new_multiplefib.get_material_file_path
      expect(@multiplefib.explanation_link_name).to_not eq new_multiplefib.explanation_link_name

      expect(@multiplefib.type_cd).to eq new_multiplefib.type_cd
      expect(@multiplefib.generic_page_title).to eq new_multiplefib.generic_page_title
      expect(@multiplefib.max_count).to eq new_multiplefib.max_count
      expect(@multiplefib.pass_grade).to eq new_multiplefib.pass_grade
      expect(@multiplefib.upload_flag).to eq new_multiplefib.upload_flag
      expect(@multiplefib.file_name).to eq new_multiplefib.file_name
      expect(@multiplefib.explanation_file_name).to eq new_multiplefib.explanation_file_name
      expect(@multiplefib.start_pass).to eq new_multiplefib.start_pass
      expect(@multiplefib.start_time).to eq new_multiplefib.start_time
      expect(@multiplefib.end_time).to eq new_multiplefib.end_time
    end
  end

  describe '他テストからの設問コピー' do
    before do
      @multiplefib = create(:multiplefib, course_id: @course.id, file: test_file,
        upload_flag: GenericPage::TYPE_FILEUPLOAD,
        max_count: 2,
        pass_grade: 70,
        start_pass: "",
        start_time: "2020/03/01",
        end_time: "2020/03/31",
      )

      @src_multiplefib = create(:multiplefib, course_id: @course.id, file: test_file,
        upload_flag: GenericPage::TYPE_FILEUPLOAD,
        max_count: 1,
        pass_grade: 65,
        start_pass: "pass12345",
        start_time: "2020/01/01",
        end_time: "2020/01/31",
      )
      parent_question = create(:parent_question)
      @src_multiplefib.questions << parent_question
      create_list(:question, 2, parent_question_id: parent_question.id, generic_page_type_cd: @multiplefib.type_cd)
    end

    it "成功" do
      expect{
        @multiplefib.copy_questions(@src_multiplefib)
      }.to change(Question, :count).by(3)

      expect(@multiplefib.parent_questions.count).to eq 1
      expect(@multiplefib.parent_questions.first.questions.count).to eq 2

      expect(@multiplefib.parent_questions.first.id).to_not eq @src_multiplefib.parent_questions.first.id
      expect(@multiplefib.parent_questions.first.questions.first.id).to_not eq @src_multiplefib.parent_questions.first.questions.first.id

      expect(@multiplefib.parent_questions.first.content).to eq @src_multiplefib.parent_questions.first.content
      expect(@multiplefib.parent_questions.first.questions.first.content).to eq @src_multiplefib.parent_questions.first.questions.first.content
    end
  end
end