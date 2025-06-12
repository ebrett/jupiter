class AddEmailVerificationToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :email_verified_at, :datetime
    add_column :users, :verification_token, :string
    add_column :users, :verification_sent_at, :datetime

    add_index :users, :verification_token, unique: true
  end
end
