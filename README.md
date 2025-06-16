# Jupiter: Reimbursement and Vendor Payment Web Application

## Overview

Jupiter is a comprehensive web application designed to streamline and manage the reimbursement and vendor payment processes. The application provides a structured workflow for payment requests, from creation through approval to final processing, with role-based access control ensuring proper authorization throughout the process.

This system enables organizations to efficiently handle financial requests, maintain proper approval hierarchies, and track payment statuses in real-time.

## Features

### Core Functionality
- **Request Creation System**: Create, save drafts, and submit payment/reimbursement requests
- **Approval Workflow**: Multi-step approval process with real-time updates via Hotwire
- **Payment Processing**: Track payment statuses and prepare for future QuickBooks integration
- **Reporting and Analytics**: Generate reports and analyze payment data with filtering and sorting capabilities

### User Management
- **Nationbuilder OAuth Integration**: Single sign-on authentication system
- **Role-Based Access Control**: Six distinct user roles with appropriate permissions:
  - Submitter
  - Country/Chapter Admin
  - Treasury Team Admin
  - Super Admin
  - Viewer
  - Treasury IT

### Administrative Tools
- **Admin Dashboard**: Comprehensive interface for user management and system configuration
- **User Management**: Add, update, and manage user accounts and roles
- **System Configuration**: Customize application settings and workflow parameters

## Technical Stack

- **Framework**: Rails 8
- **Database**: PostgreSQL
- **Frontend**: 
  - Hotwire (Turbo and Stimulus) for dynamic interactions
  - TailwindCSS for styling
- **Authentication**: OAuth integration with Nationbuilder
- **Testing**: RSpec, Factory Bot
- **CI/CD**: GitHub Actions
- **Development Tools**: 
  - RuboCop for code linting
  - Brakeman for security scanning
  - Docker for development environment (optional)

## Setup Instructions

### Prerequisites
- Ruby 3.2+ (see `.ruby-version` file for exact version)
- PostgreSQL 14+
- Node.js 18+ and Yarn
- Redis (for ActionCable in development)

### Installation

1. Clone the repository
   ```bash
   git clone https://github.com/your-organization/jupiter.git
   cd jupiter
   ```

2. Install dependencies
   ```bash
   bundle install
   yarn install
   ```

3. Setup environment variables
   ```bash
   cp .env.example .env
   # Edit .env with your local configuration
   ```

4. Setup database
   ```bash
   bin/rails db:create db:migrate db:seed
   ```

5. Start the server
   ```bash
   bin/rails server
   ```

6. Visit http://localhost:3000 in your browser

### Seed Test Data

The application provides a set of test users for development and QA purposes. These users are created automatically when you run:

```bash
bin/rails db:seed
```

The seeding process is idempotent—running it multiple times will not create duplicate users.

**Test User Credentials:**

| Email                | Password      |
|----------------------|--------------|
| admin@example.com    | password123  |
| user1@example.com    | password123  |
| user2@example.com    | password123  |
| qa@example.com       | password123  |
| guest@example.com    | password123  |

You can use these accounts to log in and test different user scenarios in the development environment.

### Running Tests

```bash
bin/rspec
```

### Linting

```bash
bin/rubocop
```

### OAuth Authentication Testing

**Important**: NationBuilder OAuth authentication functionality requires manual testing in a staging environment with real NationBuilder credentials. The automated test suite covers all business logic and error handling but excludes actual OAuth API interactions.

To test OAuth functionality:

1. **Set up staging environment** with proper NationBuilder OAuth credentials
2. **Configure environment variables**:
   ```bash
   NATIONBUILDER_CLIENT_ID=your_client_id
   NATIONBUILDER_CLIENT_SECRET=your_client_secret
   NATIONBUILDER_REDIRECT_URI=https://your-staging-domain.com/auth/nationbuilder/callback
   NATIONBUILDER_NATION_SLUG=your_nation_slug
   ```
