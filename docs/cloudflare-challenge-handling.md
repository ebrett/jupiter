# Cloudflare Challenge Handling System

A comprehensive solution for handling Cloudflare challenges during NationBuilder OAuth authentication flows in the Jupiter application.

## Overview

This system provides seamless handling of Cloudflare challenges (Turnstile, browser verification, rate limiting) that may occur during NationBuilder OAuth authentication. When a challenge is detected, users are guided through a secure completion process before resuming their authentication flow.

## Features

- **Multiple Challenge Types**: Supports Turnstile, browser challenges, and rate limiting scenarios
- **Seamless OAuth Integration**: Automatically detects and handles challenges without breaking the authentication flow
- **Feature Flag Control**: Safe deployment and instant rollback capabilities
- **Comprehensive Security**: Session validation, challenge expiration, and unauthorized access prevention
- **Accessible UI**: WCAG-compliant interface with responsive design
- **Robust Error Handling**: Graceful degradation and user-friendly error messages

## Architecture

### Core Components

#### Models
- **`CloudflareChallenge`**: Stores challenge state, OAuth parameters, and session data
  - Validates challenge types and required fields
  - Provides active/expired scopes and session filtering
  - Auto-expires challenges after 15 minutes

#### Services
- **`NationbuilderTokenExchangeService`**: Detects Cloudflare challenges during OAuth token exchange
- **`TurnstileVerificationService`**: Handles Cloudflare Turnstile widget verification
- **`CloudflareChallenge` (Value Object)**: Parses challenge responses and extracts metadata

#### Controllers
- **`NationbuilderAuthController`**: Enhanced OAuth flow with challenge detection and resumption
- **`CloudflareChallengesController`**: Challenge display, verification, and completion handling

#### UI Components
- **`CloudflareChallengeComponent`**: ViewComponent for rendering challenge interfaces
- **Challenge Views**: Responsive templates with JavaScript integration

### Data Flow

```
1. User initiates NationBuilder OAuth
2. OAuth callback triggers token exchange
3. If Cloudflare challenge detected:
   a. Create CloudflareChallenge record
   b. Redirect to challenge page
   c. User completes challenge
   d. Verify challenge response
   e. Resume OAuth flow with completion flag
4. Continue normal authentication
```

## Installation

### Prerequisites

- Rails 8.0.2+
- PostgreSQL database
- Cloudflare Turnstile site keys
- NationBuilder OAuth credentials

### Database Migration

```bash
bin/rails db:migrate
```

The migration creates the `cloudflare_challenges` table with:
- `challenge_id` (UUID, unique)
- `challenge_type` (enum: turnstile, browser_challenge, rate_limit)
- `challenge_data` (JSON metadata)
- `oauth_state` (OAuth state parameter)
- `original_params` (JSON, OAuth callback parameters)
- `session_id` (session tracking)
- `user_id` (optional, for authenticated users)
- `expires_at` (15-minute expiration)

### Environment Configuration

Add to your environment variables:

```bash
# Cloudflare Turnstile Configuration
CLOUDFLARE_TURNSTILE_SITE_KEY=your_site_key_here
CLOUDFLARE_TURNSTILE_SECRET_KEY=your_secret_key_here

# NationBuilder OAuth (existing)
NATIONBUILDER_CLIENT_ID=your_client_id
NATIONBUILDER_CLIENT_SECRET=your_client_secret
NATIONBUILDER_REDIRECT_URI=https://yourapp.com/auth/nationbuilder/callback
NATIONBUILDER_NATION_SLUG=your_nation
```

### Feature Flags

Enable the feature flags in your seed data or admin interface:

```ruby
# Enable in db/seeds.rb or Rails console
FeatureFlag.find_or_create_by!(name: 'cloudflare_challenge_handling') do |flag|
  flag.description = 'Enable Cloudflare challenge handling during OAuth flows'
  flag.enabled = true  # Set to false for gradual rollout
end

FeatureFlag.find_or_create_by!(name: 'nationbuilder_signin') do |flag|
  flag.description = 'Enable NationBuilder OAuth sign-in functionality'
  flag.enabled = true
end
```

