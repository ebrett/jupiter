class CreateNationbuilderTokens < ActiveRecord::Migration[8.0]
  def change
    create_table :nationbuilder_tokens do |t|
      t.references :user, null: false, foreign_key: true
      t.string :access_token
      t.string :refresh_token
      t.datetime :expires_at
      t.string :scope
      t.jsonb :raw_response

      t.timestamps
    end
  end
end
