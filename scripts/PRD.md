# Reimbursement and Vendor Payment Web Application PRD

## 1. Introduction

This Product Requirements Document (PRD) outlines the specifications for a web application designed to replace the current Combined Request form and In-Kind form used for reimbursement and vendor payment requests. The application aims to streamline the request submission, approval, and payment tracking process while implementing proper role-based access control to maintain security and data integrity.

The purpose of this document is to provide a comprehensive guide for the development team, stakeholders, and testers to ensure the final product meets all business requirements and user needs. It details the functional requirements, user stories, technical specifications, and design considerations necessary for successful implementation.

## 2. Product overview

The Reimbursement and Vendor Payment Application is a web-based system that allows users to submit, track, and manage reimbursement and vendor payment requests. It replaces the current manual forms with a more efficient digital solution that provides real-time status updates and a streamlined approval workflow.

The application will support various user roles with different permission levels, from submitters who create requests to administrators who manage the entire system. It will capture all required information from the existing forms while adding enhanced tracking and reporting capabilities to improve financial oversight.

This system will be built using Python, Flask, and PostgreSQL, with role-based access control to ensure secure access to sensitive financial information. The application will operate independently from the wiki, making it more accessible to users while maintaining proper authentication requirements.

Authentication will be implemented using OAuth integration with Nationbuilder API, providing single sign-on capabilities and leveraging existing user data to inform authorization requirements.

## 3. Goals and objectives

### Primary goals
- Replace the current Combined Request form and In-Kind form with a unified digital solution
- Streamline the reimbursement and vendor payment request process
- Implement appropriate access controls for different user roles
- Provide real-time status tracking of payment requests
- Improve financial oversight and reporting capabilities
- Integrate with Nationbuilder for authentication and user permissions
- Reduce duplicate user management through Nationbuilder integration

### Success metrics
- Reduced processing time for reimbursement and vendor payment requests
- Increased transparency in request status for all stakeholders
- Improved data accuracy through standardized form submission
- Enhanced reporting capabilities for financial oversight
- Decreased administrative burden on Treasury team
- User satisfaction with the new system (measured through feedback)
- Successful authentication rate through Nationbuilder
- Reduced manual user permission management

## 4. Target audience

The application will serve multiple user categories, each with specific needs and permissions:

1. **Submitters**: Regular users who need to request reimbursements or vendor payments. They require an intuitive interface to create, save, and submit requests, as well as track the status of their submissions.

2. **Country/Chapter admins**: Regional administrators who approve requests for their specific geographic area. They need visibility into all requests from their region and the ability to approve or deny submissions.

3. **Treasury Team admins**: Financial administrators who process payments and manage the overall financial system. They require comprehensive access to all requests and the ability to modify request content and status.

4. **Super Admins**: System administrators who manage user accounts and access rights. They need tools to add, modify, and remove users and their permissions.

5. **Viewers**: Stakeholders who need visibility into the request system without modification rights, such as FEC Consultants and Global ExComm members.

6. **Treasury IT**: Technical staff responsible for maintaining and modifying the application code and database.

User roles and permissions will be partially derived from Nationbuilder user data, reducing manual role assignment and ensuring consistency across systems.

## 5. Features and requirements

### 5.1 User authentication and management

- OAuth integration with Nationbuilder for authentication
- Single sign-on capability for users with existing Nationbuilder accounts
- Role mapping between Nationbuilder permissions and application roles
- User profile data synchronization with Nationbuilder
- Supplemental user registration for fields not available in Nationbuilder
- Role-based access control with six distinct roles
- User management interface for Super Admins with visibility into Nationbuilder-sourced data
- Fallback authentication method for system administrators

### 5.2 Request creation and management

- New request creation interface with all fields from current forms
- Draft saving functionality for works in progress
- Request submission workflow
- Request cancellation capability (pre-submission)
- Request status tracking through multiple stages
- Field editability based on user role and request status
- Comprehensive form fields supporting all current form data
- Auto-population of user information from Nationbuilder data where applicable

### 5.3 Request approval and processing

- Notification system for Country/Chapter admins
- Approval/denial interface for Country/Chapter admins
- Treasury processing workflow
- Payment status tracking
- Additional fields for payment metadata

### 5.4 Viewing and reporting

