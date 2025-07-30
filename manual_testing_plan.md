# Manual Testing Plan - Reimbursement Request System

## Prerequisites

1. Start the development server: `bin/tmux-dev`
2. Ensure test data is loaded: `bin/rails runner manual_test_setup.rb`
3. Open browser to: http://localhost:3000

## Test Users

All test users use password: `password123`

### Regular Users
- **test@example.com** - Regular user (can submit requests)
- **john.doe@example.com** - Regular user

### Admin Users
- **admin@example.com** - System administrator (all permissions)
- **treasury@example.com** - Treasury admin (can approve/reject requests)

## Test Scenarios

### 1. Member-Facing Features

#### 1.1 View Reimbursement Requests
1. Sign in as `test@example.com`
2. Navigate to `/reimbursement_requests`
3. **Expected**: See list of your own requests only
4. **Verify**: 
   - Request number, title, amount, status are displayed
   - Can see draft and submitted requests
   - Cannot see other users' requests

#### 1.2 Create New Request
1. Click "New Reimbursement Request" button
2. Fill out form:
   - Title: "Conference Travel Expenses"
   - Description: "Travel to DA Global Conference 2025"
   - Amount: 250.50
   - Currency: USD
   - Expense Date: (any recent date)
   - Category: travel
   - Priority: normal
3. **Do NOT attach receipts yet**
4. Click "Create Reimbursement request"
5. **Expected**: Request created in "draft" status
6. **Verify**: Redirected to request details page

#### 1.3 Edit Draft Request
1. From the request details page (while in draft status)
2. Click "Edit" button
3. Change amount to 275.00
4. Add a receipt file (any PDF or image)
5. Click "Update Reimbursement request"
6. **Expected**: Request updated successfully
7. **Verify**: New amount shown, receipt attached

#### 1.4 Submit Request for Approval
1. From the request details page
2. Click "Submit for Approval" button
3. **Expected**: 
   - Request status changes to "submitted"
   - Edit button disappears
   - Submit button disappears
4. **Verify**: Cannot edit submitted request

#### 1.5 Test Validation
1. Click "New Reimbursement Request"
2. Try to submit empty form
3. **Expected**: Validation errors for required fields
4. Fill in amount as negative number (-50)
5. **Expected**: Amount must be greater than 0

### 2. Treasury Admin Features

#### 2.1 Admin Dashboard Access
1. Sign out and sign in as `treasury@example.com`
2. Navigate to `/admin/reimbursement_requests`
3. **Expected**: See ALL reimbursement requests from all users
4. **Verify**:
   - Can see requests from test@example.com
   - Status filter dropdown is available
   - Export CSV link is present

#### 2.2 Filter Requests
1. Use status dropdown to filter by "submitted"
2. **Expected**: Only submitted requests shown
3. Clear filter and filter by specific user
4. **Expected**: Only that user's requests shown

#### 2.3 View Request Details
1. Click on a submitted request
2. **Expected**: See full details including:
   - All request information
   - Submitter details
   - Audit trail events
   - Action buttons (Approve, Reject, Request Info)

#### 2.4 Approve Request
1. Find a submitted request
2. Click "Approve" button
3. Enter approval notes: "Approved for conference attendance"
4. Optionally modify approved amount
5. Click "Confirm Approval"
6. **Expected**:
   - Request status changes to "approved"
   - Approval event in audit trail
   - Approved by shows your name
   - Success notification

#### 2.5 Reject Request
1. Find another submitted request
2. Click "Reject" button
3. Enter rejection reason: "Missing required receipts"
4. Click "Confirm Rejection"
5. **Expected**:
   - Request status changes to "rejected"
   - Rejection event in audit trail with reason
   - Success notification

#### 2.6 Request Additional Information
1. Find a submitted request
2. Click "Request Info" button
3. Enter message: "Please provide hotel receipt"
4. Click "Send Request"
5. **Expected**:
   - Request status changes to "under_review"
   - Info request event in audit trail
   - Success notification

#### 2.7 Mark as Paid
1. Find an approved request
2. Click "Mark as Paid" button
3. Enter payment reference (optional)
4. Click "Confirm Payment"
5. **Expected**:
   - Request status changes to "paid"
   - Payment event in audit trail
   - Success notification

#### 2.8 Bulk Operations
1. Go back to admin index page
2. Select multiple submitted requests using checkboxes
3. Click "Bulk Approve Selected"
4. Enter bulk approval notes
5. **Expected**:
   - All selected requests approved
   - Success message with count
   - Each request has approval event

#### 2.9 Export to CSV
1. Click "Export to CSV" link
2. **Expected**: Download CSV file with all requests
3. Open in spreadsheet application
4. **Verify** columns:
   - Request Number, Title, Description
   - Amount, Currency, Category, Priority
   - Status, Submitter Name/Email
   - Dates (expense, submitted, approved, paid)

### 3. Authorization Tests

#### 3.1 Regular User Cannot Access Admin
1. Sign in as `test@example.com`
2. Try to navigate to `/admin/reimbursement_requests`
3. **Expected**: Access denied, redirected to home page

#### 3.2 Regular User Cannot See Others' Requests
1. As `test@example.com`
2. Try to access another user's request by ID
3. **Expected**: Access denied or not found

#### 3.3 Admin Can Perform All Actions
1. Sign in as `admin@example.com`
2. Verify same admin capabilities as treasury user
3. **Expected**: Full access to all admin features

### 4. Edge Cases

#### 4.1 State Transition Validation
1. As admin, try to approve an already approved request
2. **Expected**: Error message about invalid state transition
3. Try to mark a submitted request as paid (skipping approval)
4. **Expected**: Error - must be approved first

#### 4.2 File Upload Limits
1. Create new request as regular user
2. Try to attach very large file (>10MB)
3. **Expected**: File size validation error
4. Try to attach non-allowed file type (.exe)
5. **Expected**: File type validation error

#### 4.3 Concurrent Updates
1. Open same request in two browser tabs as admin
2. Approve in first tab
3. Try to reject in second tab
4. **Expected**: Error about request already being approved

### 5. UI/UX Verification

#### 5.1 Responsive Design
1. Test on mobile viewport (use browser dev tools)
2. **Verify**:
   - Forms are usable on mobile
   - Tables scroll horizontally if needed
   - Buttons are tap-friendly

#### 5.2 Loading States
1. Submit forms and observe loading indicators
2. **Expected**: Clear feedback during submission

#### 5.3 Error Handling
1. Cause deliberate errors (invalid data, etc.)
2. **Expected**: User-friendly error messages
3. **Verify**: Can recover from errors without data loss

## Performance Checks

1. **Index Page Load**: Should load within 2 seconds with 50+ requests
2. **CSV Export**: Should handle 500+ requests without timeout
3. **File Uploads**: Should handle 5MB files smoothly

## Browser Compatibility

Test core workflows in:
- Chrome (latest)
- Firefox (latest)
- Safari (latest)
- Edge (latest)

## Logging Verification

After testing, check logs for:
1. No 500 errors
2. Proper audit trail entries
3. No N+1 query warnings
4. Successful file upload processing

## Bug Reporting

If you find issues:
1. Note the exact steps to reproduce
2. Check browser console for errors
3. Check Rails logs for stack traces
4. Take screenshots if UI issues
5. Document in `/docs/development_journal.md`