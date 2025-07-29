# API Specification

This is the API specification for the spec detailed in @.agent-os/specs/2025-07-29-reimbursement-request-system/spec.md

> Created: 2025-07-29
> Version: 1.0.0

## Routes

### Member Routes
Routes accessible to authenticated members for managing their own reimbursement requests.

#### GET /reimbursement_requests
**Purpose:** Display member's reimbursement requests dashboard
**Parameters:** 
- `status` (optional): Filter by request status
- `page` (optional): Pagination parameter
**Response:** HTML page with request listing and status overview
**Authorization:** Authenticated members see only their own requests

#### GET /reimbursement_requests/new
**Purpose:** Display new reimbursement request form
**Parameters:** None
**Response:** HTML form with Catalyst components for request creation
**Authorization:** Authenticated members only

#### POST /reimbursement_requests
**Purpose:** Create new reimbursement request
**Parameters:**
```ruby
{
  reimbursement_request: {
    title: "Conference Travel Expenses",
    description: "Flight and accommodation for DA conference",
    amount_cents: 45000,
    currency: "USD",
    expense_date: "2025-07-15",
    category: "travel",
    receipts: [file_upload_objects]
  }
}
```
**Response:** Redirect to request show page or form with errors
**Authorization:** Authenticated members only

#### GET /reimbursement_requests/:id
**Purpose:** Display specific reimbursement request details
**Parameters:** 
- `id`: Request ID
**Response:** HTML page with request details, status, and uploaded receipts
**Authorization:** Request owner or treasury staff only

#### PATCH /reimbursement_requests/:id
**Purpose:** Update draft reimbursement request
**Parameters:** Same as POST, limited to draft requests
**Response:** Updated request page or form with errors
**Authorization:** Request owner, draft status only

#### DELETE /reimbursement_requests/:id
**Purpose:** Delete draft reimbursement request
**Parameters:** 
- `id`: Request ID
**Response:** Redirect to requests index
**Authorization:** Request owner, draft status only

### Treasury Admin Routes
Routes for treasury staff to manage and approve reimbursement requests.

#### GET /admin/reimbursement_requests
**Purpose:** Treasury dashboard with all pending requests
**Parameters:**
- `status` (optional): Filter by approval status
- `category` (optional): Filter by expense category
- `user_id` (optional): Filter by requesting user
- `date_range` (optional): Filter by submission date
**Response:** HTML admin dashboard with advanced filtering and bulk actions
**Authorization:** Treasury role or higher

#### GET /admin/reimbursement_requests/:id
**Purpose:** Detailed admin view for request review
**Parameters:** 
- `id`: Request ID
**Response:** HTML page with full request details, receipt previews, and approval actions
**Authorization:** Treasury role or higher

#### PATCH /admin/reimbursement_requests/:id/approve
**Purpose:** Approve reimbursement request
**Parameters:**
```ruby
{
  approved_amount_cents: 45000,
  approval_notes: "Approved as submitted, valid conference expense"
}
```
**Response:** Turbo stream update with new status or error message
**Authorization:** Treasury role or higher

#### PATCH /admin/reimbursement_requests/:id/reject
**Purpose:** Reject reimbursement request
**Parameters:**
```ruby
{
  rejection_reason: "Missing required receipts for accommodation"
}
```
**Response:** Turbo stream update with rejection status
**Authorization:** Treasury role or higher

#### PATCH /admin/reimbursement_requests/:id/request_info
**Purpose:** Request additional information from member
**Parameters:**
```ruby
{
  info_request: "Please provide itemized hotel bill"
}
```
**Response:** Turbo stream update and email notification to member
**Authorization:** Treasury role or higher

#### PATCH /admin/reimbursement_requests/:id/mark_paid
**Purpose:** Mark approved request as paid
**Parameters:**
```ruby
{
  payment_reference: "CHECK-2025-001234",
  paid_date: "2025-07-29"
}
```
**Response:** Turbo stream update with paid status
**Authorization:** Treasury role or higher

### File Management Routes
Secure routes for receipt and document management.

