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