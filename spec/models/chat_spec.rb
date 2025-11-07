require 'rails_helper'

RSpec.describe Chat, type: :model do
  it 'belongs to an application' do
    should belong_to(:application)
  end

  it 'is valid with valid attributes' do
    expect(build(:chat)).to be_valid
  end

  it "assigns a number automatically" do
    chat = build(:chat, number: nil)
    expect(chat).to be_valid
    expect(chat.number).to be_present
  end
end
