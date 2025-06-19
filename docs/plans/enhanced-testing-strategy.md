# Enhanced Testing Strategy for Jupiter

## Overview

This document outlines a comprehensive testing strategy to address critical gaps in the current test suite, particularly around user authentication flows and end-to-end functionality testing.

## Current Testing Problems

### 1. Missing End-to-End Coverage
- No system/integration tests that simulate real user behavior through browser
- Authentication flows are only tested at the controller level in isolation
- Modal interactions and JavaScript behavior are completely untested

### 2. Component Testing Limitations
- `AuthModalComponent` tests only verify HTML output, not actual form submission behavior
- No testing of modal mode switching (login ↔ register)
- Form action changes aren't verified in realistic scenarios

### 3. JavaScript Testing Gap
- Stimulus controller behavior is completely untested
- No verification that form actions update correctly when switching modes
- Field visibility toggling logic isn't covered

### 4. Integration Issues
- Controllers are tested individually but not as part of complete user journeys
- No testing of the full modal → form submission → redirect flow
- Feature flag integration with UI components isn't tested end-to-end

## Recommended Testing Stack

### Core Tools (Already Available)
- **Capybara** - Ruby DSL for browser automation, excellent Rails integration
- **Selenium WebDriver** - Reliable browser automation for Chrome/Firefox
- **RSpec** - Existing test framework, perfect for system tests

### Why This Stack Works
1. **Native Rails Integration** - Seamless with existing authentication system
2. **Team Consistency** - Everyone already knows RSpec/Capybara
3. **Simple Debugging** - Easy to inspect page state and HTML output
4. **CI/CD Ready** - Headless Chrome support for fast automated testing

### What We DON'T Need
- **SitePrism** - Page object pattern is overkill for this application size
- **Puppeteer/Playwright** - Node.js tools would add unnecessary complexity
- **Complex frameworks** - Keep it simple and maintainable

## Testing Strategy Implementation

### 1. System Tests (Primary Focus)

Create comprehensive browser-based tests in `spec/system/`:

```ruby
# spec/system/authentication_spec.rb
require 'rails_helper'

RSpec.describe 'User Authentication', type: :system do
  context 'User Registration Flow' do
    it 'allows new user to create account via modal' do
      visit root_path
      
      # Open auth modal
      click_button 'Sign In'
      expect(page).to have_css('#auth-modal', visible: true)
      
      # Switch to registration mode
      within '#auth-modal' do
        click_link 'Sign up'
        
        # Verify form action changed to users path
        expect(page).to have_css('form[action="/users"]')
        
        # Verify registration fields are visible
        expect(page).to have_field('First name', visible: true)
        expect(page).to have_field('Last name', visible: true)
        expect(page).to have_field('Confirm password', visible: true)
        
        # Verify login-only fields are hidden
        expect(page).not_to have_field('Remember me', visible: true)
        expect(page).not_to have_link('Forgot password?', visible: true)
      end
      
      # Fill registration form
      within '#auth-modal' do
        fill_in 'First name', with: 'John'
        fill_in 'Last name', with: 'Doe'
        fill_in 'Email address', with: 'john@example.com'
        fill_in 'Password', with: 'password123'
        fill_in 'Confirm password', with: 'password123'
        
        click_button 'Create account'
      end
      
      # Verify successful registration
      expect(page).to have_text('Account created')
      expect(page).to have_text('check your email')
      expect(page).not_to have_css('#auth-modal', visible: true)
      
      # Verify user was created in database
      user = User.find_by(email_address: 'john@example.com')
      expect(user).to be_present
      expect(user.first_name).to eq('John')
      expect(user.last_name).to eq('Doe')
    end
  end

  context 'User Sign In Flow' do
    let(:user) { create(:user, password: 'password123') }
    
    it 'allows existing user to sign in via modal' do
      visit root_path
      
      # Open auth modal (defaults to login mode)
      click_button 'Sign In'
      
      within '#auth-modal' do
        # Verify login form is configured correctly
        expect(page).to have_css('form[action="/session"]')
        expect(page).to have_field('Remember me', visible: true)
        expect(page).to have_link('Forgot password?', visible: true)
        
        # Verify registration fields are hidden
        expect(page).not_to have_field('First name', visible: true)
        expect(page).not_to have_field('Confirm password', visible: true)
        
        # Fill and submit login form
        fill_in 'Email address', with: user.email_address
        fill_in 'Password', with: 'password123'
        check 'Remember me'
        
        click_button 'Sign in'
      end
      
      # Verify successful login
      expect(page).to have_text('Welcome back')
      expect(page).not_to have_css('#auth-modal', visible: true)
      expect(page).not_to have_button('Sign In') # User is now logged in
    end
  end

  context 'Modal Mode Switching' do
    it 'properly toggles between login and registration modes' do
      visit root_path
      click_button 'Sign In'
      
      within '#auth-modal' do
        # Start in login mode
        expect(page).to have_text('Sign in to Jupiter')
        expect(page).to have_css('form[action="/session"]')
        expect(page).to have_button('Sign in')
        
        # Switch to register mode
        click_link 'Sign up'
        
        expect(page).to have_text('Create your Jupiter account')
        expect(page).to have_css('form[action="/users"]')
        expect(page).to have_button('Create account')
        
        # Switch back to login mode
        click_link 'Sign in'
        
        expect(page).to have_text('Sign in to Jupiter')
        expect(page).to have_css('form[action="/session"]')
        expect(page).to have_button('Sign in')
      end
    end
  end
end
```

