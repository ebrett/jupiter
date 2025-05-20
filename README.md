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
   rails db:create db:migrate db:seed
   ```

5. Start the server
   ```bash
   rails server
   ```

6. Visit http://localhost:3000 in your browser

### Running Tests

```bash
bundle exec rspec
```

### Linting

```bash
bundle exec rubocop
```

## Development Setup

1. Install dependencies:
   ```sh
   bundle install
   ```
2. Set up environment variables:
   - Copy `.env.example` to `.env` and fill in values as needed.
3. Set up the database:
   ```sh
   rails db:create db:migrate db:seed
   ```
4. Run the test suite:
   ```sh
   bundle exec rspec
   ```
5. Run the linter:
   ```sh
   bundle exec rubocop
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
