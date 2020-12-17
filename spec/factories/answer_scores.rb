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

FactoryBot.define do
  factory :answer_score do
    total_score {100}
    total_raw_score {100}
    answer_count {1}
    pass_cd {Settings.ANSWERSCORE_PASSCD_SUBMITTED}
  end

  factory :passed_answer_score, class: AnswerScore do
    total_score {100}
    total_raw_score {100}
    answer_count {1}
    pass_cd {Settings.ANSWERSCORE_PASSCD_SUBMITTED}
  end

  factory :failed_answer_score, class: AnswerScore do
    total_score {30}
    total_raw_score {30}
    answer_count {1}
    pass_cd {Settings.ANSWERSCORE_PASSCD_UNSUBMITTING}
  end
end
