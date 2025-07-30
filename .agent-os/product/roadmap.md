# Product Roadmap

> Last Updated: 2025-01-27
> Version: 1.0.0
> Status: Planning

## Phase 0: Already Completed

The following core features have been implemented and are functional:

- [x] **User Authentication System** - Complete NationBuilder OAuth + email/password authentication with session management `L`
- [x] **Role-Based Access Control** - Pundit-based authorization with treasury, admin, and member roles `L`
- [x] **User Management Interface** - Admin controls for role assignment and user oversight `M`
- [x] **NationBuilder Integration** - Full OAuth flow with token refresh and profile synchronization `XL`
- [x] **Email Verification System** - Secure account verification for non-NationBuilder users `M`
- [x] **Feature Flag Management** - Admin interface with user-specific flag assignments `M`
- [x] **In-Kind Donation Forms** - Basic donation request submission and tracking `L`
- [x] **ViewComponent UI System** - Complete Catalyst design system with 20+ reusable components `XL`
- [x] **Security Infrastructure** - Cloudflare Turnstile integration with challenge flows `L`
- [x] **Background Job Processing** - Token refresh and profile sync automation `M`
- [x] **Comprehensive Testing** - RSpec test suite with 80+ test files covering models, controllers, services, and system tests `XL`

## Phase 1: Core Treasury Operations (4-6 weeks)

**Goal:** Replace Google Forms with complete reimbursement and vendor payment workflows
**Success Criteria:** Treasury staff can process requests end-to-end without Google Forms

### Must-Have Features

- [x] **Reimbursement Request System** - Complete form with receipt upload, approval workflow, and status tracking `XL`
- [x] **Vendor Payment Requests** - Structured vendor information collection with approval chains `L`
- [x] **Approval Workflow Engine** - Multi-level approval routing based on request type and amount `XL`
- [x] **Receipt/Document Management** - File upload, storage, and retrieval for supporting documentation `L`
- [x] **Request Status Dashboard** - Real-time status tracking for submitters and approvers `M`

### Should-Have Features

- [ ] **Email Notifications** - Automated notifications for status changes and approval requests `M`
- [x] **Request Search & Filtering** - Advanced search capabilities for treasury staff `S`

### Dependencies

- Active Storage configuration for file uploads
- Email service configuration for notifications

## Phase 2: Enhanced Treasury Features (3-4 weeks)

**Goal:** Add advanced features to streamline treasury operations
**Success Criteria:** 50% reduction in manual treasury processing time

### Must-Have Features

- [x] **Bulk Operations** - Batch approval and processing capabilities for treasury efficiency `L`
- [ ] **Request Categories & Budgets** - Structured categorization with budget tracking `M`
- [x] **Audit Trail Enhancement** - Detailed logging and reporting for compliance `M`
- [ ] **Advanced Role Permissions** - Country-specific permissions and delegation capabilities `L`

### Should-Have Features

- [ ] **Request Templates** - Pre-filled forms for common request types `S`
- [x] **Mobile Responsive Optimization** - Enhanced mobile experience for field submissions `M`
- [x] **Data Export Capabilities** - CSV/Excel exports for accounting integration `S`

### Dependencies

- Treasury team feedback from Phase 1 implementation
- Accounting system integration requirements

## Phase 3: Grant Management Foundation (4-5 weeks)

**Goal:** Implement basic grant application and disbursement tracking
**Success Criteria:** Country committees can submit and track grant requests

### Must-Have Features

- [ ] **Grant Application System** - Structured application forms with multi-stage approval `XL`
- [ ] **Grant Disbursement Tracking** - Payment scheduling and milestone tracking `L`
- [ ] **Country Committee Profiles** - Enhanced committee information and capabilities `M`
- [ ] **Grant Reporting Dashboard** - Overview of grant status and financial commitments `M`

### Should-Have Features

- [ ] **Grant Templates** - Pre-configured grant types with auto-populated requirements `M`
- [ ] **Milestone Management** - Progress tracking with conditional disbursements `L`

### Dependencies

- Treasury policy definitions for grant management
- Country committee onboarding process

## Phase 4: Advanced Grant Management (3-4 weeks)

**Goal:** Complete grant lifecycle management with reporting
**Success Criteria:** Full grant administration without external tools

### Must-Have Features

- [ ] **Grant Performance Tracking** - KPI monitoring and outcome reporting `L`
- [ ] **Financial Reconciliation** - Automated matching of disbursements to budgets `M`
- [ ] **Grant Compliance Monitoring** - Deadline tracking and requirement validation `M`
- [ ] **Advanced Grant Reporting** - Custom reports for treasury and executive oversight `L`

### Should-Have Features

- [ ] **Grant Analytics Dashboard** - Performance metrics and trend analysis `M`
- [ ] **Automated Compliance Alerts** - Proactive notifications for deadlines and requirements `S`

### Dependencies

- Phase 3 feedback and usage data
- Treasury reporting requirements definition

## Phase 5: Integration & Optimization (2-3 weeks)

**Goal:** Integrate with external systems and optimize performance
**Success Criteria:** Seamless workflow integration with existing DA infrastructure

### Must-Have Features

- [ ] **Accounting System Integration** - Direct export to treasury accounting tools `L`
- [ ] **Enhanced NationBuilder Sync** - Bi-directional data synchronization improvements `M`
- [ ] **Performance Optimization** - Database indexing and query optimization for scale `M`
- [ ] **Advanced Security Features** - Enhanced audit logging and security monitoring `L`

### Should-Have Features

- [ ] **API Development** - REST API for third-party integrations `L`
- [ ] **Advanced Analytics** - Usage analytics and treasury insights dashboard `M`
- [ ] **Automated Backup & Recovery** - Enhanced data protection and disaster recovery `S`

### Dependencies

- Treasury team workflow integration requirements
- External system API availability and documentation