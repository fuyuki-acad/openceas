FactoryBot.define do
  factory :select_quiz do
    sequence(:content) { |n| "select_quiz #{n}" }
    select_correct_flag {"0"}
  end
end