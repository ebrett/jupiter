# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Jupiter is a reimbursement and vendor payment web application built with Rails 8.0.2. The app streamlines payment requests with approval workflows and role-based access control. Currently implementing NationBuilder OAuth integration on the `feature/nationbuilder-oauth` branch.

## Development Commands

**Important**: Always use binstubs instead of `bundle exec` for better performance and consistency.

```bash
# Setup
bundle install
bin/rails db:create db:migrate db:seed

# Development server
bin/rails server
# or with Procfile for concurrent processes
bin/dev  # Runs web server + TailwindCSS watch

# Testing
bin/rspec                            # Run all tests
bin/rspec spec/models/               # Run specific test directory
bin/rspec spec/models/user_spec.rb   # Run single test file

# Code quality
bin/rubocop                          # Linting (rails-omakase preset)
bin/brakeman                         # Security scanning

# Database operations and seeding
bin/rails db:seed                    # Creates idempotent test users (environment-aware)
bin/rake seed:users                  # Create/update test users only
bin/rake seed:stats                  # Show current user statistics and test credentials
bin/rake seed:reset_users            # Remove and recreate all test users
bin/rake seed:validate               # Validate seed data integrity

# Development Environment with tmux
bin/tmux-dev                         # Starts complete development environment
```

## Architecture Overview

### Authentication System
- Custom session-based authentication using `Authentication` concern
- NationBuilder OAuth integration via `NationbuilderAuthController`
- Token storage with Rails 8 built-in encryption (`encrypts` macro)
- Session management with signed cookies and IP/user agent tracking

### Key Models & Relationships
- `User`: Core user model with email/password + NationBuilder UID integration
- `Session`: Tracks user sessions with device information
- `NationbuilderToken`: Encrypted OAuth tokens with expiration handling

### Core Services
- `NationbuilderTokenExchangeService`: Handles OAuth code-to-token exchange with error handling
- `Oauth2Client`: Generates NationBuilder authorization URLs

### Controllers Structure
- `ApplicationController`: Base controller with authentication concerns
- `SessionsController`: Login/logout functionality
- `NationbuilderAuthController`: OAuth callback handling
- `AdminController`: Protected admin interface

## Technical Stack

- **Framework**: Rails 8.0.2 with Hotwire (Turbo + Stimulus)
- **Database**: PostgreSQL with Active Record
- **Frontend**: TailwindCSS, minimal JavaScript with Stimulus controllers
    - Use Tailwind CSS for styling components, following a utility-first approach.
    - Use Tailwind Plus Application UI elements. Provided HTML - some components require js to be added - at scripts/tailwind-ui folder
    - **ViewComponent**: Component-based architecture for reusable UI elements
- **Authentication**: NationBuilder OAuth + custom session management
- **Testing**: RSpec with FactoryBot for test data
- **Deployment**: Kamal with Docker
- **Background Jobs**: Solid Queue for async processing (token refresh, etc.)
- **Authorization**: Pundit for policy-based access control

## Environment Variables

Required for development:
```
NATIONBUILDER_CLIENT_ID
NATIONBUILDER_CLIENT_SECRET
NATIONBUILDER_REDIRECT_URI
NATIONBUILDER_NATION_SLUG
PERPLEXITY_API_KEY
```

## Rails 8 Conventions

- Uses Active Record encryption for sensitive fields
- Solid Cache/Queue/Cable for background processing
- Propshaft for asset pipeline
- Standard Rails naming conventions (snake_case)
- RuboCop with rails-omakase configuration

## Database Schema Notes

- Users table enforces email uniqueness and includes `nationbuilder_uid`
- Sessions table tracks authentication with IP addresses and user agents
- Encrypted token storage prevents plaintext OAuth credentials
- Proper PostgreSQL indexing for performance

## Test User Seeding System

The application includes a robust, idempotent seeding mechanism for creating test users:

### Environment-Aware Configuration
- **Development**: Creates all user types including edge cases (verbose output)
- **Test**: Creates admin and test users only (quiet output)
- **Production**: Creates essential admin users only (minimal output)

### Available Rake Tasks
```bash
bin/rake seed:users      # Create/update test users based on environment
bin/rake seed:stats      # Display current user statistics and credentials
bin/rake seed:reset_users # Clean slate - remove and recreate all test users
bin/rake seed:validate   # Verify data integrity and user validity
```

### Test User Categories
- **Admin Users**: `admin@example.com` (super_admin role)
- **Role-based Users**: Treasury, chapter, and standard users with various permissions
- **Edge Cases**: Long emails, unicode names, minimal data scenarios
- **QA Users**: Multi-role assignments and permission testing

All test users use password: `password123`

### Seeding Features
- **Idempotent**: Safe to run multiple times without duplicates
- **Role Management**: Automatic role assignment with validation
- **NationBuilder Integration**: Some users include mock OAuth UIDs
- **Data Validation**: Built-in integrity checks for emails and roles

## Service Architecture

The application implements a service-oriented architecture within Rails conventions:

