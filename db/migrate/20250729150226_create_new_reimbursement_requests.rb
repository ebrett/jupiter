class CreateNewReimbursementRequests < ActiveRecord::Migration[8.0]
  def up
    # First drop any existing reimbursement_requests table and indexes
    execute "DROP TABLE IF EXISTS reimbursement_requests CASCADE"
    execute "DROP INDEX IF EXISTS index_reimbursement_requests_on_user_id"
    execute "DROP INDEX IF EXISTS index_reimbursement_requests_on_status"
    execute "DROP INDEX IF EXISTS index_reimbursement_requests_on_category"
    execute "DROP INDEX IF EXISTS index_reimbursement_requests_on_expense_date"
    execute "DROP INDEX IF EXISTS index_reimbursement_requests_on_request_number"
    execute "DROP INDEX IF EXISTS index_reimbursement_requests_on_submitted_at"
    execute "DROP INDEX IF EXISTS index_reimbursement_requests_on_approved_by_id"

    # Create the new table
    create_table :reimbursement_requests do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }

      # Request details
      t.string :title, null: false
      t.text :description, null: false
      t.integer :amount_cents, null: false
      t.string :currency, null: false, default: 'USD'
      t.date :expense_date, null: false
      t.string :category, null: false

      # Workflow state
      t.string :status, null: false, default: 'draft'

      # Timestamps for state changes
      t.timestamp :submitted_at
      t.timestamp :reviewed_at
      t.timestamp :approved_at
      t.timestamp :rejected_at
      t.timestamp :paid_at

      # Approval details
      t.references :approved_by, foreign_key: { to_table: :users }
      t.integer :approved_amount_cents
      t.text :approval_notes
      t.text :rejection_reason

      # Metadata
      t.string :request_number, null: false
      t.string :priority, default: 'normal'

      t.timestamps
    end

    # Add indexes for performance
    add_index :reimbursement_requests, :status
    add_index :reimbursement_requests, :category
    add_index :reimbursement_requests, :expense_date
    add_index :reimbursement_requests, :request_number, unique: true
    add_index :reimbursement_requests, :submitted_at
  end

  def down
    drop_table :reimbursement_requests
  end
end
