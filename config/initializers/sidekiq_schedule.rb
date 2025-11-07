if ENV['ENABLE_SIDEKIQ_CRON'] == 'true'
  require 'sidekiq-cron'

  schedule = {
    'count_sync_worker' => {
      'class' => 'CountSyncWorker',
      'cron' => '0 * * * *',
      'queue' => 'default'
    }
  }

  Sidekiq::Cron::Job.load_from_hash(schedule)
  Rails.logger.info("[Sidekiq Schedule] Cron jobs loaded successfully")
end
