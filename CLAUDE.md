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

## Development Patterns

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
