FactoryBot.define do
  factory :answer_score_history do
    total_score {100}
    total_raw_score {100}
    answer_count {1}
    pass_cd {Settings.ANSWERSCORE_PASSCD_SUBMITTED}
  end
end