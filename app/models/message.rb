class Message < ApplicationRecord
  include Elasticsearch::Model
  include Elasticsearch::Model::Callbacks

  belongs_to :chat, counter_cache: :messages_count

  validates :chat, presence: true
  validates :number, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :number, uniqueness: { scope: :chat_id }
  validates :body, presence: true

  before_validation :assign_number, on: :create

  def as_indexed_json(_options = {})
    {
      body: body,
      chat_id: chat_id
    }
  end

  settings index: {
    number_of_shards: 1,
    analysis: {
      analyzer: {
        ngram_analyzer: {
          tokenizer: 'ngram_tokenizer',
          filter: ['lowercase']
        },
        ngram_search_analyzer: {
          tokenizer: 'standard',
          filter: ['lowercase']
        }
      },
      tokenizer: {
        ngram_tokenizer: {
          type: 'ngram',
          min_gram: 2,
          max_gram: 10,
          token_chars: ['letter', 'digit']
        }
      }
    },
    max_ngram_diff: 8
  } do
    mappings dynamic: false do
      indexes :body, type: :text, analyzer: 'ngram_analyzer', search_analyzer: 'ngram_search_analyzer'
      indexes :chat_id, type: :integer
    end
  end


  
  def as_json(options = {})
    super({
      only: [:number, :body, :created_at, :updated_at]
    })
  end

  private

  # Use Redis first for a chat-local increment: "chat:{chat_id}:messages_seq"
  def assign_number
    return if number.present?
    if defined?($redis)
      begin
        key = "chat:#{chat_id}:messages_seq"
        new_number = $redis.incr(key)
        self.number = new_number
        return
      rescue => e
        Rails.logger.warn("[Message.assign_number] Redis incr failed: #{e.class} #{e.message}. Falling back to DB.")
      end
    end

    # DB fallback
    Message.transaction(requires_new: true) do
      max_number = Message.where(chat_id: chat_id).lock.select('MAX(number) as max_number').first&.max_number
      self.number = (max_number || 0) + 1
    end
  end
end

