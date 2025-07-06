# Forms System

Jupiter includes a flexible forms system for handling various types of financial requests. This document covers the architecture, implementation, and usage of the forms system.

## Overview

The forms system is built using a Single Table Inheritance (STI) pattern with a flexible JSONB data storage approach, allowing for different form types while maintaining data consistency.

### Current Form Types

1. **In-Kind Donations** (Phase 1 - Implemented)
   - Captures donated goods and services
   - Tracks fair market value
   - Integrates with QuickBooks expense categories

2. **Reimbursement Requests** (Planned)
   - Employee expense reimbursements
   - Receipt tracking and validation
   - Multi-level approval workflow

3. **Vendor Payment Requests** (Planned)
   - Direct vendor payments
   - Invoice processing
   - Purchase order management

## Architecture

### Database Schema

The forms system uses a flexible schema with STI:

```ruby
# Base Request model
class Request < ApplicationRecord
  self.inheritance_column = :request_type
  
  enum :request_type, {
    inkind: 'I',
    reimbursement: 'R', 
    vendor: 'V'
  }
  
  # JSONB column for flexible form data
  # Shared fields stored as regular columns
  # Form-specific data stored in form_data JSONB
end

# Specific form types inherit from Request
class InkindRequest < Request
  # Validation and business logic specific to in-kind donations
end
```

### Key Components

- **Models**: STI-based request models with form-specific validations
- **Controllers**: RESTful controllers for each form type
- **ViewComponents**: Reusable form components with client-side validation
- **Policies**: Pundit-based authorization for role-based access
- **Services**: CSV export and data processing

## In-Kind Donations (Phase 1)

### Features

- **Form Fields**:
  - Donor information (name, email, address)
  - Donation details (type, description, date)
  - Fair market value
  - QuickBooks expense category
  - Country (auto-filled for US)

- **Validation**:
  - Required field validation
  - Email format validation
  - Date validation
  - Fair market value must be positive

- **Authorization**:
  - Submitters can create new donations
  - Admins can view all donations and export data
  - Role-based access control via Pundit

### Usage

```ruby
# Create a new in-kind donation
donation = InkindRequest.new(
  amount_requested: 150.00,
  form_data: {
    donor_name: 'John Doe',
    donor_email: 'john@example.com',
    # ... other form fields
  }
)

# Access form data
donation.donor_name              # "John Doe"
donation.form_data['donor_name'] # "John Doe"

# CSV export
InkindRequest.to_csv
```

### CSV Export

The system generates CSV exports compatible with existing NB-Finances Python scripts:

```csv
Timestamp,Email Address,Name,Country,Donor Name,Donor Email,Donor Address,Donation Type,Item Description,Fair Market Value,QuickBooks Account,Date of Donation,Request Number
2024-01-15 10:30:00,user@example.com,John Smith,US,Jane Donor,jane@example.com,123 Main St,Goods,Legal consultation,$150.00,LEGAL_CONSULTING,2024-01-15,IK-2025-001
```

## Implementation Details

### ViewComponent Architecture

Forms use ViewComponent for reusable UI elements:

```ruby
# app/components/inkind_donation_form_component.rb
class InkindDonationFormComponent < ViewComponent::Base
  def initialize(inkind_request:, expense_categories:)
    @inkind_request = inkind_request
    @expense_categories = expense_categories
  end
  
  private
  
  attr_reader :inkind_request, :expense_categories
end
```

### Client-Side Validation

Stimulus controllers provide real-time validation:

```javascript
// app/javascript/controllers/inkind_form_controller.js
export default class extends Controller {
  static targets = ["donorEmail", "fairMarketValue"]
  
  validateEmail() {
    // Real-time email validation
  }
  
  validateAmount() {
    // Real-time amount validation
  }
}
```

### Request Numbering

Automatic request number generation:

- **Format**: `{PREFIX}-{YEAR}-{SEQUENCE}`
- **Examples**: 
  - `IK-2025-001` (In-Kind)
  - `RB-2025-001` (Reimbursement)
  - `VP-2025-001` (Vendor Payment)

## Authorization

Role-based access control using Pundit:

### Roles and Permissions

| Role | New | View | Export | Edit |
|------|-----|------|--------|------|
| Submitter | ✓ | Own only | ✗ | Own only |
| Admin | ✓ | All | ✓ | All |
| Viewer | ✗ | All | ✗ | ✗ |

### Policy Implementation

```ruby
class InkindRequestPolicy < ApplicationPolicy
  def create?
    user.can_submit_requests?
  end
  
  def index?
    user.system_administrator?
  end
  
  def export?
    user.system_administrator?
  end
end
```

## Future Enhancements

### Phase 2: Approval Workflow

- Multi-step approval process
- Email notifications
- Status tracking and history
- Approval delegation

### Phase 3: File Attachments

- Receipt and document upload
- Image processing and thumbnails
- Secure file storage
- Virus scanning

### Phase 4: Advanced Features

- Digital signatures
- Integration with accounting systems
- Advanced reporting and analytics
- Mobile-responsive design improvements

## Testing

Comprehensive test coverage includes:

```bash
# Run forms-related tests
bin/rspec spec/models/request_spec.rb
bin/rspec spec/models/inkind_request_spec.rb
bin/rspec spec/controllers/inkind_donations_controller_spec.rb
bin/rspec spec/policies/inkind_request_policy_spec.rb
bin/rspec spec/components/inkind_donation_form_component_spec.rb
```

## Configuration

### Expense Categories

QuickBooks expense categories are managed via:

```ruby
# Seeds data
ExpenseCategory.create!(
  code: 'LEGAL_CONSULTING',
  name: 'Legal and Consulting Services'
)

# Access in forms
@expense_categories = ExpenseCategory.all.pluck(:name, :code)
```

### Environment Variables

No additional environment variables required for basic forms functionality. OAuth configuration needed for user authentication (see [OAuth documentation](OAUTH.md)).

## Troubleshooting

### Common Issues

**Validation errors:**
- Check required fields are properly filled
- Verify email format is valid
- Ensure fair market value is positive

**Permission denied:**
- Verify user has 'submitter' role for creation
- Check admin permissions for viewing/exporting

**CSV export issues:**
- Ensure sufficient data exists
- Check QuickBooks category mappings
- Verify date formats

### Debug Commands

```ruby
# Rails console debugging
InkindRequest.count                    # Check record count
InkindRequest.last.form_data          # Inspect form data
User.find(1).can_submit_requests?     # Check permissions
```