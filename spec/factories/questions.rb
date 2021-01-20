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
  factory :parent_question, class: Question do
    sequence(:content) { |n| "parent question #{n}" }
    pattern_cd { Settings.QUESTION_PATTERNCD_PARENTQUESTION }
    shuffle_flag { Settings.QUESTION_SHUFFLEFLG_OFF }
    answer_in_full_cd { Settings.QUESTION_ANSWERINFULLCD_NOTANSWERINFULL }
  end

  factory :question do
    sequence(:content) { |n| "question #{n}" }
    pattern_cd { Settings.QUESTION_PATTERNCD_RADIO }
    score { 1 }
    text_count { Question::DEFAULT_SELECT_COUNT }
    shuffle_flag { Settings.QUESTION_SHUFFLEFLG_OFF }
    answer_in_full_cd { Settings.QUESTION_ANSWERINFULLCD_NOTANSWERINFULL }
    sequence(:answer_memo) { |n| "answer_memo #{n}" }
  end

  factory :essay_question, class: Question do
    sequence(:content) { |n| "essay question #{n}" }
    pattern_cd { Settings.QUESTION_PATTERNCD_ASSIGNMENTESSAY }
    shuffle_flag { Settings.QUESTION_SHUFFLEFLG_OFF }
  end

  factory :questionnaire_question, class: Question do
    sequence(:content) { |n| "questionnaire question #{n}" }
    pattern_cd { Settings.QUESTION_PATTERNCD_RADIO }
    must_flag {"0"}
    text_count { Question::DEFAULT_SELECT_COUNT }
    text_flag {"0"}
    shuffle_flag { Settings.QUESTION_SHUFFLEFLG_OFF }
    answer_in_full_cd { Settings.QUESTION_ANSWERINFULLCD_NOTANSWERINFULL }
    sequence(:answer_memo) { |n| "answer_memo #{n}" }
  end
end
