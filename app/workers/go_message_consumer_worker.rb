require 'json'
require 'redis'

class GoMessageConsumerWorker
  include Sidekiq::Worker

  sidekiq_options queue: :go_consumer, retry: true

  REDIS_QUEUE_KEY = 'messages_queue'

  def perform(limit: nil)
    redis = Redis.new(url: ENV.fetch('REDIS_URL', 'redis://redis:6379/0'))
    Rails.logger.info("[GoMessageConsumerWorker] Listening on #{REDIS_QUEUE_KEY}...")

    loop do
      begin
        _, raw_message = redis.blpop(REDIS_QUEUE_KEY, timeout: 0)
        payload = JSON.parse(raw_message)

        process_message(payload)
      rescue JSON::ParserError => e
        Rails.logger.error("[GoMessageConsumerWorker] Invalid JSON: #{e.message}")
      rescue => e
        Rails.logger.error("[GoMessageConsumerWorker] Error: #{e.class} - #{e.message}")
        sleep 1
      end
    end
  end

  private

  def process_message(payload)
    token        = payload['application_token']
    chat_number  = payload['chat_number']
    message_body = payload['body']
    number       = payload['message_number']

    Rails.logger.info("[GoMessageConsumerWorker] Processing message #{number} for chat #{chat_number}")

    application = Application.find_by(token: token)
    return unless application

    chat = application.chats.find_by(number: chat_number)
    return unless chat

    message = chat.messages.find_or_initialize_by(number: number)
    message.body = message_body
    message.save!
    Rails.cache.delete("chat:#{chat.id}:messages")

    # Index in Elasticsearch
    message.__elasticsearch__.index_document if message.respond_to?(:__elasticsearch__)
  end
end
