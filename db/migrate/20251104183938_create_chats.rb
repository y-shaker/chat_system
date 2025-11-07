class CreateChats < ActiveRecord::Migration[8.1]
  def change
    create_table :chats do |t|
      t.references :application, null: false, foreign_key: true, index: true
      t.integer :number, null: false
      t.integer :messages_count, null: false, default: 0
      t.string :title # optional, remove if not needed

      t.timestamps
    end

    # enforce uniqueness: each application has chats numbered starting at 1
    add_index :chats, [:application_id, :number], unique: true
  end
end
