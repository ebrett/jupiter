class CreateReimbursementRequestEvents < ActiveRecord::Migration[8.0]
  def change
    create_table :reimbursement_request_events do |t|
      t.references :reimbursement_request, null: false, foreign_key: { on_delete: :cascade }
      t.references :user, null: false, foreign_key: true

      t.string :event_type, null: false
      t.string :from_status
      t.string :to_status
      t.text :notes
      t.jsonb :event_data, default: {}

      t.timestamp :created_at, null: false, default: -> { 'CURRENT_TIMESTAMP' }
    end

    add_index :reimbursement_request_events,
              [ :reimbursement_request_id, :created_at ],
              name: 'idx_events_request_time'
    add_index :reimbursement_request_events, :event_type
  end
end
