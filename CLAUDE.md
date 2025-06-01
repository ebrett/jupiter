# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Jupiter is a reimbursement and vendor payment web application built with Rails 8.0.2. The app streamlines payment requests with approval workflows and role-based access control. Currently implementing NationBuilder OAuth integration on the `feature/nationbuilder-oauth` branch.

## Development Commands

```bash
# Setup
bundle install
rails db:create db:migrate db:seed

# Development server
rails server
# or with Procfile for concurrent processes
bin/dev  # Runs web server + TailwindCSS watch

# Testing
bundle exec rspec                    # Run all tests
bundle exec rspec spec/models/       # Run specific test directory
bundle exec rspec spec/models/user_spec.rb  # Run single test file

# Code quality
bundle exec rubocop                  # Linting (rails-omakase preset)
bundle exec brakeman                 # Security scanning

# Database operations and seeding
rails db:seed                        # Creates idempotent test users (environment-aware)
rake seed:users                      # Create/update test users only
rake seed:stats                      # Show current user statistics and test credentials
rake seed:reset_users                # Remove and recreate all test users
rake seed:validate                   # Validate seed data integrity
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
- **Authentication**: NationBuilder OAuth + custom session management
- **Testing**: RSpec with FactoryBot for test data
- **Deployment**: Kamal with Docker

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
rake seed:users      # Create/update test users based on environment
rake seed:stats      # Display current user statistics and credentials
rake seed:reset_users # Clean slate - remove and recreate all test users
rake seed:validate   # Verify data integrity and user validity
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
