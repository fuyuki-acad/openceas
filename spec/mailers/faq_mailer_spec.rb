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

RSpec.describe FaqMailer, type: :mailer do

  describe '#send_mail' do
    let(:teacher) { create(:teacher_user) }
    let(:student) { create(:student_user) }

    before do
      User.current_user = teacher
      course = create(:course, :year_of_2019)
      create(:course_assigned_user, course_id: course.id, user_id: teacher.id)
      @faq = create(:faq, course_id: course.id, user_id: student.id, open_flag: true, response_flag: true,
        question: "faq test question")
      @faq_answer = create(:faq_answer, faq_id: @faq.id, answer: "faq test answer")
      end

    context 'faq question' do
      subject(:mail) do
        FaqMailer.question(@faq, student).deliver_now
        ActionMailer::Base.deliveries.last
      end

      it { expect(mail.from.first).to eq Settings.CUSTOM_MAIL_SENDER }

      it { expect(mail.to.first).to eq student.email }

      it { expect(mail.subject).to eq @faq.user.user_name + I18n.t("faq.PRE_BEA_CONFIRMFAQQUESTIONBEAN_MAILSUBJECT") }

      it { expect(mail.body).to match(@faq.question) }
    end

    context 'faq answer' do
      subject(:mail) do
        FaqMailer.answer(@faq_answer, student).deliver_now
        ActionMailer::Base.deliveries.last
      end

      it { expect(mail.from.first).to eq Settings.CUSTOM_MAIL_SENDER }

      it { expect(mail.to.first).to eq student.email }

      it { expect(mail.subject).to eq I18n.t("faq.PRE_BEA_CONFIRMFAQBEAN_MAILSUBJECT") }

      it { expect(mail.body).to match(@faq_answer.faq.question) }

      it { expect(mail.body).to match(@faq_answer.answer) }
    end
  end
end