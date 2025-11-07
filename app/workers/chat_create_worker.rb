class ChatCreateWorker
  include Sidekiq::Worker

  def perform(application_id, number, title)
    Chat.create!(application_id: application_id, number: number, title: title)
  end
end
