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

class SupportScoreForm
  include ActiveModel::Model, CustomValidationModule, ErrorMessageModule

  attr_accessor :start_date, :end_date

  validate :check_data

  def check_data
    validate_presence(:start_date, I18n.t("support.MESSAGE_UNFITTED_DATE_FORMAT"))
    validate_date(:start_date, I18n.t("support.MESSAGE_UNFITTED_DATE_FORMAT"))
    validate_presence(:end_date, I18n.t("support.MESSAGE_UNFITTED_DATE_FORMAT"))
    validate_date(:end_date, I18n.t("support.MESSAGE_UNFITTED_DATE_FORMAT"))
    if errors.count == 0
      errors.add(:start_date, I18n.t("support.MESSAGE_ERROR_DATE_RANGE")) if start_date.to_date > end_date.to_date
    end
  end

end
