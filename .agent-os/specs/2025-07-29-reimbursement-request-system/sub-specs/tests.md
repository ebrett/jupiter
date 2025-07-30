# Tests Specification

This is the tests coverage details for the spec detailed in @.agent-os/specs/2025-07-29-reimbursement-request-system/spec.md

> Created: 2025-07-29
> Version: 1.0.0

## Test Coverage

### Unit Tests

**ReimbursementRequest Model**
- Validates presence of required fields (title, description, amount_cents, expense_date, category)
- Validates amount_cents is positive integer
- Validates currency is valid 3-letter ISO code
- Validates category is from allowed list
- Validates expense_date is not in future beyond reasonable threshold
- Associates correctly with user and approved_by user
- Generates unique request_number on creation
- Handles currency conversion and formatting
- Validates state machine transitions with AASM
- Triggers audit trail creation on state changes
- Scopes requests by status and user appropriately

**ReimbursementRequestStateChange Model**
- Validates presence of required fields (reimbursement_request, user, to_state, event)
- Associates correctly with reimbursement_request and user
- Stores metadata as valid JSON
- Orders records by creation timestamp
- Provides audit trail querying methods

**User Model Extensions**
- Associates with reimbursement_requests as requester
- Associates with approved reimbursement_requests as approver
- Provides convenience methods for request counts and totals
- Handles user deletion with appropriate cascading or restrictions

**ReimbursementRequestPolicy**
- Allows users to view only their own requests
- Allows users to create new requests
- Allows users to update only draft requests
- Prevents users from accessing other users' requests
- Allows treasury staff to view all requests in scope
- Allows treasury staff to approve/reject requests
- Prevents non-treasury users from administrative actions

**Admin::ReimbursementRequestPolicy**
- Inherits appropriate permissions from base policy
- Adds treasury-specific permissions for approval actions
- Implements jurisdictional scoping for treasury staff
- Allows admin users full access with audit logging

### Integration Tests

**ReimbursementRequestsController**
- GET #index renders user's requests with proper filtering (JSON)
- GET #index renders HTML template with schema-compatible data display
- GET #show displays request details with authorization (JSON)
- GET #show renders HTML template with all request attributes correctly
- GET #new renders form with proper Catalyst components (JSON)
- GET #new renders HTML form template with correct field names and schema
- POST #create successfully creates request with valid params
- POST #create renders form with errors for invalid params
- POST #create handles file uploads with Active Storage
- PATCH #update modifies draft requests successfully
- PATCH #update prevents editing submitted requests
- DELETE #destroy removes draft requests only
- Handles authorization failures with proper redirects
- Implements proper pagination for large request lists
- HTML view integration tests verify schema compatibility across all templates
- Form component tests ensure proper attribute mapping with new database schema

**Admin::ReimbursementRequestsController**
- GET #index renders admin dashboard with filtering
- GET #show displays detailed admin view with actions
- PATCH #approve transitions request to approved state
- PATCH #approve sends notification emails
- PATCH #approve creates audit trail entries
- PATCH #reject transitions request to rejected state
- PATCH #reject requires rejection reason
- PATCH #request_info sends info request to member
- PATCH #mark_paid updates payment status
- Handles concurrent editing scenarios gracefully
- Implements bulk actions for multiple requests

**ReceiptsController**
- GET #show serves files with proper authorization
- GET #show returns 404 for non-existent files
- GET #show denies access to unauthorized users
- DELETE #destroy removes receipts from draft requests
- DELETE #destroy prevents removal from submitted requests
- Handles Active Storage errors gracefully

**Email Notifications**
- Sends confirmation email on request submission
- Sends approval notification to treasury staff
- Sends status change notifications to requester
- Sends payment confirmation on completion
- Handles email delivery failures gracefully
- Uses proper email templates with branding

### System Tests

**Member Request Submission Workflow**
- Member logs in via NationBuilder OAuth
- Navigates to reimbursement request creation
- Fills out form with valid expense details
- Uploads receipt files successfully
- Submits request and receives confirmation
- Views request status in personal dashboard
- Receives email notification of submission
- Can edit draft requests before submission
- Cannot edit requests after submission

