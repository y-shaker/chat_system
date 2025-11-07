FactoryBot.define do
  factory :chat do
    association :application
    number { Faker::Number.unique.between(from: 1, to: 10_000) }
    title { Faker::Lorem.words(number: 3).join(' ') }
  end
end
