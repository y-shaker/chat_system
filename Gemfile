source "https://rubygems.org"

ruby "~> 3.3"

gem "rails", "~> 8.1.1"
gem "puma", ">= 5.0"
gem "mysql2", "~> 0.5.7"

gem "redis", "~> 5.2"
gem "sidekiq"
gem "sidekiq-cron", "~> 2.3"

gem "elasticsearch", "~> 8.0"
gem "elasticsearch-model", "~> 8.0"
gem "elasticsearch-rails", "~> 8.0"

gem "bootsnap", require: false

gem "kamal", require: false
gem 'sprockets-rails'


gem "tzinfo-data", platforms: %i[ windows jruby ]

group :development, :test do
  gem "rspec-rails", "~> 8.0"
  gem "factory_bot_rails"
  gem "faker"
  gem "database_cleaner-active_record"
  gem "shoulda-matchers", "~> 6.0"

  gem "debug", platforms: %i[mri windows], require: "debug/prelude"
  gem "brakeman", require: false
  gem "bundler-audit", require: false
  gem "rubocop-rails-omakase", require: false
end

group :development do
  gem "web-console"
end
