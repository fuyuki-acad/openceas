require 'rails_helper'

RSpec.describe AssignmentEssayComment, type: :model do
  let(:student) { create(:student_user) }
  let(:test_file) { Rack::Test::UploadedFile.new(Rails.root.join('spec', 'fixtures', 'files', 'test.txt'), 'text/txt') }

  before do
    User.current_user = student
    course = create(:course, :year_of_2019)
    essay = create(:essay, course_id: course.id, upload_flag: GenericPage::TYPE_NOFILEUPLOAD)
    @answer_score = create(:answer_score, page_id: essay.id, user_id: student.id, file: test_file)
end

  context '保存' do
    it '新規登録' do
      @comment = build(:assignment_essay_comment, answer_score_id: @answer_score.id, memo: "test memo")

      expect{
        @comment.save
      }.to change(AssignmentEssayComment, :count).by(1)

      histories = AssignmentEssayCommentHistory.where(answer_score_history_id: @comment.answer_score_history.id).order('id DESC')

      expect(histories.count).to eq 1

      expect(histories[0].memo).to eq "test memo"
    end

    it '更新' do
      @comment = create(:assignment_essay_comment, answer_score_id: @answer_score.id, memo: "test memo")

      expect{
        @comment.update(memo: "test update memo")
      }.to change(Answer, :count).by(0)

      histories = AssignmentEssayCommentHistory.where(answer_score_history_id: @comment.answer_score_history.id).order('id DESC')

      expect(histories.count).to eq 2

      expect(histories[0].memo).to eq "test update memo"
      expect(@comment.answer_score_history.latest_comment.memo).to eq @answer_score.latest_comment.memo
    end
  end

end