- Request listing with sorting and filtering capabilities
- Detailed request view based on user permissions
- Summary overview for Treasury
- Status-based filtering

### 5.5 System administration

- User management interface with Nationbuilder data integration
- Role assignment capabilities with Nationbuilder role mapping
- System configuration options for Nationbuilder integration settings
- Configuration for role mapping between systems

## 6. User stories and acceptance criteria

### Submitter user stories

#### ST-101: User authentication with Nationbuilder
**As a** user with a Nationbuilder account,  
**I want to** log in to the application using my Nationbuilder credentials,  
**So that** I don't need to maintain separate login information.

**Acceptance Criteria:**
- User can access application login page
- Login page offers "Sign in with Nationbuilder" option
- User is redirected to Nationbuilder for authentication
- Upon successful authentication, user is returned to the application
- Application creates/updates local user record with necessary Nationbuilder data
- User is logged in with appropriate permissions based on Nationbuilder role mapping
- Session management respects security best practices

#### ST-102: Request creation
**As a** submitter,  
**I want to** create a new reimbursement or vendor payment request,  
**So that** I can be reimbursed for expenses or pay vendors.

**Acceptance Criteria:**
- User can access a "New Request" button from the main dashboard
- System presents a form with all required fields
- Form includes all fields from the current Combined Request and In-Kind forms
- User can save the form as a draft before submission
- System validates all required fields before final submission
- User receives confirmation when request is successfully submitted
- Submitted request appears in the user's request list with appropriate status
- User profile information from Nationbuilder is pre-populated where applicable

#### ST-103: Draft request management
**As a** submitter,  
**I want to** save draft requests and return to them later,  
**So that** I can complete complex requests over multiple sessions.

**Acceptance Criteria:**
- User can save a request in "In preparation" status
- System saves all entered data when draft is saved
- User can see all draft requests in their request list
- User can open and continue editing draft requests
- User can submit a completed draft request
- User can cancel a draft request

#### ST-104: Request tracking
**As a** submitter,  
**I want to** view the status of my submitted requests,  
**So that** I know when they are approved and paid.

**Acceptance Criteria:**
- User can see a list of all their submitted requests
- List displays key information including request date, vendor, amount, and status
- User can sort and filter their request list
- User can click on a request to view complete details
- Status updates are reflected in real-time
- User cannot edit requests after submission

### Country/Chapter admin user stories

#### ST-201: Request approval
**As a** country/chapter admin,  
**I want to** review and approve/deny requests for my region,  
**So that** only valid expenses are processed.

**Acceptance Criteria:**
- Admin receives notification when new requests are submitted for their region
- Admin can see a list of all requests for their country/chapter
- Admin can view complete details of each request
- Admin can approve or deny requests with comments
- Status changes are immediately reflected in the system
- Approved requests are made available to Treasury for processing

#### ST-202: Regional request oversight
**As a** country/chapter admin,  
**I want to** see all requests from my region,  
**So that** I can monitor financial activities.

**Acceptance Criteria:**
- Admin can access a dashboard showing all requests for their region
- Dashboard provides filtering by status, date, and requester
- Admin can view detailed information for each request
- System provides basic reporting capabilities for regional requests
- Admin cannot see requests from other regions
- Admin permissions are correctly mapped from Nationbuilder regional roles

### Treasury Team admin user stories

#### ST-301: Payment processing
**As a** treasury team admin,  
**I want to** process approved payment requests,  
**So that** submitters and vendors receive their payments.

**Acceptance Criteria:**
- Admin can see a list of all approved requests pending payment
- Admin can update payment status and add payment details
- Admin can record when a payment is posted to QuickBooks
- Admin can record payment processor information
- Admin can add notes to the payment record
- System tracks all status changes with timestamps and user information

#### ST-302: Request modification
**As a** treasury team admin,  
**I want to** modify request details when necessary,  
**So that** incorrect information can be corrected.

**Acceptance Criteria:**
- Admin can edit all fields in any request regardless of status
- System logs all changes made by admins
- Original submitter can see that changes were made and by whom
- Admin can add internal notes not visible to submitters

#### ST-303: Financial overview
**As a** treasury team admin,  
**I want to** see a comprehensive overview of all requests,  
**So that** I can manage financial operations effectively.

