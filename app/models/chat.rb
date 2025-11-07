class Chat < ApplicationRecord
  belongs_to :application, counter_cache: :chats_count
  has_many :messages, dependent: :destroy

  validates :application, presence: true
  validates :number, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :number, uniqueness: { scope: :application_id }

  before_validation :assign_number, on: :create

  def as_json(options = {})
    super({
      only: [:number, :title, :messages_count, :created_at]
    })
  end

  private

  # Assign sequential number for the chat within the application.
  # Preferred: Redis-based sequence per application: "application:{application_id}:chats_seq"
  # Fallback: DB transaction that locks the chats table for that application and picks max+1.
  def assign_number
    return if number.present?
    if defined?($redis)
      begin
        key = "application:#{application_id}:chats_seq"
        new_number = $redis.incr(key)
        self.number = new_number
        return
      rescue => e
        Rails.logger.warn("[Chat.assign_number] Redis incr failed: #{e.class} #{e.message}. Falling back to DB.")
      end
    end

    # Fallback: DB-safe approach
    Chat.transaction(requires_new: true) do
      # lock related chats rows with SELECT ... FOR UPDATE (works per DB adapter)
      max_number = Chat.where(application_id: application_id).lock.select('MAX(number) as max_number').first&.max_number
      self.number = (max_number || 0) + 1
    end
  end
end