## Usage

### Basic OAuth Flow

The system integrates seamlessly with existing NationBuilder OAuth:

```erb
<!-- In your sign-in view -->
<%= link_to "Sign in with NationBuilder", "/auth/nationbuilder", 
    class: "btn btn-primary" %>
```

### Challenge Detection

Challenges are automatically detected during token exchange:

```ruby
# In NationbuilderAuthController#callback
begin
  token_data = token_exchange_service.exchange_code_for_token(params[:code])
  # Continue normal OAuth flow
rescue NationbuilderTokenExchangeService::TokenExchangeError => e
  if e.message == "cloudflare_challenge" && cloudflare_challenge_handling_enabled?
    handle_cloudflare_challenge(e.data[:challenge])
  else
    # Fallback to standard error handling
  end
end
```

### Challenge Types

#### Turnstile Challenge
Interactive widget requiring user interaction:
```ruby
challenge_data = { 
  "turnstile_present" => true,
  "site_key" => "0x4AAAAAAABkMYinukHgb"
}
```

#### Browser Challenge
Automatic browser verification:
```ruby
challenge_data = { 
  "challenge_stage_present" => true,
  "legacy_detection" => false
}
```

#### Rate Limit Challenge
Too many requests scenario:
```ruby
challenge_data = { 
  "rate_limited" => true
}
```

### Manual Challenge Creation

For testing or custom scenarios:

```ruby
challenge = CloudflareChallenge.create!(
  challenge_id: SecureRandom.uuid,
  challenge_type: 'turnstile',
  challenge_data: { 'turnstile_present' => true },
  oauth_state: params[:state],
  original_params: params.permit!.to_h,
  session_id: session.id,
  user: current_user, # optional
  expires_at: 15.minutes.from_now
)

redirect_to cloudflare_challenge_path(challenge.challenge_id)
```

## API Reference

### Routes

```ruby
# OAuth routes (existing)
get '/auth/nationbuilder', to: 'nationbuilder_auth#redirect'
get '/auth/nationbuilder/callback', to: 'nationbuilder_auth#callback'

# Challenge routes
resources :cloudflare_challenges, param: :challenge_id, only: [:show] do
  member do
    post :verify
    get :complete
  end
end
```

### Challenge Controller Actions

#### `GET /cloudflare_challenges/:challenge_id`
Displays the challenge interface to the user.

**Parameters:**
- `challenge_id` (required): UUID of the challenge

**Responses:**
- `200`: Challenge page rendered
- `302`: Redirect to sign-in if challenge invalid/expired

#### `POST /cloudflare_challenges/:challenge_id/verify`
Processes challenge response (Turnstile token, etc.).

**Parameters:**
- `challenge_id` (required): UUID of the challenge
- `cf_turnstile_response` (optional): Turnstile response token

**Responses:**
- `302`: Redirect to completion on success
- `200`: Re-render challenge with error on failure

#### `GET /cloudflare_challenges/:challenge_id/complete`
Completes the challenge and resumes OAuth flow.

**Responses:**
- `302`: Redirect to OAuth callback with completion flag

### Service Classes

#### `NationbuilderTokenExchangeService`

```ruby
service = NationbuilderTokenExchangeService.new(
  client_id: ENV['NATIONBUILDER_CLIENT_ID'],
  client_secret: ENV['NATIONBUILDER_CLIENT_SECRET'],
  redirect_uri: ENV['NATIONBUILDER_REDIRECT_URI']
)

begin
  tokens = service.exchange_code_for_token(oauth_code)
rescue NationbuilderTokenExchangeService::TokenExchangeError => e
  if e.message == "cloudflare_challenge"
    challenge = e.data[:challenge]
    # Handle challenge
  end
end
```

#### `TurnstileVerificationService`