**Acceptance Criteria:**
- Admin can access a summary page showing all requests in the system
- Page includes filtering and sorting capabilities
- Page displays key metrics like total requests, amounts by status, etc.
- Admin can export summary data for external analysis
- View is similar to current Google Sheets used by Treasury

### Super Admin user stories

#### ST-401: User management with Nationbuilder integration
**As a** super admin,  
**I want to** manage user accounts with Nationbuilder integration,  
**So that** appropriate access controls are maintained with minimal duplication.

**Acceptance Criteria:**
- Admin can view a list of all users in the system
- List displays which users are authenticated via Nationbuilder
- Admin can view Nationbuilder roles for integrated users
- Admin can map Nationbuilder roles to application roles
- Admin can override role mappings for specific users
- Admin can create supplementary user accounts not in Nationbuilder
- Admin can deactivate user accounts
- System logs all user management actions

#### ST-402: Nationbuilder integration configuration
**As a** super admin,  
**I want to** configure Nationbuilder integration settings,  
**So that** authentication and role mapping work correctly.

**Acceptance Criteria:**
- Admin can access Nationbuilder integration configuration page
- Admin can configure OAuth client settings
- Admin can map Nationbuilder roles/tags to application roles
- Admin can test integration settings
- Admin can enable/disable Nationbuilder integration
- Changes to integration settings are logged

### Viewer user stories

#### ST-501: Request viewing
**As a** viewer,  
**I want to** see request information without editing capabilities,  
**So that** I can monitor financial activities in the organization.

**Acceptance Criteria:**
- Viewer can see a list of all requests in the system
- Viewer can view complete details of each request
- Viewer cannot modify any request information
- Viewer cannot approve or deny requests
- System prevents any modification attempts
- Viewer permissions are correctly mapped from appropriate Nationbuilder roles

### Treasury IT user stories

#### ST-601: System maintenance
**As a** treasury IT staff,  
**I want to** access the application code and database,  
**So that** I can perform maintenance and updates.

**Acceptance Criteria:**
- IT staff has access to application code repository
- IT staff has administrative access to the production database
- System architecture documentation is available
- Deployment procedures are documented
- Database schema is documented
- Nationbuilder integration architecture is documented

### Authentication user stories

#### ST-701: Nationbuilder OAuth authentication
**As a** system user,  
**I want to** authenticate using my Nationbuilder account,  
**So that** I can access the application without maintaining separate credentials.

**Acceptance Criteria:**
- User can select "Login with Nationbuilder" option
- User is redirected to Nationbuilder authentication page
- After successful authentication, user is redirected back to application
- Application retrieves and stores necessary user information from Nationbuilder
- Application assigns appropriate roles based on Nationbuilder data
- User session is created with appropriate timeout settings
- All authentication attempts are logged

#### ST-702: Fallback authentication
**As a** system administrator,  
**I want to** have a fallback authentication method,  
**So that** I can access the system if Nationbuilder integration is unavailable.

**Acceptance Criteria:**
- System maintains local authentication for administrator accounts
- Admin can log in with local credentials if Nationbuilder is unavailable
- Fallback authentication is properly secured
- Fallback authentication is logged and monitored
- Only administrative accounts have fallback authentication capability

#### ST-703: User profile synchronization
**As a** system user,  
**I want to** have my profile information synchronized with Nationbuilder,  
**So that** I don't need to maintain duplicate information.

**Acceptance Criteria:**
- User profile data is updated from Nationbuilder upon login
- Application stores only necessary user data locally
- User can view which information comes from Nationbuilder
- Changes to profile in Nationbuilder are reflected in application on next login
- System handles conflicts between local and Nationbuilder data appropriately

### Database modeling user stories

#### ST-801: Data storage
**As a** system designer,  
**I want to** create an efficient database schema,  
**So that** all request and user data is properly stored and related.

**Acceptance Criteria:**
- Database schema includes tables for users, roles, requests, and statuses
- Schema supports all fields from current forms
- Relationships between tables are properly defined
- Database enforces data integrity constraints
- Schema supports efficient querying for all required views
- User credentials are stored securely in a separate database
- Schema includes audit trails for data modifications
- Schema supports Nationbuilder user integration with appropriate identifiers

