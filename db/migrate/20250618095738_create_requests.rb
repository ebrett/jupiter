class CreateRequests < ActiveRecord::Migration[8.0]
  def change
    create_table :requests do |t|
      t.string :request_type, null: false
      t.string :request_number, null: false
      t.integer :status, default: 0
      t.decimal :amount_requested, precision: 10, scale: 2
      t.string :currency_code, default: 'USD'
      t.decimal :amount_usd, precision: 10, scale: 2
      t.decimal :exchange_rate, precision: 10, scale: 6, default: 1.0
      t.jsonb :form_data, null: false
      t.jsonb :metadata

      t.timestamps
    end
    add_index :requests, :request_number, unique: true
    add_index :requests, :request_type
  end
end
