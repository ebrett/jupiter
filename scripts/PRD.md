# Product Requirements Document: Financial Request Forms Application

## Executive Summary

Replace the current Google Forms system for payment and vendor reimbursement requests with a custom web application that integrates seamlessly with the existing NB-Finances processing system. The application will maintain compatibility with current data structures while improving validation, user experience, and processing efficiency.

## Current System Analysis

### Existing Forms
The current system uses five Google Forms types:
1. **Combined Reimbursement/Vendor Form** (primary form in use)
2. **In-Kind Donations Form**
3. **Grant Reimbursement Form** (currently turned off)
4. **Grant Vendor Form** (currently turned off)
5. **Legacy Reimbursement/Vendor Forms** (no longer used)

### Processing Requirements
- Forms must be marked "paid" in Status column for processing
- System generates unique IDs to prevent duplicate processing
- Data flows to QuickBooks via bills and Google Sheets for tracking
- Supports multi-currency transactions with automatic conversion

## Data Models

### Core Data Types

#### Request Base Model
```typescript
interface RequestBase {
  id: string;                    // Auto-generated unique ID
  timestamp: Date;               // Submission timestamp
  status: 'submitted' | 'approved' | 'paid' | 'rejected';
  country: string;               // Country/Chapter from predefined list
  submittedBy: string;           // Name of submitter
  emailAddress: string;          // Submitter email
  notes?: string;                // Additional notes
  approvalDate?: Date;           // When approved
  approvalAttestation?: string;  // Approval signature
}
```

#### Payment Information
```typescript
interface PaymentInfo {
  payeeName: string;
  bankName: string;
  routingNumber: string;         // ABA, SWIFT/BIC, etc.
  accountNumber: string;         // Or IBAN
  additionalInfo?: string;       // For Brazil, Japan, UK, Ireland
  accountType: 'checking' | 'savings' | 'business';
  payeeAddress: string;
  payeeEmail?: string;
  payeePhone?: string;
}
```

#### Financial Transaction
```typescript
interface FinancialTransaction {
  requestCurrency: string;       // Currency requested (USD, EUR, etc.)
  totalAmountRequested: number;
  receiptCurrency: string;       // Currency of receipts/invoices
  amountPaid?: number;          // USD amount actually paid
  datePaid?: Date;
  transferMethod?: string;       // How payment was made
  nestCode?: string;            // Tracking code
}
```

#### Receipt/Invoice Item
```typescript
interface ReceiptItem {
  document: File | string;       // Receipt/invoice file or reference
  amount: number;
  vendorName: string;
  vendorAddress: string;
  purposeOfFunds: string;        // From predefined list
}
```

### Form-Specific Models

#### Combined Reimbursement/Vendor Request
```typescript
interface CombinedRequest extends RequestBase, PaymentInfo, FinancialTransaction {
  requestType: 'reimbursement' | 'vendor';
  receipts: ReceiptItem[];       // Up to 5 receipts/invoices
  certification: string;        // Digital signature
}
```

#### In-Kind Donation
```typescript
interface InKindDonation extends RequestBase {
  donorName: string;
  donorAddress: string;
  donorOccupationEmployer: string;
  usdValue: number;
  donationDate: Date;
  purposeOfFunds: string;
  certification: string;
}
```

## Validation Rules

### Business Logic Validation
1. **Status Workflow**: Only approved requests can be marked "paid"
2. **Currency Consistency**: All receipts/invoices must use same currency
3. **Amount Reconciliation**: Receipt amounts must sum to total requested
4. **File Requirements**: Receipts/invoices must be uploaded and readable
5. **Purpose Validation**: Purpose of funds must match predefined chart of accounts
6. **Country Authorization**: Users can only submit for authorized countries/chapters

### Data Validation
- **Email Format**: Valid email addresses required
- **Numeric Fields**: Amounts must be positive numbers
- **Date Validation**: Dates must be reasonable (not future for receipts)
- **File Types**: Accept PDF, JPG, PNG for receipts
- **Currency Codes**: Must use valid ISO currency codes
- **Bank Details**: Format validation for routing/account numbers

## Predefined Data Lists

### Countries and Chapters
```typescript
const COUNTRIES = [
  'Argentina', 'Australia', 'Austria', 'Belgium', 'Brazil',
  'Canada', 'Caribbean Islands', 'China', 'Colombia', 'Costa Rica',
  'Czech Republic', 'Denmark', 'Dominican Republic', 'Ecuador',
  'Finland', 'France', 'Germany', 'Greece', 'Guatemala', 'Hungary',
  'India', 'Ireland', 'Israel', 'Italy', 'Japan', 'Kenya',
  'Luxembourg', 'Mexico', 'Netherlands', 'New Zealand', 'Norway',
  'Panama', 'Philippines', 'South Africa', 'South Korea', 'Spain',
  'Sweden', 'Switzerland', 'Thailand', 'United Arab Emirates',
  'United Kingdom', '1_Global'
];

const CANADA_CHAPTERS = [
  'Canada - Alberta', 'Canada - Atlantic Provinces', 'Canada - BC Mainland',
  'Canada - Capital Region', 'Canada - Grand River', 'Canada - Hamilton-Burlington',
  'Canada - London', 'Canada - Manitoba', 'Canada - Niagara',
  'Canada - Quebec', 'Canada - Toronto', 'Canada - Victoria', 'Canada - Windsor'
];

const MEXICO_CHAPTERS = [
  'Mexico - Baja California', 'Mexico - Costa Banderas', 'Mexico - Ciudad de Mexico',
  'Mexico - Guadalajara', 'Mexico - Lake Chapala', 'Mexico - Istmo',
  'Mexico - San Miguel de Allende', 'Mexico - Yucatan'
];
```

