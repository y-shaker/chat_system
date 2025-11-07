require 'rails_helper'

RSpec.describe 'Messages API', type: :request do
  let(:application) { create(:application) }
  let(:chat) { create(:chat, application: application) }

  describe 'GET /messages' do
    before { create_list(:message, 3, chat: chat) }

    it 'retrieves all messages for a chat' do
      get "/applications/#{application.token}/chats/#{chat.number}/messages"

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body).size).to eq(3)
    end
  end

  describe 'GET /messages/:number' do
    let(:message) { create(:message, chat: chat) }

    it 'retrieves a specific message' do
      get "/applications/#{application.token}/chats/#{chat.number}/messages/#{message.number}"

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)['body']).to eq(message.body)
    end
  end
end
