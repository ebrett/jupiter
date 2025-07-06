# Development Setup

This guide will help you set up Jupiter for local development.

## Prerequisites

- Ruby 3.2+ (see `.ruby-version` file for exact version)
- PostgreSQL 14+
- Node.js 18+ and Yarn
- Redis (for ActionCable in development)

## Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/your-organization/jupiter.git
   cd jupiter
   ```

2. **Install dependencies**
   ```bash
   bundle install
   yarn install
   ```

3. **Setup environment variables**
   ```bash
   cp .env.example .env
   # Edit .env with your local configuration
   ```

4. **Setup database**
   ```bash
   bin/rails db:create db:migrate db:seed
   ```

5. **Start the development server**
   ```bash
   bin/rails server
   # or with Procfile for concurrent processes
   bin/dev  # Runs web server + TailwindCSS watch
   ```

6. **Visit the application**
   Open http://localhost:3000 in your browser

## Environment Variables

Copy `.env.example` to `.env` and configure the following:

### Required for Development
```bash
# Database
DATABASE_URL=postgresql://username:password@localhost:5432/jupiter_development

# Rails
SECRET_KEY_BASE=generate_with_rails_secret
RAILS_MASTER_KEY=your_master_key

# NationBuilder OAuth (optional for basic development)
NATIONBUILDER_CLIENT_ID=your_client_id
NATIONBUILDER_CLIENT_SECRET=your_client_secret
NATIONBUILDER_REDIRECT_URI=http://localhost:3000/auth/nationbuilder/callback
NATIONBUILDER_NATION_SLUG=your_nation_slug
```

## Test Data

The application includes comprehensive test data for development:

```bash
# Create test users (idempotent)
bin/rails db:seed

# View available test users
bin/rake seed:stats

# Reset all test users
bin/rake seed:reset_users
```

### Test User Accounts

| Email                | Password      | Roles                    |
|----------------------|---------------|--------------------------|
| admin@example.com    | password123   | system_administrator     |
| submitter@example.com| password123   | submitter                |
| treasury@example.com | password123   | treasury_team_admin      |
| viewer@example.com   | password123   | viewer                   |

## Development Commands

```bash
# Testing
bin/rspec                            # Run all tests
bin/rspec spec/models/               # Run specific directory
bin/rspec spec/models/user_spec.rb   # Run single file

# Code Quality
bin/rubocop                          # Linting
bin/brakeman                         # Security scanning

# Database
bin/rails db:migrate                 # Run migrations
bin/rails db:rollback                # Rollback last migration
bin/rails db:reset                   # Drop, create, migrate, seed
```

## Troubleshooting

### Common Issues

**Database connection errors:**
- Ensure PostgreSQL is running
- Check DATABASE_URL in .env file
- Verify database exists: `bin/rails db:create`

**Asset compilation issues:**
- Run `yarn install` to update packages
- Clear tmp files: `bin/rails tmp:clear`
- Restart server after asset changes

**OAuth errors in development:**
- OAuth requires HTTPS in production but works with HTTP in development
- Check NationBuilder app settings match your redirect URI
- Verify environment variables are set correctly

## UI Development

### Brand Guidelines
Jupiter follows Democrats Abroad brand standards. See [Brand Guidelines](brand-guidelines.md) for:
- Logo usage and clear space requirements
- Brand color palette and Tailwind configuration
- Typography guidelines (Overpass, Oswald fonts)
- Caucus-specific branding

### Component Development
- **ViewComponents**: Located in `app/components/`
- **Stimulus Controllers**: Located in `app/javascript/controllers/`
- **Reference Libraries**: See [UI Component Reference](ui_component_reference.md)

### Available Resources
```bash
# Tailwind UI examples (HTML for reference)
ls scripts/tailwind-ui/

# Catalyst UI Kit (React/TypeScript for translation)
ls scripts/catalyst-ui-kit/

# Existing ViewComponents
ls app/components/catalyst/
```

### Getting Help

- Check the main [README](../README.md) for additional information
- Review [CONTRIBUTING](../CONTRIBUTING.md) for development guidelines
- See [UI Component Reference](ui_component_reference.md) for component examples
- Open an issue for specific problems