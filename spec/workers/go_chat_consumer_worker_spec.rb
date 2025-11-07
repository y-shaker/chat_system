require 'rails_helper'
require 'redis'
require 'json'

RSpec.describe GoChatConsumerWorker, type: :worker do
  let(:redis) { Redis.new(url: ENV.fetch('REDIS_URL', 'redis://redis:6379/0')) }
  let(:application) { create(:application) }
  let(:chat) { create(:chat, application: application) }

  before do
    redis.del('chats_queue')
    allow(Redis).to receive(:new).and_return(redis)
  end

  describe '#process_chat' do
    it 'creates a new chat and increments chat count' do
      payload = {
        'application_token' => application.token,
        'chat_number' => 1,
        'title' => 'Chat from Go'
      }

      worker = GoChatConsumerWorker.new

      expect {
        worker.send(:process_chat, payload)
      }.to change { application.reload.chats.count }.by(1)
       .and change { application.reload.chats_count }.by(1)

      chat = application.chats.find_by(number: 1)
      expect(chat.title).to eq('Chat from Go')
    end

    it 'does nothing if application is not found' do
      payload = {
        'application_token' => 'nonexistent-token',
        'chat_number' => 999,
        'title' => 'Ghost Chat'
      }

      worker = GoChatConsumerWorker.new

      expect {
        worker.send(:process_chat, payload)
      }.not_to change(Chat, :count)
    end

    it 'does not create duplicate chats if already exists (idempotent)' do
      existing_chat = create(:chat, application: application, number: 7, title: 'Old Chat')
      payload = {
        'application_token' => application.token,
        'chat_number' => 7,
        'title' => 'New Title'
      }

      worker = GoChatConsumerWorker.new

      expect {
        worker.send(:process_chat, payload)
      }.not_to change(Chat, :count)

      expect(existing_chat.reload.title).to eq('Old Chat')
    end
  end
end
