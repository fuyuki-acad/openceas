require 'rails_helper'

RSpec.describe GenericPage, type: :model do
  before do
    @course = create(:course, :year_of_2019)
  end

  describe 'バリデーション' do
    before do
      @evaluation = build(:evaluation, course_id: @course.id,)
    end

    it "正常" do
      @evaluation.valid?
      expect(@evaluation.errors.count).to eq 0
      expect(@evaluation).to be_valid
    end

    it "タイトル" do
      @evaluation.generic_page_title = nil
      @evaluation.valid?
      expect(@evaluation.errors.messages[:base]).to include I18n.t("materials_registration.MAT_REG_EVA_EVALUATIONLIST_ERROR_NOTITLE")
    end

    it "公開メモ" do
      @evaluation.material_memo = "あ" * 4097
      @evaluation.valid?
      expect(@evaluation.errors.messages[:base]).to include I18n.t("page_management.MAT_REG_MAT_PAGEMANAGEMENT_COMMENT_TOO_LONG")

      @evaluation.material_memo = "あ" * 4096
      @evaluation.valid?
      expect(@evaluation.errors.count).to eq 0
    end
  end

  describe '登録' do
    it "成功" do
      evaluation = build(:evaluation, course_id: @course.id,)

      expect{
        evaluation.save
      }.to change(GenericPage, :count).by(1)
    end
  end

  describe '更新' do
    it "成功" do
      evaluation = create(:evaluation, course_id: @course.id)

      evaluation.generic_page_title = "update title"

      expect{
        evaluation.save
      }.to change(GenericPage, :count).by(0)

      expect(evaluation.generic_page_title).to eq "update title"
    end
  end

  describe 'コピー' do
    before do
      @evaluation = create(:evaluation, course_id: @course.id)

      @other_course = create(:course, :year_of_2019)
    end

    it "成功" do
      new_evaluation = @evaluation.copy(@other_course)

      expect(@evaluation.course_id).to_not eq new_evaluation.course_id

      expect(@evaluation.type_cd).to eq new_evaluation.type_cd
      expect(@evaluation.generic_page_title).to eq new_evaluation.generic_page_title
      expect(@evaluation.material_memo).to eq new_evaluation.material_memo
    end
  end
end