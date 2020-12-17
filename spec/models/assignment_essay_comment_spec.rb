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