#### ST-802: Nationbuilder data integration
**As a** system designer,  
**I want to** integrate Nationbuilder user data with application data,  
**So that** user information and permissions are consistent across systems.

**Acceptance Criteria:**
- Database schema includes fields for Nationbuilder user IDs and role mappings
- System maintains mapping between Nationbuilder roles/tags and application roles
- Database supports efficient queries for user permissions
- Schema handles cases where users exist in application but not in Nationbuilder
- Schema includes audit trail for permission changes

## 7. Technical requirements / stack

### Technology stack
- **Backend**: Rails 8, Hotwire, Stimulus, TailwindCSS
- **Database**: PostgreSQL
- **Authentication**: 
  - Primary: OAuth 2.0 integration with Nationbuilder API
  - Secondary: Local authentication for administrative fallback
- **Authorization**: Role-Based Access Control (RBAC) with Nationbuilder role mapping
- **Frontend**: HTML, CSS, JavaScript (specific framework to be determined)
- **Deployment**: To be determined based on organizational infrastructure

### Nationbuilder integration requirements
- OAuth 2.0 implementation for authentication
- API integration for user data retrieval
- Secure storage of OAuth tokens
- Regular synchronization of user data
- Configurable mapping between Nationbuilder roles/tags and application roles
- Error handling for Nationbuilder API unavailability
- Logging of all Nationbuilder API interactions

### Security requirements
- Secure OAuth implementation following best practices
- Protection of OAuth client secrets and tokens
- Session management with appropriate timeouts
- Role-based access control
- Secure handling of financial data
- Protection against common web vulnerabilities (OWASP Top 10)
- Regular security audits and updates

### Performance requirements
- Application should support multiple concurrent users
- Page load times should be under 2 seconds
- Database queries should be optimized for efficiency
- Nationbuilder API calls should be cached appropriately
- System should be scalable to accommodate growing number of requests

### Integration requirements
- Nationbuilder API integration for authentication and user data
- Potential future integration with QuickBooks (not in initial scope)
- Potential future integration with payment processors (not in initial scope)

### Maintenance requirements
- Code should be well-documented for future maintenance
- System should include logging for troubleshooting
- Database backups should be regularly scheduled
- Monitoring for Nationbuilder API availability and performance

## 8. Design and user interface

### General UI principles
- Clean, intuitive interface focused on task completion
- Responsive design for use on various devices
- Consistent navigation and action patterns
- Clear feedback for user actions
- Accessibility compliance

### Key screens

1. **Login/Authentication**
   - Prominently displayed "Sign in with Nationbuilder" button
   - Clear visual indication of Nationbuilder integration
   - Fallback login form for administrative users
   - Error messaging for authentication failures

2. **Dashboard**
   - Overview of user's requests (or all visible requests for admins)
   - Quick stats relevant to user role
   - Clear navigation to main functions
   - Action buttons appropriate to user role
   - User profile information with indication of Nationbuilder-sourced data

3. **Request List**
   - Sortable, filterable list of requests
   - Key information displayed in columns
   - Status indicators with clear visual differentiation
   - Action buttons based on user role and request status

4. **Request Creation/Viewing**
   - Form with all required fields from current paper forms
   - Logical grouping of related fields
   - Pre-population of user information from Nationbuilder where applicable
   - Clear save, submit, and cancel actions
   - Status information prominently displayed
   - Edit controls based on user permissions

5. **Admin Panels**
   - User management interface for Super Admins with Nationbuilder integration
   - Role mapping configuration for Nationbuilder integration
   - Approval interface for Country/Chapter admins
   - Payment processing interface for Treasury Team admins

### Navigation structure
- Persistent top navigation bar with key functions
- Breadcrumb navigation for multi-level processes
- Clearly labeled action buttons
- Consistent placement of common actions
- User profile/account access with visible Nationbuilder connection

### Visual design considerations
- Use of organizational color scheme and branding
- Clear typography with good readability
- Visual indicators for request status
- Appropriate use of icons for common actions
- Visual indication of Nationbuilder integration where relevant
- Minimalist design that focuses on content

### Interaction design
- Inline validation for form fields
- Progressive disclosure for complex forms
- Confirmation dialogs for important actions
- Clear error messages with resolution guidance
- Status updates without page refresh when possible
- Smooth handling of authentication redirects