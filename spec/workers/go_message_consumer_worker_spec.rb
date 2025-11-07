require 'rails_helper'

RSpec.describe GoMessageConsumerWorker, type: :worker do
  let(:redis) { Redis.new(url: ENV.fetch('REDIS_URL', 'redis://redis:6379/0')) }
  let(:application) { create(:application) }
  let(:chat) { create(:chat, application: application, number: 1) }

  before do
    redis.del('messages_queue') # Clear queue
    allow_any_instance_of(GoMessageConsumerWorker).to receive(:sleep) # don’t actually sleep in specs
  end

  describe '#process_message' do
    it 'creates a message and increments chat count' do
      payload = {
        'application_token' => application.token,
        'chat_number' => chat.number,
        'message_number' => 42,
        'body' => 'Hello from Go!'
      }

      worker = GoMessageConsumerWorker.new
      expect {
        worker.send(:process_message, payload)
      }.to change { chat.reload.messages.count }.by(1)
       .and change { chat.reload.messages_count }.by(1)
    end

    it 'does nothing if the application token is invalid' do
      payload = {
        'application_token' => 'fake',
        'chat_number' => chat.number,
        'message_number' => 99,
        'body' => 'Ghost message'
      }

      worker = GoMessageConsumerWorker.new
      expect {
        worker.send(:process_message, payload)
      }.not_to change(Message, :count)
    end

    it 'does nothing if the chat number does not exist' do
      payload = {
        'application_token' => application.token,
        'chat_number' => 9999,
        'message_number' => 99,
        'body' => 'Orphan message'
      }

      worker = GoMessageConsumerWorker.new
      expect {
        worker.send(:process_message, payload)
      }.not_to change(Message, :count)
    end

    it 'does not create duplicate messages when the same job is processed twice' do
      message = create(:message, chat: chat, number: 5, body: 'Old Body')
      payload = {
        'application_token' => application.token,
        'chat_number' => chat.number,
        'message_number' => 5,
        'body' => 'Updated Body'
      }

      worker = GoMessageConsumerWorker.new

      2.times { worker.send(:process_message, payload) }

      expect(chat.messages.count).to eq(1)
      expect(message.reload.body).to eq('Updated Body')
    end
  end
end
