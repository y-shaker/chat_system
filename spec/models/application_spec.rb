require 'rails_helper'

RSpec.describe Application, type: :model do
  it 'is valid with valid attributes' do
    expect(build(:application)).to be_valid
  end

  it 'generates a token before creation' do
    app = create(:application)
    expect(app.token).to be_present
  end
end