#### GET /reimbursement_requests/:id/receipts/:receipt_id
**Purpose:** Serve receipt file with authorization
**Parameters:** 
- `id`: Request ID
- `receipt_id`: Active Storage attachment ID
**Response:** File content with appropriate content-type headers
**Authorization:** Request owner or treasury staff only

#### DELETE /reimbursement_requests/:id/receipts/:receipt_id
**Purpose:** Remove receipt from draft request
**Parameters:** 
- `id`: Request ID
- `receipt_id`: Active Storage attachment ID
**Response:** Turbo stream update removing receipt from form
**Authorization:** Request owner, draft requests only

## Controllers

### ReimbursementRequestsController
Handles member-facing CRUD operations for reimbursement requests.

**Actions:**
- `index` - Member dashboard with personal requests
- `show` - Individual request details with status timeline
- `new` - Request creation form with file upload
- `create` - Process new request submission with validation
- `edit` - Edit form for draft requests only
- `update` - Update draft requests with new information
- `destroy` - Delete draft requests

**Business Logic:**
- Request number generation using timestamp-based unique IDs
- File upload validation and virus scanning
- Status transition validation (only drafts can be edited)
- Email notification triggers for submission events
- Authorization scoping to user's own requests

**Error Handling:**
- Form validation errors with field-specific messages
- File upload errors with size and type restrictions
- Authorization errors with appropriate redirects
- State transition errors for invalid operations

### Admin::ReimbursementRequestsController
Treasury-specific admin interface for request management and approval.

**Actions:**
- `index` - Admin dashboard with filtering and search
- `show` - Detailed admin view with approval actions
- `approve` - Approve request with optional amount adjustment
- `reject` - Reject request with required reason
- `request_info` - Request additional information
- `mark_paid` - Update payment status

**Business Logic:**
- Multi-level approval routing based on amount thresholds
- Audit trail logging for all administrative actions
- Email notification automation for status changes
- Bulk action processing for multiple requests
- Advanced filtering and search capabilities

**Error Handling:**
- Approval validation with business rule enforcement
- Concurrent editing detection and resolution
- File access errors with fallback handling
- State machine validation with informative error messages

### ReceiptsController
Dedicated controller for secure file serving and management.

**Actions:**
- `show` - Serve receipt files with authorization
- `destroy` - Remove receipts from draft requests
- `preview` - Generate receipt thumbnails and previews

**Business Logic:**
- Secure file serving with temporary signed URLs
- Content type validation and virus scanning
- Image resizing and thumbnail generation
- Access logging for audit requirements

**Error Handling:**
- File not found errors with appropriate HTTP status
- Authorization failures with security logging
- File corruption detection and error reporting
- Storage service errors with graceful degradation

## Integration Points

### Pundit Authorization Integration
All controllers use Pundit policies for request-level authorization:
- `ReimbursementRequestPolicy` - Controls member access to own requests
- `Admin::ReimbursementRequestPolicy` - Controls treasury access with jurisdictional scoping
- `ReceiptPolicy` - Controls file access with ownership validation

### Action Mailer Integration
Email notifications triggered by controller actions:
- Request submission confirmation to member
- Approval request notification to treasury staff
- Status change notifications to all stakeholders
- Payment confirmation to requesting member

### Hotwire Integration
Real-time updates using Turbo Streams:
- Status changes broadcast to all connected users
- Dashboard updates without page refresh
- Form submission with inline error handling
- File upload progress indication

### Background Job Integration
Async processing for non-critical operations:
- Email sending via Solid Queue
- File processing and thumbnail generation
- Audit log cleanup and maintenance
- Notification batching for efficiency

## Security Considerations

### Request Authorization
- Members can only access their own requests
- Treasury staff limited to appropriate jurisdictional scope
- Admin users have full system access with audit logging
- File access restricted to authorized users only

### Input Validation
- Strong parameters for all request attributes
- File upload validation with size and type restrictions
- Currency and amount validation with business rules
- XSS prevention through proper output encoding

### Audit Trail
- All state changes logged with user attribution
- File access logging for security monitoring
- Failed authorization attempts recorded
- Administrative actions tracked for compliance

### Rate Limiting
- Request submission rate limiting to prevent abuse
- File upload throttling for resource protection
- Admin action rate limiting for security
- IP-based blocking for suspicious activity