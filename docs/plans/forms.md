# Rails Application Replacement Plan for RVI Forms

## Executive Summary

This plan outlines the requirements and phased approach for creating Rails-based forms to replace the current Google Forms for reimbursement requests, vendor payments, and in-kind donations. The Rails application will integrate with existing Google Sheets by appending approved payments directly to the sheets currently used by NB-Finances Python scripts.

## High-Level Requirements

### Functional Requirements

1. **Three Form Types**
   - Payment reimbursement request form
   - Vendor payment request form  
   - In-kind donation form

2. **Form Features**
   - Dynamic form fields based on request type
   - File upload for receipts/documentation
   - Multi-currency support with automatic exchange rates
   - Form validation and business rules
   - Save draft functionality
   - Email notifications

3. **Approval Workflow**
   - Country chair approval routing
   - Status tracking (Submitted, Approved, Rejected, Paid)
   - Audit trail of all changes

4. **Data Export Options**
   - Option 1: Download CSV files in current format
   - Option 2: Direct export to Google Sheets (append approved payments)
   - Google Sheets integration settings in general configuration

5. **Administrative Features**
   - Dashboard for monitoring submissions
   - Configuration management for dropdown values
   - General settings for Google Sheets integration

### Design Principles

1. **Flexibility**: Modular design to accommodate future changes
2. **Compatibility**: Maintain exact format compatibility with existing sheets
3. **Integration**: Seamless connection to existing Google Sheets workflow

## Current Google Sheets Structure

The NB-Finances scripts currently use two Google Sheets populated by forms:

1. **Combined Sheet**: Receives both reimbursement and vendor payment requests
2. **In-Kind Sheet**: Receives in-kind donation records

The Rails application will maintain this two-sheet output structure while providing three separate input forms for better user experience.

## Form Fields and Formats

### Common Fields (All Forms)

| Field Name | Type | Required | Validation | Notes |
|------------|------|----------|------------|-------|
| timestamp | datetime | Yes | Auto-generated | Submission timestamp |
| country | select | Yes | Valid country code | From location list |
| submitter_email | email | Yes | Valid email format | Current user email |
| submitter_name | string | Yes | Max 255 chars | Current user name |
| approver_email | email | Yes | Valid email format | Based on country |
| approver_name | string | Yes | Max 255 chars | Based on country |
| status | select | Yes | Submitted/Approved/Rejected/Paid | Workflow status |
| amount_requested | decimal | Yes | > 0, 2 decimals | Original currency amount |
| currency | select | Yes | Valid currency code | From currency list |
| amount_usd | decimal | Auto | Calculated | Auto-converted to USD |
| exchange_rate | decimal | Auto | > 0, 6 decimals | From API or manual |

### Payment Reimbursement Form Fields

| Field Name | Type | Required | Validation | Notes |
|------------|------|----------|------------|-------|
| request_type | hidden | Yes | Fixed: 'R' | Reimbursement identifier |
| purpose | select | Yes | Valid purpose code | From purpose list |
| expense_category | select | Yes | Valid QB category | From category list |
| description | text | Yes | Max 1000 chars | Expense description |
| date_incurred | date | Yes | Not future date | When expense occurred |
| payment_method | select | Yes | Valid method | How originally paid |
| payee_name | string | Yes | Max 255 chars | Person to reimburse |
| payee_email | email | Yes | Valid email | For payment notification |
| payee_address | text | No | Max 500 chars | Mailing address |
| receipt_urls | file[] | Yes | PDF/Image, Max 10MB each | Receipt uploads |

### Vendor Payment Form Fields

