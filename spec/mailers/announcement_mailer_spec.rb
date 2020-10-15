require 'rails_helper'

RSpec.describe AnnouncementMailer, type: :mailer do

  describe '#send_mail' do
    let(:teacher) { create(:teacher_user) }
    let(:student) { create(:student_user) }

    before do
      User.current_user = teacher
      course = create(:course, :year_of_2019)
      @announcement = create(:announcement, course_id: course.id, content: "test send mail content")
    end

    context 'when send_mail' do
      subject(:mail) do
        AnnouncementMailer.new_registration(@announcement, student).deliver_now
        ActionMailer::Base.deliveries.last
      end

      it { expect(mail.from.first).to eq Settings.CUSTOM_MAIL_SENDER }

      it { expect(mail.to.first).to eq student.email }

      it { expect(mail.subject).to eq @announcement.course.course_name + I18n.t("announcement.COMMONANNOUNCEMENT_MAILSUBJECT") }

      it { expect(mail.body).to match(@announcement.content) }
    end
  end
end