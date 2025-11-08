require 'json'
require 'redis'

class GoChatConsumerWorker
  include Sidekiq::Worker

  sidekiq_options queue: :go_chat_consumer, retry: true

  REDIS_QUEUE_KEY = 'chats_queue'

  def perform
    redis = Redis.new(url: ENV.fetch('REDIS_URL', 'redis://redis:6379/0'))
    Rails.logger.info("[GoChatConsumerWorker] Listening on #{REDIS_QUEUE_KEY}...")

    loop do
      begin
        _, raw_chat = redis.blpop(REDIS_QUEUE_KEY, timeout: 0)
        payload = JSON.parse(raw_chat)
        process_chat(payload)
      rescue JSON::ParserError => e
        Rails.logger.error("[GoChatConsumerWorker] Invalid JSON: #{e.message}")
      rescue => e
        Rails.logger.error("[GoChatConsumerWorker] Error: #{e.class} - #{e.message}")
        sleep 1
      end
    end
  end

  private

  def process_chat(payload)
    token   = payload['application_token']
    title   = payload['title']
    number  = payload['chat_number']

    Rails.logger.info("[GoChatConsumerWorker] Creating chat #{number} for app #{token}")

    app = Application.find_by(token: token)
    return unless app

    chat = app.chats.find_or_initialize_by(number: number)
    chat.title ||= title
    chat.save!

  end
end
