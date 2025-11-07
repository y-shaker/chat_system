require 'rails_helper'
require 'net/http'
require 'json'

RSpec.describe "Go Gateway - Messages API", type: :request do
  let!(:application) { create(:application, token: "testtoken") }
  let!(:chat) { create(:chat, application: application, number: 1) }
  let(:go_gateway_url) { "http://go_gateway:8081" }

  describe "POST /applications/:token/chats/:number/messages" do
    it "queues a message creation and returns message number" do
      uri = URI("#{go_gateway_url}/applications/#{application.token}/chats/#{chat.number}/messages")
      res = Net::HTTP.post(uri, { body: "Hello from Go Gateway" }.to_json, "Content-Type" => "application/json")

      expect(res.code.to_i).to eq(202)

      body = JSON.parse(res.body)
      expect(body).to have_key("number")
      expect(body["number"]).to be_a(Integer)
    end

    it "returns 400 if body is missing" do
      uri = URI("#{go_gateway_url}/applications/#{application.token}/chats/#{chat.number}/messages")
      res = Net::HTTP.post(uri, {}.to_json, "Content-Type" => "application/json")

      expect(res.code.to_i).to eq(400)
    end
  end
end