| Field Name | Type | Required | Validation | Notes |
|------------|------|----------|------------|-------|
| request_type | hidden | Yes | Fixed: 'V' | Vendor identifier |
| purpose | select | Yes | Valid purpose code | From purpose list |
| expense_category | select | Yes | Valid QB category | From category list |
| vendor_name | string | Yes | Max 255 chars | Business name |
| vendor_email | email | No | Valid email | For notifications |
| vendor_address | text | Yes | Max 500 chars | Business address |
| vendor_tax_id | string | No | Max 50 chars | Tax ID if applicable |
| invoice_number | string | Yes | Max 100 chars | Vendor invoice # |
| invoice_date | date | Yes | Valid date | Invoice date |
| due_date | date | No | >= invoice_date | Payment due date |
| payment_terms | string | No | Max 100 chars | Net 30, etc. |
| invoice_urls | file[] | Yes | PDF/Image, Max 10MB each | Invoice uploads |
| description | text | Yes | Max 1000 chars | Payment description |

### In-Kind Donation Form Fields

| Field Name | Type | Required | Validation | Notes |
|------------|------|----------|------------|-------|
| request_type | hidden | Yes | Fixed: 'I' | In-kind identifier |
| donor_name | string | Yes | Max 255 chars | Person/company donating |
| donor_email | email | Yes | Valid email | For acknowledgment |
| donor_address | text | Yes | Max 500 chars | For tax receipt |
| donation_type | select | Yes | Goods/Services | Type of in-kind |
| item_description | text | Yes | Max 1000 chars | What was donated |
| expense_category | select | Yes | Valid QB category | From category list |
| fair_market_value | decimal | Yes | > 0, 2 decimals | Estimated value |
| donation_date | date | Yes | Not future | When donated |
| acknowledgment_sent | boolean | No | Default false | Track thank you |

## Google Sheets Integration

### Output Configuration

```yaml
google_sheets:
  combined_sheet:
    sheet_id: "configured_in_settings"
    worksheet_name: "Form Responses 1"
    append_mode: true
    output_types: ["R", "V"]  # Reimbursements and Vendors
    
  inkind_sheet:
    sheet_id: "configured_in_settings" 
    worksheet_name: "Form Responses 1"
    append_mode: true
    output_types: ["I"]  # In-kind only
```

### Column Mapping

The Rails app must output data in the exact column order expected by the Python scripts:

**Combined Sheet Columns (Reimbursements & Vendors)**:
```
Timestamp,Email Address,Name,Urgency,Country,Chapter,Purpose,QuickBooks Coding,
Amount Requested,Exchange Rate,Currency,Amount (USD),Description,Date Incurred,
Request Type,Payment Method,Receipt URLs,Payee Name,Payee Email,Payee Address,
Vendor Name,Vendor Email,Vendor Address,Invoice Number,Invoice Date,Due Date,
Status,Approver Email,Approver Name,Approval Date,Payment Date,Check Number,Notes
```

**In-Kind Sheet Columns**:
```
Timestamp,Email Address,Name,Country,Donor Name,Donor Email,Donor Address,
Donation Type,Item Description,QuickBooks Coding,Fair Market Value,Currency,
Amount (USD),Exchange Rate,Donation Date,Acknowledgment Sent,Status,
Approver Email,Approver Name,Approval Date,Notes
```

## Database Schema

### Core Tables

```ruby
# Requests (flexible JSONB storage for adaptability)
create_table :requests do |t|
  t.string :request_type, null: false # R, V, I
  t.string :request_number, null: false, index: true
  t.integer :status, default: 0 # enum: submitted, approved, rejected, paid
  t.decimal :amount_requested, precision: 10, scale: 2
  t.string :currency_code
  t.decimal :amount_usd, precision: 10, scale: 2
  t.decimal :exchange_rate, precision: 10, scale: 6
  t.jsonb :form_data, null: false # All form fields stored here
  t.jsonb :metadata # Tracking, approvals, etc.
  t.timestamps
end

# Attachments
create_table :attachments do |t|
  t.references :request, null: false
  t.string :file_type # receipt, invoice, documentation
  t.string :file_name
  t.string :file_url
  t.integer :file_size
  t.timestamps
end

# Settings (for Google Sheets configuration)
create_table :settings do |t|
  t.string :key, null: false, index: true
  t.jsonb :value
  t.timestamps
end
```