3. **Test the OAuth flow manually**:
   - Visit `/auth/nationbuilder` to initiate OAuth
   - Complete authorization on NationBuilder's consent screen
   - Verify successful callback and token storage
   - Test admin dashboard OAuth status page
   - Verify token refresh functionality

The application includes comprehensive error handling and graceful degradation for OAuth failures.

## Deployment

### Fly.io Deployment

The application is configured for deployment on Fly.io. Follow these steps to deploy:

1. **Install Fly CLI**:
   ```bash
   curl -L https://fly.io/install.sh | sh
   ```

2. **Authenticate with Fly**:
   ```bash
   fly auth login
   ```

3. **Deploy the application**:
   ```bash
   fly deploy
   ```

### Connecting NationBuilder to Your Fly Deployment

To enable NationBuilder OAuth authentication on your Fly deployment:

1. **Register your application with NationBuilder**:
   - Log in to your NationBuilder nation's control panel
   - Navigate to Settings → Developer → OAuth Applications
   - Click "Register a new application"
   - Fill in the application details:
     - **Name**: Jupiter (or your preferred name)
     - **Redirect URI**: `https://your-app-name.fly.dev/auth/nationbuilder/callback`
     - Save the application

2. **Note your OAuth credentials**:
   - **Client ID**: Displayed after registration
   - **Client Secret**: Displayed after registration
   - **Nation Slug**: Your NationBuilder nation's subdomain (e.g., `yournation` from `yournation.nationbuilder.com`)

3. **Set Fly.io secrets**:
   ```bash
   fly secrets set NATIONBUILDER_CLIENT_ID="your_client_id"
   fly secrets set NATIONBUILDER_CLIENT_SECRET="your_client_secret"
   fly secrets set NATIONBUILDER_REDIRECT_URI="https://your-app-name.fly.dev/auth/nationbuilder/callback"
   fly secrets set NATIONBUILDER_NATION_SLUG="your_nation_slug"
   ```

4. **Set additional required secrets**:
   ```bash
   # Generate a secure secret key base
   fly secrets set SECRET_KEY_BASE="$(openssl rand -hex 64)"
   
   # Set Rails master key (from config/master.key)
   fly secrets set RAILS_MASTER_KEY="your_master_key_content"
   ```

5. **Deploy with the new configuration**:
   ```bash
   fly deploy
   ```

6. **Verify the integration**:
   - Visit `https://your-app-name.fly.dev`
   - Click "Sign in with NationBuilder"
   - You should be redirected to NationBuilder's authorization page
   - After authorizing, you'll be redirected back to your Jupiter app

### Troubleshooting Deployment

- **Check logs**: `fly logs`
- **SSH into container**: `fly ssh console`
- **Check secrets**: `fly secrets list`
- **Database issues**: Ensure `DATABASE_URL` is properly set by Fly
- **OAuth errors**: Verify redirect URI matches exactly between NationBuilder and your Fly secrets

## Development Setup

1. Install dependencies:
   ```sh
   bundle install
   ```
2. Set up environment variables:
   - Copy `.env.example` to `.env` and fill in values as needed.
3. Set up the database:
   ```sh
   bin/rails db:create db:migrate db:seed
   ```
4. Run the test suite:
   ```sh
   bin/rspec
   ```
5. Run the linter:
   ```sh
   bin/rubocop
   ```

## Environment Variables

See `.env.example` for required variables.

## Docker (Optional)

- To use Docker for development, ensure Docker is installed and run:
  ```sh
  docker-compose up --build
  ```
- See `Dockerfile` and `docker-compose.yml` for configuration.

## Continuous Integration

- CI is configured via GitHub Actions in `.github/workflows/ci.yml`.
- The pipeline runs tests and linting on each push and pull request.

## Contributing

Please see the [CONTRIBUTING.md](CONTRIBUTING.md) file for details on how to contribute to this project.

## License

This project is proprietary software. All rights reserved.