### 2. Feature Flag Integration Tests

```ruby
# spec/system/feature_flag_auth_spec.rb
require 'rails_helper'

RSpec.describe 'Feature Flag Auth Integration', type: :system do
  context 'when nationbuilder_signin feature is enabled' do
    before do
      FeatureFlag.create!(name: 'nationbuilder_signin', enabled: true, description: 'Test flag')
    end
    
    it 'shows NationBuilder OAuth option in both modes' do
      visit root_path
      click_button 'Sign In'
      
      within '#auth-modal' do
        # Login mode
        expect(page).to have_link('Sign in with Democrats Abroad')
        expect(page).to have_text('Or continue with email')
        
        # Switch to register mode
        click_link 'Sign up'
        expect(page).to have_link('Sign up with Democrats Abroad')
      end
    end
  end
  
  context 'when nationbuilder_signin feature is disabled' do
    it 'hides NationBuilder OAuth option completely' do
      visit root_path
      click_button 'Sign In'
      
      within '#auth-modal' do
        expect(page).not_to have_link(href: '/auth/nationbuilder')
        expect(page).not_to have_text('Or continue with email')
        expect(page).not_to have_text('Sign in with')
      end
    end
  end
end
```

### 3. Enhanced Component Tests

Update existing component tests to verify form behavior:

```ruby
# spec/components/auth_modal_component_spec.rb (additions)
describe "form configuration" do
  it "configures form action correctly for login mode" do
    render_inline(described_class.new(mode: :login))
    
    expect(rendered_content).to have_css('form[action="/session"]')
    expect(rendered_content).to have_css('input[type="submit"][value="Sign in"]')
  end
  
  it "configures form action correctly for register mode" do
    render_inline(described_class.new(mode: :register))
    
    expect(rendered_content).to have_css('form[action="/users"]')
    expect(rendered_content).to have_css('input[type="submit"][value="Create account"]')
  end
  
  it "includes required data attributes for JavaScript functionality" do
    render_inline(described_class.new(mode: :login))
    
    expect(rendered_content).to have_css('[data-controller="auth"]')
    expect(rendered_content).to have_css('[data-auth-target="form"]')
    expect(rendered_content).to have_css('[data-auth-mode-value="login"]')
  end
end
```

### 4. JavaScript/Stimulus Testing

```ruby
# spec/javascript/controllers/auth_controller_spec.rb
require 'rails_helper'

RSpec.describe 'AuthController', type: :system, js: true do
  it 'updates form action when switching modes' do
    visit root_path
    click_button 'Sign In'
    
    # Verify initial state
    expect(page).to have_css('form[action="/session"]')
    
    # Switch mode via JavaScript
    within '#auth-modal' do
      click_link 'Sign up'
    end
    
    # Verify form action updated
    expect(page).to have_css('form[action="/users"]')
  end
end
```

### 5. Integration Request Tests

```ruby
# spec/requests/authentication_flows_spec.rb
require 'rails_helper'

RSpec.describe 'Authentication Flow Integration', type: :request do
  describe 'Registration via modal submission' do
    let(:valid_params) do
      {
        email_address: 'test@example.com',
        password: 'password123',
        password_confirmation: 'password123',
        first_name: 'Test',
        last_name: 'User'
      }
    end
    
    it 'processes registration from modal correctly' do
      post '/users', params: valid_params
      
      expect(response).to redirect_to(root_path)
      expect(flash[:notice]).to match(/Account created/)
      
      user = User.find_by(email_address: 'test@example.com')
      expect(user).to be_present
    end
  end
end
```

