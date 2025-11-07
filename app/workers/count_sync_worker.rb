class CountSyncWorker
  include Sidekiq::Worker

  def perform
    Rails.logger.info("[CountSyncWorker] Starting periodic count sync...")

    Application.find_each do |app|
      chats_count = app.chats.count
      app.update_column(:chats_count, chats_count)
      Rails.logger.info("[CountSyncWorker] Updated chats_count=#{chats_count} for app #{app.id}")
    end

    Chat.find_each do |chat|
      messages_count = chat.messages.count
      chat.update_column(:messages_count, messages_count)
      Rails.logger.info("[CountSyncWorker] Updated messages_count=#{messages_count} for chat #{chat.id}")
    end

    Rails.logger.info("[CountSyncWorker] Count sync completed successfully.")
  end
end
