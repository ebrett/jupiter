# Technical Specification

This is the technical specification for the spec detailed in @.agent-os/specs/2025-07-29-reimbursement-request-system/spec.md

> Created: 2025-07-29
> Version: 1.0.0

## Technical Requirements

### Data Model Requirements
- **ReimbursementRequest model** with fields for amount, currency, description, expense_date, category, status, and user associations
- **File attachment associations** using Active Storage for receipt uploads with virus scanning
- **Approval workflow tracking** with state machine for status transitions (draft, submitted, under_review, approved, rejected, paid)
- **Audit trail logging** for all state changes and admin actions
- **Email notification triggers** for status changes and workflow events

### File Upload Requirements
- **Supported formats**: PDF, JPG, JPEG, PNG files up to 10MB each
- **Security**: Virus scanning and content type validation
- **Storage**: Active Storage with secure direct uploads
- **Access control**: Only request owner and treasury staff can access uploaded files
- **Preview capabilities**: Display uploaded images in admin review interface

### User Interface Requirements
- **Member submission form** with Catalyst components following existing design system
- **Treasury admin dashboard** with request listing, filtering, and bulk actions
- **Request detail views** with file preview, approval history, and status timeline
- **Responsive design** optimized for desktop and tablet use
- **Real-time status updates** using Hotwire Turbo for live refresh

### Authorization Requirements
- **Member permissions**: Can create and view own requests only
- **Treasury permissions**: Can view, approve/reject all requests in their jurisdiction
- **Admin permissions**: Full access to all requests and system configuration
- **Country-specific access**: Requests scoped to appropriate committee jurisdictions

### Performance Requirements
- **Form submission**: Under 2 seconds for requests without file uploads
- **File upload**: Progress indication and direct upload to prevent timeouts
- **Dashboard loading**: Under 1 second for standard request listings
- **Search performance**: Sub-second response for filtered request queries

## Approach Options

**Option A: Simple Enum with Timestamps (Selected)**
- Pros: Rails-native approach, easy to implement, straightforward state management, no external dependencies
- Cons: Manual state transition validation, requires separate audit trail implementation

**Option B: State Machine with AASM**
- Pros: Robust state management, clear workflow definitions, built-in audit trail
- Cons: Additional gem dependency, slightly more complex implementation, external dependency overhead

**Option C: Event Sourcing with Eventide**
- Pros: Complete audit trail, time travel capabilities, microservices-ready
- Cons: Significant architectural complexity, steep learning curve, infrastructure overhead

**Rationale:** Simple enum with timestamps provides the perfect balance for an MVP, using Rails conventions while maintaining audit capabilities through a separate events table. This approach eliminates external dependencies while providing clear state management and room for future enhancement.

## External Dependencies

- **image_processing gem** - Image resizing and optimization for receipt previews
  - **Justification:** Already included with Rails 8 Active Storage, needed for generating receipt thumbnails in admin interface

- **active_storage_validations gem** - Enhanced file upload validation
  - **Justification:** Provides content type, size, and dimension validations beyond Rails defaults for security

## Integration Points

### Active Storage Configuration
- Configure direct uploads for better user experience
- Set up virus scanning using built-in Active Storage analyzers
- Implement secure URL generation with expiring tokens

### Pundit Policy Integration
- Extend existing user roles to include reimbursement-specific permissions
- Implement request-level authorization with country committee scoping
- Add treasury-specific actions (approve, reject, mark_paid)

### Email Notification Integration
- Leverage existing Action Mailer configuration
- Create reimbursement-specific email templates using existing component system
- Integrate with Solid Queue for reliable email delivery

### Hotwire Integration
- Use Turbo Streams for real-time status updates
- Implement Stimulus controllers for file upload progress and form enhancements
- Leverage existing Catalyst components for consistent UI patterns

## Security Considerations

### File Upload Security
- Content type validation to prevent malicious file uploads
- File size limits to prevent storage abuse
- Virus scanning on upload using Active Storage analyzers
- Secure direct upload URLs with short expiration times

### Access Control
- Request-level authorization ensuring users can only access appropriate requests
- Treasury staff limited to their committee jurisdiction
- Admin-only access to sensitive financial data and system configuration
- Audit logging for all access and modification events

### Data Protection
- PII encryption for sensitive financial information
- Secure file storage with access controls
- Compliance with political organization data handling requirements
- Regular cleanup of temporary upload files and expired access tokens