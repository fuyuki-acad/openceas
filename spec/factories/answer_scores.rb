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
