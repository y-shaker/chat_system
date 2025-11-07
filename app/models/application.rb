class Application < ApplicationRecord
  has_many :chats, dependent: :destroy

  validates :name, presence: true
  validates :token, presence: true, uniqueness: true

  before_validation :ensure_token, on: :create

  def as_json(options = {})
    super({
      only: [:token, :name, :chats_count, :created_at]
    })
  end

  # generate a secure random token
  def ensure_token
    return if token.present?
    self.token = loop do
      t = SecureRandom.hex(16)
      break t unless Application.exists?(token: t)
    end
  end

  # helper to find by token
  def self.find_by_token!(token)
    find_by!(token: token)
  end
end
