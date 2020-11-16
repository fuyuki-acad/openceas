require 'rails_helper'

RSpec.describe EvaluationMailer, type: :mailer do

  describe '#send_mail' do
    let(:teacher) { create(:teacher_user) }
    let(:student) { create(:student_user) }

    before do
      User.current_user = teacher
      course = create(:course, :year_of_2019)
      @generic_page = create(:compound, course_id: course.id, upload_flag: GenericPage::TYPE_NOFILEUPLOAD, content: "test send mail content")
    end

    context 'when send_mail' do
      subject(:mail) do
        EvaluationMailer.send_mail(@generic_page, @comment, student).deliver_now
        ActionMailer::Base.deliveries.last
      end

      it { expect(mail.from.first).to eq Settings.CUSTOM_MAIL_SENDER }

      it { expect(mail.to.first).to eq student.email }

      it 'subject' do
        subject = @generic_page.course.course_name +
          I18n.t("materials_administration.PRE_BEA_MAT_ADM_ASS_ASSIGNMENTESSAYTOTALRESULTBEAN_MAIL1") +
          @generic_page.generic_page_title +
          I18n.t("materials_administration.PRE_BEA_MAT_ADM_ASS_ASSIGNMENTESSAYTOTALRESULTBEAN_MAIL2")

        expect(mail.subject).to eq subject
      end

      it { expect(mail.body).to match(@generic_page.content) }
    end
  end
end