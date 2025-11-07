class MessageCreateWorker
  include Sidekiq::Worker

  def perform(chat_id, number, body)
    # Check if message already exists to handle retries gracefully
    existing_message = Message.find_by(chat_id: chat_id, number: number)
    if existing_message
      Rails.logger.info("[MessageCreateWorker] Message #{number} for chat #{chat_id} already exists, skipping creation")
      message = existing_message
    else
      message = Message.create!(chat_id: chat_id, number: number, body: body)
    end

    # Manually index the message in Elasticsearch since callbacks don't work in background jobs
    # Use a separate transaction to ensure indexing happens after the message is committed
    Message.transaction do
      begin
        message.__elasticsearch__.index_document
        Rails.logger.info("[MessageCreateWorker] Indexed message #{message.id} in Elasticsearch")
      rescue => e
        Rails.logger.error("[MessageCreateWorker] Failed to index message #{message.id}: #{e.message}")
        # Don't raise the error to avoid job retries - the message is already created
      end
    end
  end
end
