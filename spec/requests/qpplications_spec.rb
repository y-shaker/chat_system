require 'rails_helper'

RSpec.describe 'Applications API', type: :request do
  let!(:applications) { create_list(:application, 3) }
  let(:application) { applications.first }

  describe 'GET /applications' do
    it 'returns all applications' do
      get '/applications'

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)
      expect(json.size).to eq(3)
      expect(json.first).to have_key('token')
    end
  end

  describe 'GET /applications/:token' do
    it 'returns a specific application' do
      get "/applications/#{application.token}"

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)
      expect(json['name']).to eq(application.name)
      expect(json['token']).to eq(application.token)
    end

    it 'returns 404 if not found' do
      get "/applications/invalidtoken"

      expect(response).to have_http_status(:not_found)
    end
  end
end
