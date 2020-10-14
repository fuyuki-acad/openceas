require 'rails_helper'

RSpec.describe Question, type: :model do
  before do
    User.current_user = create(:teacher_user)
    @course = create(:course, :year_of_2019)
    @multiplefib = build(:multiplefib, course_id: @course.id)
  end

  describe '大問' do
    context 'バリデーション' do
      before do
        @parent_question = build(:parent_question)
      end

      it "正常" do
        @parent_question.valid?
        expect(@parent_question.errors.count).to eq 0
        expect(@parent_question).to be_valid
      end

      it "記述部" do
        @parent_question.content = nil
        @parent_question.valid?
        expect(@parent_question.errors.messages[:base]).to include I18n.t("materials_registration.MAT_REG_REGISTERPARENTQUESTION_ERROR1")
      end
    end
  end
end