```ruby
service = TurnstileVerificationService.new(
  response_token: params[:cf_turnstile_response],
  user_ip: request.remote_ip
)

if service.verify
  # Challenge passed
else
  # Challenge failed
end
```

## Testing

The system includes comprehensive test coverage:

### Running Tests

```bash
# Run all Cloudflare challenge tests (121 tests)
bin/rspec spec/models/cloudflare_challenge_spec.rb \
          spec/services/turnstile_verification_service_spec.rb \
          spec/services/nationbuilder_token_exchange_service_spec.rb \
          spec/controllers/cloudflare_challenges_controller_spec.rb \
          spec/components/cloudflare_challenge_component_spec.rb \
          spec/requests/cloudflare_challenge_feature_flag_spec.rb \
          spec/requests/nationbuilder_auth_cloudflare_spec.rb \
          spec/integration/cloudflare_service_integration_spec.rb

# Run specific test types
bin/rspec spec/models/cloudflare_challenge_spec.rb          # Model tests
bin/rspec spec/services/turnstile_verification_service_spec.rb  # Service tests
bin/rspec spec/requests/nationbuilder_auth_cloudflare_spec.rb   # Integration tests
```

### Test Coverage

- **Unit Tests**: 87 tests covering models, services, controllers, and components
- **Integration Tests**: 22 tests for service interactions and request flows
- **System Tests**: 12 tests for end-to-end user journeys

### Testing with WebMock

```ruby
# Stub Cloudflare challenge response
stub_request(:post, 'https://testnation.nationbuilder.com/oauth/token')
  .to_return(
    status: 403,
    body: turnstile_html,
    headers: { 'Content-Type' => 'text/html' }
  )

# Stub successful Turnstile verification
stub_request(:post, 'https://challenges.cloudflare.com/turnstile/v0/siteverify')
  .to_return(
    status: 200,
    body: { success: true }.to_json,
    headers: { 'Content-Type' => 'application/json' }
  )
```

## Deployment

### Production Checklist

1. **Environment Variables**: Configure Cloudflare Turnstile keys
2. **Database Migration**: Run `bin/rails db:migrate`
3. **Feature Flags**: Enable `cloudflare_challenge_handling` feature flag
4. **DNS Configuration**: Ensure Cloudflare protection is active
5. **Monitoring**: Set up alerts for challenge completion rates

### Gradual Rollout

Use feature flags for safe deployment:

```ruby
# Start with disabled flag
flag = FeatureFlag.find_by(name: 'cloudflare_challenge_handling')
flag.update!(enabled: false)

# Enable for specific users first
FeatureFlagAssignment.create!(
  feature_flag: flag,
  assignable: admin_user
)

# Enable globally when ready
flag.update!(enabled: true)
```

### Rollback Procedure

In case of issues:

```ruby
# Immediate rollback
flag = FeatureFlag.find_by(name: 'cloudflare_challenge_handling')
flag.update!(enabled: false)

# Clean up orphaned challenges (optional)
CloudflareChallenge.where('created_at < ?', 1.hour.ago).destroy_all
```

## Monitoring

### Key Metrics

Monitor these metrics in production:

- **Challenge Creation Rate**: Number of challenges created per hour
- **Challenge Completion Rate**: Percentage of challenges successfully completed
- **Challenge Types**: Distribution of Turnstile vs browser vs rate limit challenges
- **Completion Time**: Average time from challenge creation to completion
- **Error Rate**: Failed challenge verifications and system errors

### Logging

The system logs key events:

```ruby
Rails.logger.info "NationBuilder OAuth: Handling Cloudflare challenge"
Rails.logger.info "NationBuilder OAuth: Created challenge #{challenge.challenge_id}"
Rails.logger.info "NationBuilder OAuth: Challenge #{challenge.challenge_id} validated, resuming OAuth flow"
Rails.logger.error "NationBuilder OAuth: Challenge not found for state #{params[:state]}"
```

### Database Cleanup

Set up a scheduled job to clean up expired challenges:

