class CreateChats < ActiveRecord::Migration[8.1]
  def change
    create_table :chats do |t|
      t.references :application, null: false, foreign_key: true, index: true
      t.integer :number, null: false
      t.integer :messages_count, null: false, default: 0
      t.string :title

      t.timestamps
    end

    add_index :chats, [:application_id, :number], unique: true
  end
end
