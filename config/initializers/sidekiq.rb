Rails.application.config.after_initialize do
  if defined?(Sidekiq) && !Rails.const_defined?('Server')
    Thread.new do
      begin
        GoMessageConsumerWorker.new.perform
      rescue => e
        Rails.logger.error("[Sidekiq Init] Failed to start GoMessageConsumerWorker: #{e.message}")
      end
    end

    Thread.new do
      begin
        GoChatConsumerWorker.new.perform
      rescue => e
        Rails.logger.error("[Sidekiq Init] Failed to start GoChatConsumerWorker: #{e.message}")
      end
    end
  end
end