### Reference Tables (Maintained for dropdowns)

```ruby
# Locations (Countries/Chapters)
create_table :locations do |t|
  t.string :code, null: false
  t.string :name, null: false
  t.string :location_type # country, chapter
  t.references :parent, foreign_key: { to_table: :locations }
  t.boolean :active, default: true
  t.timestamps
end

# Expense Categories
create_table :expense_categories do |t|
  t.string :code, null: false
  t.string :name, null: false
  t.references :parent, foreign_key: { to_table: :expense_categories }
  t.string :qb_account_id
  t.boolean :active, default: true
  t.timestamps
end

# Other reference tables: payment_methods, purposes, currencies
```

## Phased Implementation Approach

### Phase 1: Foundation & First Form (3-4 weeks)
**Goal**: Working reimbursement form with CSV export

- Rails application setup
- Reimbursement form implementation
- File upload functionality
- CSV export matching current format
- Basic admin dashboard

**Deliverables**:
- Working reimbursement form
- CSV download functionality
- Form matches existing Google Form fields

### Phase 2: Complete Forms (3-4 weeks)
**Goal**: All three forms operational

- Vendor payment form
- In-kind donation form
- Approval workflow
- Email notifications
- Enhanced validation

**Deliverables**:
- All three forms functional
- Approval workflow active
- Email integration complete

### Phase 3: Google Sheets Integration (2-3 weeks)
**Goal**: Direct sheet integration

- Google Sheets API integration
- Append functionality for approved items
- Settings interface for sheet configuration
- Error handling and retry logic

**Deliverables**:
- Direct export to Google Sheets
- Configuration interface
- Error handling system

### Phase 4: Polish & Migration (2-3 weeks)
**Goal**: Production-ready system

- Performance optimization
- Enhanced admin features
- Data migration tools
- Parallel running period
- Documentation

**Deliverables**:
- Production-ready system
- Migration tools
- User documentation

## Flexible Design Considerations

### Extensibility Points

1. **Form Fields**: JSONB storage allows easy addition/removal of fields
2. **Validation Rules**: Configurable validation stored in settings
3. **Export Formats**: Pluggable export system for future formats
4. **Integrations**: Service layer pattern for adding new integrations

### Configuration Management

```ruby
class FormConfiguration
  # Dynamic field definitions
  def self.fields_for(request_type)
    # Load from database or config file
    # Allows changing fields without code changes
  end
  
  # Validation rules
  def self.validations_for(request_type)
    # Configurable validation rules
  end
  
  # Export mappings
  def self.export_mapping_for(request_type)
    # Maps internal fields to export columns
  end
end
```

## Dropdown Option Tables

### Payment Methods (9 options)
- Apple Pay, Cash, Check, Credit Card
- Google Pay, In-Kind, PayPal, Wire Transfer, Wise

Note: ActBlue removed as it no longer accepts international donations

### Expense Categories (97 options)
Complete hierarchical list including:
- DONATIONS (parent)
- FUNDRAISING COSTS
- LEGAL & PROFESSIONAL SERVICES
- MEETINGS, EVENTS & TRAVEL
- OPERATIONAL COSTS
- PROGRAM EXPENSES
- TECHNOLOGY

### Countries/Locations (65+ options)
All Democrats Abroad countries and chapters

### Currencies (21 options)
USD, EUR, GBP, CAD, AUD, CHF, JPY, MXN, BRL, ARS, THB, ZAR, SEK, NZD, RUB, NGN, CZK, DKK, ILS, NOK, KES

### Request Status (4 options)
Submitted, Approved, Rejected, Paid

## Success Metrics

1. **Form Completion Rate**: > 95% successful submissions
2. **Export Success Rate**: > 99.9% successful Google Sheets updates
3. **Processing Time**: < 5 seconds per form submission
4. **Data Accuracy**: 100% format compatibility with existing sheets
5. **System Availability**: 99.9% uptime during business hours

