FactoryBot.define do
  factory :faq do
    sequence(:faq_title) { |n| "faq title #{n}" }
    sequence(:question) { |n| "question #{n}" }
  end
end
