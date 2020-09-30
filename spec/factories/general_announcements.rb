FactoryBot.define do
  factory :general_announcement do
    sequence(:title) { |n| "announcement title #{n}" }
    sequence(:content) { |n| "content #{n}" }
    type_cd { GeneralAnnouncement::TYPE_SYSTEM }
  end
end
