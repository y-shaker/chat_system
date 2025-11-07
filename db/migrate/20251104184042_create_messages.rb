class CreateMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :messages do |t|
      t.references :chat, null: false, foreign_key: true, index: true
      t.integer :number, null: false
      t.text :body, null: false

      t.timestamps
    end

    # enforce uniqueness: each chat has messages numbered starting at 1
    add_index :messages, [:chat_id, :number], unique: true

    # index body for faster scanning (note: actual search will be via ElasticSearch)
    add_index :messages, :body, type: :fulltext if connection.adapter_name.downcase.include?('mysql')
  end
end
