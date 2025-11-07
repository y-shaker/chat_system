FactoryBot.define do
  factory :message do
    association :chat
    number { Faker::Number.unique.between(from: 1, to: 10_000) }
    body { Faker::Lorem.sentence(word_count: 6) }
  end
end
