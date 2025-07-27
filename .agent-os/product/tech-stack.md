# Technical Stack

> Last Updated: 2025-01-27
> Version: 1.0.0

## Core Technologies

### Application Framework
- **Framework:** Ruby on Rails
- **Version:** 8.0.2
- **Language:** Ruby 3.2+

### Database
- **Primary:** PostgreSQL
- **Version:** Latest stable
- **ORM:** Active Record
- **Session Storage:** Database-backed session store

## Frontend Stack

### JavaScript Framework
- **Framework:** Hotwire (Turbo + Stimulus)
- **Version:** Latest stable via Rails integration
- **Build Tool:** Rails 8 asset pipeline (Propshaft)

### Import Strategy
- **Strategy:** Import maps (importmap-rails)
- **Package Manager:** Standard Rails asset management
- **Node Version:** Not required (Rails-native approach)

### CSS Framework
- **Framework:** TailwindCSS
- **Version:** Latest via tailwindcss-ruby and tailwindcss-rails
- **PostCSS:** Included with Tailwind Rails integration

### UI Components
- **Library:** Custom Catalyst Components + ViewComponent
- **Version:** ViewComponent ~> 3.23
- **Implementation:** Component-based architecture with dedicated design system

## Authentication & Authorization

### Authentication System
- **Primary:** NationBuilder OAuth 2.0
- **Secondary:** Email/password with bcrypt
- **Session Management:** Custom session handling with device tracking
- **Token Storage:** Rails 8 encryption (encrypts macro)

### Authorization
- **Library:** Pundit
- **Version:** ~> 2.5
- **Pattern:** Policy-based authorization with role management

## Background Processing

### Job Queue
- **Primary:** Solid Queue
- **Use Cases:** Token refresh, profile synchronization, email sending
- **Reliability:** Database-backed with retry mechanisms

### Caching
- **System:** Solid Cache
- **Storage:** Database-backed caching layer

### Real-time Features
- **System:** Solid Cable
- **Implementation:** Action Cable with database adapter

## Development & Testing

### Testing Framework
- **Primary:** RSpec
- **Integration:** rspec-rails with FactoryBot
- **System Tests:** Capybara with Selenium WebDriver
- **Mocking:** WebMock for external API testing

### Code Quality
- **Linting:** RuboCop with rails-omakase configuration
- **Security:** Brakeman static analysis
- **Style Guide:** Rails Omakase conventions

### Development Tools
- **Debugging:** debug gem, pry-rails
- **Environment:** dotenv-rails for configuration
- **Continuous Testing:** Guard-rspec for automatic test runs

## Security & Compliance

### Bot Protection
- **Provider:** Cloudflare Turnstile
- **Integration:** Custom verification service
- **Challenge Handling:** Feature-flagged challenge flows

### Data Protection
- **Encryption:** Rails 8 built-in encryption for sensitive fields
- **Session Security:** Signed cookies with IP/user agent tracking
- **Token Security:** Encrypted OAuth token storage with automatic refresh

## Infrastructure

### Application Hosting
- **Platform:** Docker containers
- **Deployment:** Kamal deployment system
- **Web Server:** Puma with Thruster for HTTP acceleration

### Database Hosting
- **Provider:** To be determined based on deployment target
- **Service:** PostgreSQL compatible hosting
- **Backups:** Standard PostgreSQL backup strategies

### Asset Storage
- **Strategy:** Self-hosted assets via Propshaft
- **CDN:** Optional based on deployment requirements
- **Performance:** Thruster for asset caching and compression

## External Integrations

### NationBuilder API
- **Integration:** Custom API client with comprehensive error handling
- **Features:** Profile sync, authentication, user management
- **Reliability:** Automatic token refresh, graceful degradation, audit logging

### Email Services
- **System:** Action Mailer
- **Provider:** Configurable SMTP (development uses Rails defaults)
- **Features:** Email verification, password reset workflows

## Development Workflow

### Version Control
- **Platform:** Git
- **Branching:** Feature branches with merge workflows
- **Repository:** GitHub integration ready

### Code Organization
- **Architecture:** Service objects for complex business logic
- **Components:** ViewComponent-based UI components
- **Policies:** Pundit policies for authorization logic
- **Background Jobs:** Dedicated job classes for async processing

### Feature Management
- **System:** Custom feature flag implementation
- **Storage:** Database-backed with user-specific assignments
- **Controls:** Admin interface for flag management