### NationBuilder Integration Services
- **API Client Pattern**: `NationbuilderApiClient` handles authenticated requests with automatic token refresh
- **Token Management**: `NationbuilderTokenExchangeService` and `NationbuilderTokenRefreshService` manage OAuth lifecycle
- **User Synchronization**: `NationbuilderUserService` handles profile fetching and account creation
- **Monitoring & Resilience**: `NationbuilderAccessMonitor`, `NationbuilderErrorHandler`, and graceful degradation patterns

### Error Handling Strategy
- **Classified Errors**: `NationbuilderOauthErrors` provides structured error types
- **Recovery Patterns**: Automatic retry with exponential backoff
- **Audit Logging**: `NationbuilderAuditLogger` tracks all OAuth events and performance metrics
- **Graceful Degradation**: Service continues operating with reduced functionality during API failures

## Development Environment

### tmux-dev Setup
When using `bin/tmux-dev`, the development environment includes:
- **Dev Server**: Rails server + TailwindCSS watcher
- **Ngrok Tunnel**: Public HTTPS URL for testing webhooks/OAuth
- **Continuous Testing**: Guard-rspec monitors file changes and auto-runs relevant tests
- **Claude AI**: Dedicated workspace for AI-assisted development

### Continuous Testing Workflow
**Guard-rspec is running and monitoring your changes**:
- File saves trigger automatic test runs for related specs
- No need to manually run `bin/rspec` during development 
- Tests run in background - check the "tests" tmux window for results
- Focus on writing code; tests provide immediate feedback
- Only run full test suite (`bin/rspec`) before commits or for comprehensive verification

### Development Patterns

### Component Architecture
- Use ViewComponent for reusable UI elements (located in `app/components/`)
- Follow Rails 8 conventions with Hotwire for reactive interfaces
- Utilize Stimulus controllers for minimal JavaScript interactions

### PRD Workflow
- Use `.cursor/rules/create-prd.mdc` rule for structured feature development
- PRDs should be saved in `/tasks/` directory as `prd-[feature-name].md`
- Follow the clarifying questions process before implementation

### Code Quality
- RuboCop with rails-omakase preset for consistent styling
- Brakeman for security scanning
- Comprehensive test coverage with RSpec and FactoryBot

## RuboCop Guidelines

**CRITICAL**: Always run RuboCop after making code changes to maintain code quality and prevent build failures.

### Required Commands
```bash
# Always run these commands after making changes:
bin/rubocop                          # Check for style violations
bin/rubocop --autocorrect            # Auto-fix correctable violations
bin/rspec                            # Run tests to ensure functionality
```

### RuboCop Rules and Exceptions

**Auto-correctable Issues**: These should always be fixed automatically:
- `Layout/TrailingWhitespace` - Remove trailing spaces
- `Layout/TrailingEmptyLines` - Ensure single final newline
- `Layout/EmptyLinesAroundBlockBody` - Proper spacing around blocks
- `RSpec/EmptyHook` - Remove empty before/after blocks

**Acceptable Violations** (require manual review):
- `RSpec/MultipleExpectations` - Allowed in comprehensive system tests and component tests
  - System tests often need 10+ expectations to verify complex user flows
  - Component tests may need multiple expectations to verify HTML structure
  - **Guideline**: Keep under 15 expectations per test, break into smaller tests if possible

**Breaking Changes to Avoid**:
1. **Never change method signatures** without updating all callers
2. **Never remove public methods** without deprecation
3. **Never change database column types** without proper migration
4. **Never modify test helper methods** without verifying all usages
5. **Never change class names** without updating all references

### Pre-commit Checklist
Before committing code changes:
1. ✅ `bin/rubocop --autocorrect` - Fix style issues
2. ✅ `bin/rspec` - Ensure all tests pass  
3. ✅ `bin/brakeman` - Check security issues
4. ✅ Review any remaining RuboCop violations for acceptability
5. ✅ Verify no breaking changes to public APIs

### Common RuboCop Violations and Fixes

**Trailing Whitespace**:
```ruby
# Bad
def method_name  
  # code with trailing spaces
end

# Good  
def method_name
  # clean code
end
```

**Multiple Expectations in Tests**:
```ruby
# Acceptable for comprehensive tests
it "renders correct form structure for registration mode" do
  render_inline(described_class.new(mode: :register))
  
  # Multiple expectations are OK for structure verification
  expect(rendered_content).to include('<form')
  expect(rendered_content).to include('action="/users"')
  expect(rendered_content).to include('method="post"')
  # ... up to ~15 expectations for comprehensive validation
end
```

**Empty Hooks**:
```ruby
# Bad
before do
  # empty hook
end

# Good - remove empty hooks or add actual setup
before do
  @user = create(:user)
end
```

### Testing Quality Standards
- **System tests**: Focus on user workflows, multiple expectations acceptable
- **Unit tests**: Single responsibility, fewer expectations preferred  
- **Component tests**: Structure verification may require multiple expectations
- **Integration tests**: End-to-end flows, comprehensive assertions needed
