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

class SupportDetailForm < SupportScoreForm
  attr_accessor :start_score, :end_score

  validate :check_score

  def check_score
    validate_numeric(:start_score, I18n.t("support.MESSAGE_ERROR_SCORE")) unless start_score.empty?
    validate_numeric(:end_score, I18n.t("support.MESSAGE_ERROR_SCORE")) unless end_score.empty?
    if !start_score.empty? && !end_score.empty?
      errors.add(:start_score, I18n.t("support.MESSAGE_ERROR_SCORE_RANGE")) if start_score.to_i > end_score.to_i
    end
  end

end
