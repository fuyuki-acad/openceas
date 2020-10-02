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
