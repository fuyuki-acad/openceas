require 'rails_helper'

RSpec.describe Question, type: :model do
  before do
    User.current_user = create(:teacher_user)
    @course = create(:course, :year_of_2019)
  end

  describe '大問' do
    context 'バリデーション' do
      before do
        @question = build(:essay_question)
      end

      it "正常" do
        @question.valid?
        expect(@question.errors.count).to eq 0
        expect(@question).to be_valid
      end

      it "記述部" do
        @question.content = nil
        @question.valid?
        expect(@question.errors.messages[:base]).to include I18n.t("common.COMMON_CONTENTCHECK")
      end
    end
  end
end