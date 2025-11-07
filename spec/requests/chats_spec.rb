require 'rails_helper'

RSpec.describe 'Chats API', type: :request do
  let(:application) { create(:application) }
  let!(:chats) { create_list(:chat, 3, application: application) }
  let(:chat) { chats.first }

  describe 'GET /applications/:token/chats' do
    it 'lists all chats for the application' do
      get "/applications/#{application.token}/chats"

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)
      expect(json.size).to eq(3)
      expect(json.first).to have_key('number')
      expect(json.first).to have_key('title')
    end
  end

  describe 'GET /applications/:token/chats/:number' do
    it 'returns a single chat' do
      get "/applications/#{application.token}/chats/#{chat.number}"

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)
      expect(json['number']).to eq(chat.number)
      expect(json['title']).to eq(chat.title)
    end

    it 'returns 404 for an invalid chat number' do
      get "/applications/#{application.token}/chats/9999"

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'GET /applications/:token/chats/:number' do
    it 'returns 404 if application not found' do
      get '/applications/invalid_token/chats/1'
      expect(response).to have_http_status(:not_found)
    end

    it 'returns 404 if chat not found' do
      app = create(:application)
      get "/applications/#{app.token}/chats/999"
      expect(response).to have_http_status(:not_found)
    end
  end

end