**Treasury Approval Workflow**
- Treasury staff logs in with appropriate role
- Views pending requests in admin dashboard
- Filters requests by status and category
- Opens request for detailed review
- Views uploaded receipts and expense details
- Approves request with optional notes
- Request status updates in real-time
- Member receives approval notification email
- Audit trail records approval action

**Request Rejection Workflow**
- Treasury staff opens submitted request
- Reviews expense details and receipts
- Rejects request with required reason
- Request status updates to rejected
- Member receives rejection notification with reason
- Member can view rejection details in dashboard
- Audit trail records rejection action

**Information Request Workflow**
- Treasury staff requests additional information
- Request status updates to "info_requested"
- Member receives notification with details
- Member can provide additional information
- Request returns to review status
- Process continues with approval/rejection

**Payment Processing Workflow**
- Treasury staff marks approved request as paid
- Enters payment reference and date
- Request status updates to paid
- Member receives payment confirmation
- Final audit trail entry created
- Request appears in payment history

**File Upload and Management**
- Upload various file types (PDF, JPG, PNG)
- Validate file size restrictions
- Display receipt previews in admin interface
- Download receipts with proper authorization
- Handle virus scanning and validation
- Remove receipts from draft requests

**Mobile Responsive Testing**
- Form submission works on tablet devices
- File upload functions on mobile browsers
- Admin dashboard displays properly on tablets
- Touch interactions work for approval actions
- Responsive design maintains usability

### Mocking Requirements

**Active Storage Mocking**
- Mock file uploads using fixture files
- Test file validation without actual virus scanning
- Simulate upload failures and error handling
- Mock thumbnail generation for testing

**Email Service Mocking**
- Mock Action Mailer for testing email content
- Test email delivery without sending actual emails
- Verify email recipients and content accuracy
- Simulate email delivery failures

**Time-based Mocking**
- Mock current time for testing date validations
- Test expense date validation with various scenarios
- Mock request submission timestamps
- Test audit trail timestamp accuracy

**External Service Mocking**
- Mock virus scanning service responses
- Simulate file processing delays and failures
- Mock thumbnail generation service
- Test graceful degradation when services unavailable

**Authentication Mocking**
- Mock NationBuilder OAuth for testing
- Create test users with various role combinations
- Mock session management and user context
- Test authorization scenarios with different user types

### Performance Testing

**Database Query Performance**
- Test dashboard loading with large request datasets
- Verify index usage for common filtering operations
- Test pagination performance with thousands of requests
- Monitor N+1 query issues in request listings

**File Upload Performance**
- Test direct upload functionality under load
- Verify progress indication accuracy
- Test concurrent file uploads
- Monitor memory usage during large file processing

**Real-time Update Performance**
- Test Turbo Stream updates with multiple users
- Verify broadcast performance with many connections
- Test status update propagation speed
- Monitor server resources during peak usage

### Security Testing

**Authorization Testing**
- Test access control with various user role combinations
- Verify request-level permissions enforcement
- Test administrative action authorization
- Ensure proper error handling for unauthorized access

**File Security Testing**
- Test file access authorization thoroughly
- Verify virus scanning integration
- Test file type validation edge cases
- Ensure secure file serving with temporary URLs

**Input Validation Testing**
- Test SQL injection prevention in all inputs
- Verify XSS protection in form fields
- Test file upload validation bypasses
- Ensure proper parameter filtering

**Session Security Testing**
- Test session hijacking prevention
- Verify CSRF protection on all forms
- Test concurrent session handling
- Ensure proper session cleanup

### Data Integrity Testing

**State Machine Testing**
- Test all valid state transitions
- Verify invalid transitions are blocked
- Test concurrent state changes
- Ensure audit trail accuracy

**Currency and Amount Testing**
- Test currency conversion edge cases
- Verify amount precision handling
- Test negative amount prevention
- Ensure proper decimal handling

**File Attachment Testing**
- Test attachment integrity after upload
- Verify file association accuracy
- Test orphaned file cleanup
- Ensure proper cascading deletion

### Compliance Testing

**Audit Trail Testing**
- Verify all user actions are logged
- Test audit trail query performance
- Ensure audit data immutability
- Test compliance report generation

**Data Retention Testing**
- Test request archival processes
- Verify data cleanup procedures
- Test compliance with retention policies
- Ensure secure data deletion