```ruby
# In a background job or cron task
CloudflareChallenge.where('expires_at < ?', Time.current).destroy_all
```

## Security Considerations

### Challenge Validation

- **Session Verification**: Challenges are tied to specific sessions
- **Expiration**: Challenges automatically expire after 15 minutes
- **State Validation**: OAuth state parameters are preserved and validated
- **IP Tracking**: Turnstile verification includes user IP validation

### Access Control

- **Feature Flags**: Control access at user and global levels
- **Unauthenticated Access**: Challenge pages allow unauthenticated access for OAuth flows
- **Session Hijacking Prevention**: Session ID validation prevents unauthorized access

### Data Protection

- **Encrypted Storage**: Challenge data and OAuth parameters are stored securely
- **Parameter Filtering**: Only permitted OAuth parameters are preserved
- **Automatic Cleanup**: Expired challenges are cleaned up automatically

## Troubleshooting

### Common Issues

#### Challenge Not Found Error

```
Challenge not found for state oauth_state_123
```

**Causes:**
- Session mismatch (user switched browsers/devices)
- Challenge expired (>15 minutes old)
- Database cleanup removed challenge

**Solutions:**
- Redirect user to restart OAuth flow
- Check session ID consistency
- Verify challenge expiration settings

#### Turnstile Verification Failed

```
Challenge verification failed. Please try again.
```

**Causes:**
- Invalid Turnstile response token
- Incorrect secret key configuration
- Network timeout to Cloudflare API

**Solutions:**
- Verify `CLOUDFLARE_TURNSTILE_SECRET_KEY` is correct
- Check network connectivity to `challenges.cloudflare.com`
- Review Cloudflare dashboard for site key issues

#### Feature Flag Disabled

```
Challenge handling is currently unavailable. Please try signing in again.
```

**Causes:**
- Feature flag globally disabled
- User lacks feature flag assignment

**Solutions:**
- Check `cloudflare_challenge_handling` feature flag status
- Verify user has proper feature flag assignment
- Enable flag for gradual rollout

### Debug Mode

Enable debug logging in development:

```ruby
# In development.rb
config.log_level = :debug

# View full OAuth flow logs
tail -f log/development.log | grep "NationBuilder OAuth"
```

### Testing Challenges Locally

Force challenge scenarios for testing:

```ruby
# In Rails console - force challenge creation
stub_request(:post, /nationbuilder.*oauth.*token/)
  .to_return(status: 403, body: turnstile_html)

# Test with different challenge types
challenge = CloudflareChallenge.create!(
  challenge_id: SecureRandom.uuid,
  challenge_type: 'turnstile', # or 'browser_challenge', 'rate_limit'
  challenge_data: { 'turnstile_present' => true },
  oauth_state: 'test_state',
  original_params: { 'code' => 'test_code', 'state' => 'test_state' },
  session_id: session.id,
  expires_at: 15.minutes.from_now
)
```

## Contributing

### Development Setup

1. Clone repository and install dependencies
2. Set up test environment variables
3. Run database migrations: `bin/rails db:migrate`
4. Seed feature flags: `bin/rails db:seed`
5. Run test suite: `bin/rspec`

### Code Quality

Maintain high code quality standards:

```bash
# Run linting
bin/rubocop

# Run security scanning
bin/brakeman

# Run full test suite
bin/rspec
```

### Adding New Challenge Types

To add support for new challenge types:

1. Update `CloudflareChallenge` model validation
2. Extend challenge detection in `NationbuilderTokenExchangeService`
3. Add UI handling in `CloudflareChallengeComponent`
4. Create comprehensive tests
5. Update documentation

## License

This Cloudflare Challenge Handling system is part of the Jupiter application. See the main application license for details.

## Support

For issues and questions:

1. Check the troubleshooting section above
2. Review test files for usage examples
3. Check application logs for specific error details
4. Create an issue in the project repository with:
   - Error messages and stack traces
   - Steps to reproduce
   - Environment details (Rails version, feature flag status)
   - Challenge ID and timestamp (if applicable)