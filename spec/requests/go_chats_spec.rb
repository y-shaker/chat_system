require 'rails_helper'
require 'net/http'

RSpec.describe 'Go Gateway Chats API', type: :request do
  let(:application) { create(:application) }
  let(:go_gateway_url) { "http://go_gateway:8081" }

  describe 'POST /applications/:token/chats' do
    it 'creates a new chat and queues it in Redis' do
      uri = URI("#{go_gateway_url}/applications/#{application.token}/chats?title=TestChat")
      response = Net::HTTP.post(uri, '', { 'Content-Type' => 'application/json' })

      expect(response.code.to_i).to eq(202)

      parsed = JSON.parse(response.body)
      expect(parsed['number']).to be_present
      expect(parsed['number']).to be_a(Integer)
    end
  end

  describe 'POST /applications/:token/chats with default title' do
    it 'creates chat with default title when none given' do
      uri = URI("#{go_gateway_url}/applications/#{application.token}/chats")
      response = Net::HTTP.post(uri, '', { 'Content-Type' => 'application/json' })

      expect(response.code.to_i).to eq(202)

      parsed = JSON.parse(response.body)
      expect(parsed['number']).to be_present
    end
  end
end
