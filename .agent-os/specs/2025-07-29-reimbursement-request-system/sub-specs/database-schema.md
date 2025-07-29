# Database Schema

This is the database schema implementation for the spec detailed in @.agent-os/specs/2025-07-29-reimbursement-request-system/spec.md

> Created: 2025-07-29
> Version: 1.0.0

## Schema Changes

### New Tables

#### reimbursement_requests
Primary table for storing reimbursement request data with comprehensive tracking.

```sql
CREATE TABLE reimbursement_requests (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  
  -- Request Details
  title VARCHAR(255) NOT NULL,
  description TEXT NOT NULL,
  amount_cents INTEGER NOT NULL CHECK (amount_cents > 0),
  currency VARCHAR(3) NOT NULL DEFAULT 'USD',
  expense_date DATE NOT NULL,
  category VARCHAR(100) NOT NULL,
  
  -- Workflow State
  aasm_state VARCHAR(50) NOT NULL DEFAULT 'draft',
  
  -- Approval Tracking
  submitted_at TIMESTAMP,
  reviewed_at TIMESTAMP,
  approved_at TIMESTAMP,
  rejected_at TIMESTAMP,
  paid_at TIMESTAMP,
  
  -- Approval Details
  approved_by_id BIGINT REFERENCES users(id),
  approved_amount_cents INTEGER,
  approval_notes TEXT,
  rejection_reason TEXT,
  
  -- Metadata
  request_number VARCHAR(20) UNIQUE NOT NULL,
  priority VARCHAR(20) DEFAULT 'normal',
  
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
```

#### reimbursement_request_state_changes
Audit trail for all state transitions and workflow events.

```sql
CREATE TABLE reimbursement_request_state_changes (
  id BIGSERIAL PRIMARY KEY,
  reimbursement_request_id BIGINT NOT NULL REFERENCES reimbursement_requests(id) ON DELETE CASCADE,
  user_id BIGINT NOT NULL REFERENCES users(id),
  
  -- State Change Details
  from_state VARCHAR(50),
  to_state VARCHAR(50) NOT NULL,
  event VARCHAR(50) NOT NULL,
  
  -- Additional Context
  notes TEXT,
  metadata JSONB DEFAULT '{}',
  
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
```

### Indexes and Constraints

#### Performance Indexes
```sql
-- Primary lookup indexes
CREATE INDEX idx_reimbursement_requests_user_id ON reimbursement_requests(user_id);
CREATE INDEX idx_reimbursement_requests_state ON reimbursement_requests(aasm_state);
CREATE INDEX idx_reimbursement_requests_category ON reimbursement_requests(category);
CREATE INDEX idx_reimbursement_requests_expense_date ON reimbursement_requests(expense_date DESC);

-- Admin dashboard indexes
CREATE INDEX idx_reimbursement_requests_submitted_at ON reimbursement_requests(submitted_at DESC) WHERE submitted_at IS NOT NULL;
CREATE INDEX idx_reimbursement_requests_approved_by ON reimbursement_requests(approved_by_id) WHERE approved_by_id IS NOT NULL;

-- Audit trail indexes
CREATE INDEX idx_state_changes_request_id ON reimbursement_request_state_changes(reimbursement_request_id, created_at DESC);
CREATE INDEX idx_state_changes_user_id ON reimbursement_request_state_changes(user_id);
```

#### Data Integrity Constraints
```sql
-- Ensure state transitions are valid
ALTER TABLE reimbursement_requests 
ADD CONSTRAINT check_valid_aasm_state 
CHECK (aasm_state IN ('draft', 'submitted', 'under_review', 'approved', 'rejected', 'paid'));

-- Ensure currency is valid ISO code
ALTER TABLE reimbursement_requests 
ADD CONSTRAINT check_valid_currency 
CHECK (currency ~ '^[A-Z]{3}$');

-- Ensure category is from allowed list
ALTER TABLE reimbursement_requests 
ADD CONSTRAINT check_valid_category 
CHECK (category IN ('travel', 'accommodation', 'meals', 'supplies', 'communications', 'events', 'other'));

-- Ensure priority is valid
ALTER TABLE reimbursement_requests 
ADD CONSTRAINT check_valid_priority 
CHECK (priority IN ('low', 'normal', 'high', 'urgent'));

-- Approval logic constraints
ALTER TABLE reimbursement_requests 
ADD CONSTRAINT check_approval_consistency 
CHECK ((approved_at IS NULL) = (approved_by_id IS NULL));

ALTER TABLE reimbursement_requests 
ADD CONSTRAINT check_approved_amount_when_approved 
CHECK ((aasm_state != 'approved') OR (approved_amount_cents IS NOT NULL));
```

