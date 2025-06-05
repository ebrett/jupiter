# Role Management System Tests

This directory contains comprehensive system/integration tests for the role management functionality in the Jupiter Rails application.

## Test Structure

### 1. Core Test Files

- **`role_management_spec.rb`** - Main role management functionality tests
  - Role assignment and removal
  - Role-based access control
  - Bulk operations
  - Filtering and search
  - Role hierarchy display

- **`role_authorization_spec.rb`** - Authorization and access control tests
  - Admin dashboard access by role
  - User management permissions
  - System configuration access
  - OAuth status monitoring
  - Profile access based on roles

- **`role_edge_cases_spec.rb`** - Edge cases and complex scenarios
  - Last super admin protection
  - Concurrent role modifications
  - Role conflicts and validation
  - Performance with many users
  - Emergency access procedures

- **`role_management_comprehensive_spec.rb`** - Complete test plan
  - End-to-end workflow testing
  - Critical path testing
  - Security testing
  - Performance benchmarks
  - Compliance and audit requirements

### 2. Request/Integration Tests

- **`spec/requests/role_management_spec.rb`** - API and controller tests
  - Role assignment endpoints
  - Bulk operations
  - Role filtering
  - Permission checks

### 3. Unit Tests

- **`spec/models/role_spec.rb`** - Role model tests
- **`spec/models/user_spec.rb`** - User role methods tests
- **`spec/policies/role_policy_spec.rb`** - Role policy tests

## Running Tests

### Run all role management tests:
```bash
bundle exec rspec spec/system/role_*
```

### Run specific test file:
```bash
bundle exec rspec spec/system/role_management_spec.rb
```

### Run with specific examples:
```bash
bundle exec rspec spec/system/role_management_spec.rb:23
```

### Run with documentation format:
```bash
bundle exec rspec spec/system/role_* --format documentation
```

### Run JavaScript tests (with headless Chrome):
```bash
bundle exec rspec spec/system/role_* --tag js
```

## Test Coverage Areas

### 1. Authentication & Authorization
- Role-based access to admin areas
- Permission enforcement
- Multi-level authorization checks

### 2. Role Management
- Creating and assigning roles
- Removing roles
- Bulk operations
- Role transitions

### 3. User Interface
- Role assignment forms
- Bulk action interfaces
- Role filtering and search
- Role badge display

### 4. Data Integrity
- Preventing invalid role states
- Maintaining role consistency
- Cascading deletes
- Audit trail

### 5. Performance
- Large dataset handling
- Search optimization
- Page load times

### 6. Security
- Privilege escalation prevention
- CSRF protection
- Input validation

## Test Helpers

The `spec/support/system_test_helpers.rb` file provides useful helper methods:

- `login_as(user)` - Log in as a specific user
- `create_user_with_role(role_name)` - Create user with a role
- `expect_authorized_access` - Assert authorized access
- `expect_unauthorized_access` - Assert unauthorized access
- `within_user_row(user)` - Scope actions to user's table row
- `select_users_for_bulk_action(*users)` - Select multiple users
- `perform_bulk_action(action, option)` - Execute bulk actions

## Prerequisites

1. **Database Setup**
   ```bash
   rails db:test:prepare
   ```

2. **Chrome/Chromium for JS tests**
   - Install Chrome or Chromium browser
   - Tests use headless Chrome by default

3. **Test Data**
   - Tests automatically create required roles
   - Uses FactoryBot for test data generation

## Writing New Tests

When adding new role management features:

1. Add unit tests for models/policies
2. Add request specs for API endpoints
3. Add system tests for UI interactions
4. Update comprehensive test plan if needed

### Example Test Structure:
```ruby
RSpec.describe "New Role Feature", type: :system do
  before { ensure_roles_exist }
  
  describe "feature description" do
    let(:super_admin) { create_user_with_role(:super_admin) }
    
    it "does something specific" do
      login_as(super_admin)
      # Test implementation
    end
  end
end
```

## Common Issues

1. **Flaky JavaScript tests**
   - Use `wait_for_ajax` helpers
   - Increase Capybara wait time if needed

2. **Database state issues**
   - Tests use transactional fixtures
   - Each test starts with clean state

3. **Role seeding issues**
   - `ensure_roles_exist` helper handles this
   - Check `spec/rails_helper.rb` for setup

## CI/CD Integration

These tests are designed to run in CI environments:
- Use headless Chrome
- Set up test database automatically
- Generate coverage reports
- Fail fast on critical errors