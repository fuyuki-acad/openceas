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

class EvaluationMailer < ApplicationMailer
  def send_mail(generic_page, comment, user)
    @generic_page = generic_page
    subject = @generic_page.course.course_name +
              I18n.t("materials_administration.PRE_BEA_MAT_ADM_ASS_ASSIGNMENTESSAYTOTALRESULTBEAN_MAIL1") +
              @generic_page.generic_page_title +
              I18n.t("materials_administration.PRE_BEA_MAT_ADM_ASS_ASSIGNMENTESSAYTOTALRESULTBEAN_MAIL2")

    user_email = user.email
    user_email += ", " + user.email_mobile unless user.email_mobile.blank?
    mail reply_to: User.current_user.email, to: user_email, subject: subject
  end
end
