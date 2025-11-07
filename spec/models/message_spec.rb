require 'rails_helper'

RSpec.describe Message, type: :model do
  it 'belongs to a chat' do
    should belong_to(:chat)
  end

  it 'is valid with valid attributes' do
    expect(build(:message)).to be_valid
  end

  it 'requires a body' do
    message = build(:message, body: nil)
    expect(message).not_to be_valid
  end
end