## Test Infrastructure Setup

### 1. System Test Configuration

```ruby
# spec/rails_helper.rb (additions)
RSpec.configure do |config|
  config.before(:each, type: :system) do
    driven_by :selenium, using: :headless_chrome, screen_size: [1400, 1400]
  end
  
  config.before(:each, type: :system, js: true) do
    driven_by :selenium, using: :chrome, screen_size: [1400, 1400]
  end
end

# For debugging, configure screenshot on failure
Capybara.save_path = Rails.root.join('tmp', 'capybara')
```

### 2. Shared Test Helpers

```ruby
# spec/support/system_test_helpers.rb
module SystemTestHelpers
  def sign_in_user(user, password: 'password123')
    visit root_path
    click_button 'Sign In'
    
    within '#auth-modal' do
      fill_in 'Email address', with: user.email_address
      fill_in 'Password', with: password
      click_button 'Sign in'
    end
  end
  
  def open_registration_modal
    visit root_path
    click_button 'Sign In'
    
    within '#auth-modal' do
      click_link 'Sign up'
    end
  end
  
  def expect_modal_closed
    expect(page).not_to have_css('#auth-modal', visible: true)
  end
end

RSpec.configure do |config|
  config.include SystemTestHelpers, type: :system
end
```

### 3. Database Cleaner Setup

```ruby
# spec/rails_helper.rb (additions)
RSpec.configure do |config|
  config.use_transactional_fixtures = false
  
  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation)
  end
  
  config.before(:each) do
    DatabaseCleaner.strategy = :transaction
  end
  
  config.before(:each, type: :system) do
    DatabaseCleaner.strategy = :truncation
  end
  
  config.before(:each) do
    DatabaseCleaner.start
  end
  
  config.after(:each) do
    DatabaseCleaner.clean
  end
end
```

## Test Organization Structure

```
spec/
├── system/
│   ├── authentication_spec.rb          # Core auth flows
│   ├── feature_flag_auth_spec.rb       # Feature flag integration
│   ├── modal_interactions_spec.rb      # Modal behavior testing
│   └── user_registration_spec.rb       # Registration edge cases
├── components/
│   └── auth_modal_component_spec.rb    # Enhanced component tests
├── requests/
│   └── authentication_flows_spec.rb    # Integration request tests
├── javascript/
│   └── controllers/
│       └── auth_controller_spec.rb     # Stimulus testing
└── support/
    ├── system_test_helpers.rb          # Shared utilities
    └── auth_test_helpers.rb            # Authentication-specific helpers
```

## Benefits of This Strategy

### 1. Bug Prevention
- **Catches Real Issues** - Would have immediately caught the form action bug
- **JavaScript Coverage** - Ensures client-side behavior works correctly
- **Integration Testing** - Verifies complete user journeys, not just isolated units

### 2. Development Confidence
- **Safe Refactoring** - Can modify code knowing tests will catch regressions
- **Feature Flag Safety** - Ensures feature flags don't break core functionality
- **Modal Behavior** - Verifies complex UI interactions work as expected

### 3. Documentation Value
- **Living Documentation** - System tests document expected user behavior
- **Onboarding Tool** - New developers can understand flows by reading tests
- **Requirements Verification** - Tests serve as acceptance criteria validation

### 4. Maintenance Benefits
- **Simple Debugging** - Easy to run individual tests and inspect failures
- **Fast Feedback** - Quick identification of what broke and where
- **CI/CD Ready** - Headless mode for automated testing environments

## Implementation Checklist

- [ ] Set up system test configuration with Capybara/Selenium
- [ ] Create core authentication flow tests
- [ ] Add feature flag integration tests
- [ ] Enhance existing component tests
- [ ] Add JavaScript behavior testing
- [ ] Create shared test helpers
- [ ] Configure database cleaner for system tests
- [ ] Set up CI/CD integration with headless Chrome
- [ ] Document test patterns for team consistency

## Success Metrics

After implementation, we should have:
- **Zero authentication bugs** reaching production
- **100% coverage** of critical user journeys
- **Fast test feedback** (< 30 seconds for full auth test suite)
- **Confident deployments** with comprehensive regression protection