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

RSpec.describe EssayMailer, type: :mailer do

  describe '#send_mail' do
    let(:teacher) { create(:teacher_user) }
    let(:student) { create(:student_user) }
    let(:test_file) { Rack::Test::UploadedFile.new(Rails.root.join('spec', 'fixtures', 'files', 'test.txt'), 'text/txt') }

    before do
      User.current_user = teacher
      course = create(:course, :year_of_2019)
      @essay = create(:essay, course_id: course.id, upload_flag: GenericPage::TYPE_NOFILEUPLOAD)
      answer_score = create(:answer_score, page_id: @essay.id, user_id: student.id, file: test_file)
      @comment = create(:assignment_essay_comment, answer_score_id: answer_score.id, memo: "test send mail memo")
    end

    context 'when send_mail' do
      subject(:mail) do
        EssayMailer.send_mail(@essay, @comment, student).deliver_now
        ActionMailer::Base.deliveries.last
      end

      it { expect(mail.from.first).to eq Settings.CUSTOM_MAIL_SENDER }

      it { expect(mail.to.first).to eq student.email }

      it 'subject' do
        subject = @essay.course.course_name +
          I18n.t("materials_administration.PRE_BEA_MAT_ADM_ASS_ASSIGNMENTESSAYTOTALRESULTBEAN_MAIL1") +
          @essay.generic_page_title +
          I18n.t("materials_administration.PRE_BEA_MAT_ADM_ASS_ASSIGNMENTESSAYTOTALRESULTBEAN_MAIL2")

        expect(mail.subject).to eq subject
      end

      it { expect(mail.body).to match(@comment.memo) }
    end
  end
end