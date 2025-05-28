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

# Database operations
rails db:seed    # Creates idempotent test users
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