### Purpose of Funds (Chart of Accounts)
```typescript
const EXPENSE_PURPOSES = [
  'Digital Media Advertising',
  'Materials & Swag',
  'Phone Banking',
  'Political Analyst',
  'Postage mail campaigns',
  'Print & Billboard Advertising',
  'Printing & Design',
  'Radio',
  'Voter Protection',
  'Accounting Expenses',
  'Bank fees',
  'Domain Registration',
  'Insurance',
  'Membership Dues',
  'Office Supplies and Equipment',
  'Post Office & Postage',
  'Wise Wire Services',
  'Operations/Systems',
  'Conferencing/Collaboration',
  'Voter Services, Outreach & Support',
  'Membership Management'
];
```

### Supported Currencies
```typescript
const CURRENCIES = [
  'USD', 'EUR', 'GBP', 'CAD', 'AUD', 'JPY', 'CHF', 'SEK', 'NOK', 'DKK',
  'MXN', 'BRL', 'ARS', 'CZK', 'THB', 'ZAR', 'ILS', 'KES', 'NGN', 'RUB', 'NZD'
];
```

## User Interface Requirements

### Form Steps

#### Step 1: Request Type Selection
- Radio buttons for request type (Reimbursement/Vendor/In-Kind)
- Country/Chapter dropdown with search
- Basic submitter information

#### Step 2: Payment Information (if applicable)
- Payee details form
- Bank information with validation
- Currency selection
- Total amount requested

#### Step 3: Receipts/Invoices
- Dynamic receipt entry (up to 5)
- File upload with preview
- Amount and vendor details per receipt
- Purpose of funds dropdown
- Running total validation

#### Step 4: Review and Submit
- Summary of all entered data
- Certification checkbox and digital signature
- Submit button with confirmation

### Administrative Interface
- View all submitted requests
- Filter by status, country, date range
- Approve/reject requests
- Mark as paid with payment details
- Export to CSV for external processing

## Technical Requirements

### Output Format
Maintain compatibility with existing Google Sheets structure:
- Same column order as current Combined form (48 columns)
- Identical data formatting and validation
- Support for existing error codes and processing logic

### Integration Points
1. **Google Sheets API**: Write approved requests to processing sheets
2. **File Storage**: Store receipt/invoice files (Google Drive or AWS S3)
3. **Email Notifications**: Notify on status changes
4. **Authentication**: Integration with existing user management

### Performance Requirements
- Form submission < 5 seconds
- File uploads < 30 seconds for standard receipts
- Support 100+ concurrent users
- 99.9% uptime during business hours

## Suggested Improvements

### Enhanced Validation
1. **Real-time currency conversion**: Show USD equivalent amounts
2. **Bank validation**: Verify routing numbers and account formats
3. **Duplicate detection**: Flag potential duplicate submissions
4. **Receipt OCR**: Extract amounts and vendors from uploaded receipts

### Workflow Improvements
1. **Progressive saving**: Auto-save form data as user progresses
2. **Approval workflow**: Multi-level approval for large amounts
3. **Batch processing**: Allow multiple receipts for single vendor
4. **Mobile optimization**: Responsive design for mobile submission

### Processing Enhancements
1. **Structured data export**: JSON format for easier processing
2. **API endpoints**: Direct integration with QB processing
3. **Automated status updates**: Sync payment status from QB
4. **Analytics dashboard**: Spending trends and approval metrics

### Data Quality
1. **Vendor database**: Maintain list of common vendors with auto-complete
2. **Purpose templates**: Common expense templates for quick entry
3. **Address validation**: Verify payee addresses for accuracy
4. **Amount reconciliation**: Flag discrepancies between totals and receipts

## Migration Strategy

### Phase 1: MVP Implementation
- Combined Reimbursement/Vendor form
- In-Kind donation form
- Basic validation and Google Sheets output
- Administrative approval interface

### Phase 2: Enhanced Features
- Advanced validation and OCR
- Mobile optimization
- Improved user experience
- Analytics and reporting

### Phase 3: Full Integration
- Direct QB API integration
- Automated status synchronization
- Advanced workflow management
- Complete legacy system replacement

## Success Metrics

1. **Processing Efficiency**: Reduce manual data entry by 80%
2. **Error Reduction**: Decrease validation errors by 60%
3. **User Satisfaction**: 90%+ approval rating from regular users
4. **Processing Time**: Reduce average approval cycle by 50%
5. **Data Quality**: 95%+ clean data rate (no manual corrections needed)

This application will significantly improve the financial request process while maintaining full compatibility with the existing NB-Finances processing system.