### Active Storage Integration

The system will leverage existing Active Storage tables for file attachments:
- `active_storage_blobs` - File metadata and checksums
- `active_storage_attachments` - Polymorphic associations to reimbursement_requests
- `active_storage_variant_records` - Generated thumbnails and variants

#### Active Storage Association Setup
```ruby
# In ReimbursementRequest model
has_many_attached :receipts do |attachable|
  attachable.variant :thumbnail, resize_to_limit: [300, 300]
  attachable.variant :preview, resize_to_limit: [800, 600]
end
```

## Migration Strategy

### Migration 1: Create Core Tables
```ruby
class CreateReimbursementRequests < ActiveRecord::Migration[8.0]
  def change
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
      t.string :aasm_state, null: false, default: 'draft'
      
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
    
    add_index :reimbursement_requests, :user_id
    add_index :reimbursement_requests, :aasm_state
    add_index :reimbursement_requests, :category
    add_index :reimbursement_requests, :expense_date
    add_index :reimbursement_requests, :request_number, unique: true
  end
end
```

### Migration 2: Add State Change Audit Trail
```ruby
class CreateReimbursementRequestStateChanges < ActiveRecord::Migration[8.0]
  def change
    create_table :reimbursement_request_state_changes do |t|
      t.references :reimbursement_request, null: false, foreign_key: { on_delete: :cascade }
      t.references :user, null: false, foreign_key: true
      
      t.string :from_state
      t.string :to_state, null: false
      t.string :event, null: false
      t.text :notes
      t.jsonb :metadata, default: {}
      
      t.timestamp :created_at, null: false, default: -> { 'CURRENT_TIMESTAMP' }
    end
    
    add_index :reimbursement_request_state_changes, 
              [:reimbursement_request_id, :created_at], 
              name: 'idx_state_changes_request_time'
  end
end
```

### Migration 3: Add Database Constraints
```ruby
class AddReimbursementRequestConstraints < ActiveRecord::Migration[8.0]
  def up
    # Add check constraints for data integrity
    execute <<-SQL
      ALTER TABLE reimbursement_requests 
      ADD CONSTRAINT check_valid_aasm_state 
      CHECK (aasm_state IN ('draft', 'submitted', 'under_review', 'approved', 'rejected', 'paid'))
    SQL
    
    execute <<-SQL
      ALTER TABLE reimbursement_requests 
      ADD CONSTRAINT check_positive_amount 
      CHECK (amount_cents > 0)
    SQL
    
    execute <<-SQL
      ALTER TABLE reimbursement_requests 
      ADD CONSTRAINT check_valid_currency 
      CHECK (currency ~ '^[A-Z]{3}$')
    SQL
  end
  
  def down
    execute "ALTER TABLE reimbursement_requests DROP CONSTRAINT check_valid_aasm_state"
    execute "ALTER TABLE reimbursement_requests DROP CONSTRAINT check_positive_amount"
    execute "ALTER TABLE reimbursement_requests DROP CONSTRAINT check_valid_currency"
  end
end
```

## Data Seeding Requirements

### Reference Data
- **Categories**: Predefined expense categories (travel, accommodation, meals, supplies, communications, events, other)
- **Currency Codes**: Support for USD primarily, with EUR and GBP for international committees
- **Priority Levels**: Standard priority classifications (low, normal, high, urgent)

### Test Data
- Sample reimbursement requests in various states for testing workflows
- Mock receipt attachments for development and testing
- User assignments across different roles for permission testing

## Performance Considerations

### Query Optimization
- **Composite indexes** for common dashboard queries combining state and date filters
- **Partial indexes** for active requests to improve admin dashboard performance
- **JSONB indexing** on metadata fields for advanced filtering capabilities

### Archival Strategy
- **Soft deletion** pattern for maintaining audit trails while improving query performance
- **Data retention policies** for old requests and associated files
- **Automated cleanup** of temporary files and expired attachments

### Scaling Considerations
- **Table partitioning** by date for large-scale deployments
- **Read replicas** for reporting and analytics queries
- **Connection pooling** optimization for concurrent request processing