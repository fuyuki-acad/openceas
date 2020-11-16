FactoryBot.define do
  factory :faq_answer do
    sequence(:answer_title) { |n| "answer title #{n}" }
    sequence(:answer) { |n| "answer #{n}" }
  end
end
