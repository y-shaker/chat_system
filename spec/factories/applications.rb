FactoryBot.define do
  factory :application do
    name { Faker::App.name }
    token { SecureRandom.hex(16) }
  end
end
