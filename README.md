# Jupiter: Treasury Forms and Payment Management

Jupiter is a Rails web application for managing financial requests and payments, featuring NationBuilder OAuth integration, role-based access control, and a flexible forms system.

## Features

- **Forms System**: In-kind donations, reimbursement requests, and vendor payments
- **NationBuilder OAuth**: Single sign-on authentication with automatic user sync
- **Role-Based Access**: Submitter, admin, viewer, and treasury roles
- **CSV Export**: QuickBooks-compatible data export
- **Real-time UI**: Hotwire-powered interface with minimal JavaScript

## Technical Stack

- **Framework**: Rails 8.0.2 with Hotwire (Turbo + Stimulus)
- **Database**: PostgreSQL with JSONB for flexible form data
- **Frontend**: TailwindCSS + ViewComponent architecture
- **Authentication**: NationBuilder OAuth with automatic token refresh
- **Testing**: RSpec with FactoryBot
- **Deployment**: Fly.io with Docker

## Quick Start

1. **Setup**
   ```bash
   git clone https://github.com/your-organization/jupiter.git
   cd jupiter
   bundle install && yarn install
   cp .env.example .env  # Configure environment variables
   bin/rails db:create db:migrate db:seed
   ```

2. **Development**
   ```bash
   bin/dev  # Runs Rails server + TailwindCSS watch
   # Visit http://localhost:3000
   ```

3. **Testing**
   ```bash
   bin/rspec      # Run tests
   bin/rubocop    # Code linting
   ```

## Documentation

### Development
- **[Setup Guide](docs/SETUP.md)** - Development environment setup
- **[Contributing](CONTRIBUTING.md)** - Development guidelines and workflow

### Features
- **[Forms System](docs/FORMS.md)** - Treasury forms implementation
- **[OAuth Integration](docs/OAUTH.md)** - NationBuilder authentication

### Design & UI
- **[Brand Guidelines](docs/brand-guidelines.md)** - Democrats Abroad brand standards
- **[UI Component Reference](docs/ui_component_reference.md)** - ViewComponent library and examples

### Operations
- **[Deployment](docs/DEPLOYMENT.md)** - Production deployment guide

## Test Users

Development includes test users with various roles:

| Email                | Password      | Role                    |
|----------------------|---------------|-------------------------|
| admin@example.com    | password123   | system_administrator    |
| submitter@example.com| password123   | submitter               |
| treasury@example.com | password123   | treasury_team_admin     |
| viewer@example.com   | password123   | viewer                  |

Run `bin/rake seed:stats` to see all available test accounts.

## Contributing

Please see [CONTRIBUTING.md](CONTRIBUTING.md) for development guidelines.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

Copyright (c) 2025 Brett McHargue
