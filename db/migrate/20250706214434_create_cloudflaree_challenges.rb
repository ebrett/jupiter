class CreateCloudflareeChallenges < ActiveRecord::Migration[8.0]
  def change
    create_table :cloudflare_challenges do |t|
      t.string :challenge_id, null: false
      t.string :challenge_type, null: false
      t.json :challenge_data
      t.string :oauth_state, null: false
      t.json :original_params
      t.string :session_id, null: false
      t.references :user, null: true, foreign_key: true
      t.datetime :expires_at, null: false

      t.timestamps
    end
    add_index :cloudflare_challenges, :challenge_id, unique: true
    add_index :cloudflare_challenges, :session_id
    add_index :cloudflare_challenges, :expires_at
  end
end
