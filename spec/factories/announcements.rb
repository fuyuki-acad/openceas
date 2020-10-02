FactoryBot.define do
  factory :announcement do
    sequence(:subject) { |n| "announcement subject #{n}" }
    sequence(:content) { |n| "announcement content #{n}" }
    announcement_state { "1" }
  end
end