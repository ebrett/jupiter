class CreateRailsSessionStore < ActiveRecord::Migration[8.0]
  def change
    create_table :rails_sessions do |t|
      t.string :session_id, null: false
      t.text :data
      t.timestamps
    end

    add_index :rails_sessions, :session_id, unique: true
    add_index :rails_sessions, :updated_at
  end
end
