# NationBuilder OAuth2 Implementation Guide

## Overview

This document provides comprehensive guidance for developers working with the NationBuilder OAuth2 implementation in the Jupiter application. The implementation supports both account linking for existing users and standalone sign-in for new users.

## Architecture

### Core Components

- **`Oauth2Client`**: Handles OAuth2 authorization URL generation
- **`NationbuilderAuthController`**: Manages OAuth flows and callbacks
- **`NationbuilderTokenExchangeService`**: Exchanges authorization codes for tokens
- **`NationbuilderTokenRefreshService`**: Handles automatic token refresh
- **`NationbuilderApiClient`**: Provides authenticated API access with automatic token management
- **`NationbuilderUserService`**: Manages user profile fetching and account creation
- **`NationbuilderToken`**: Model for secure token storage with encryption

### Error Handling Infrastructure

- **`NationbuilderOauthErrors`**: Centralized error classification
- **`NationbuilderErrorHandler`**: Recovery strategies and exponential backoff
- **`NationbuilderAuditLogger`**: Comprehensive event tracking and performance metrics

### Admin & Monitoring

- **`NationbuilderAccessMonitor`**: Rate limiting and usage tracking
- **`NationbuilderGracefulDegradation`**: Service resilience patterns

## Setup Instructions

### Environment Configuration

Required environment variables:

```bash
# NationBuilder OAuth Configuration
NATIONBUILDER_CLIENT_ID=your_client_id
NATIONBUILDER_CLIENT_SECRET=your_client_secret
NATIONBUILDER_REDIRECT_URI=http://localhost:3000/auth/nationbuilder/callback
NATIONBUILDER_NATION_SLUG=your_nation_slug

# Optional: Perplexity API for enhanced features
PERPLEXITY_API_KEY=your_perplexity_key
```

### Database Setup

The implementation requires the following database tables:

1. **users**: Enhanced with `nationbuilder_uid`, `first_name`, `last_name`
2. **nationbuilder_tokens**: Encrypted token storage
3. **sessions**: User session management

Run migrations:

```bash
rails db:migrate
```

### NationBuilder App Registration

1. Log into your NationBuilder admin panel
2. Navigate to Settings → Developer → Apps
3. Create a new app with these settings:
   - **Redirect URI**: `http://localhost:3000/auth/nationbuilder/callback` (development)
   - **Scopes**: `people:read`, `sites:read` (minimum required)
   - **App Type**: Web Application

## User Flows

### Flow 1: New User Sign-in

1. User visits `/sessions/new`
2. Clicks "Sign in with NationBuilder"
3. Redirected to NationBuilder authorization page
4. User authorizes application
5. Callback received at `/auth/nationbuilder/callback`
6. System exchanges code for tokens
7. Fetches user profile from NationBuilder API
8. Creates new local user account
9. Stores encrypted tokens
10. Creates session and redirects to dashboard

### Flow 2: Existing User Account Linking

1. Authenticated user visits OAuth link
2. Follows authorization flow (steps 3-6 above)
3. System links NationBuilder account to existing user
4. Updates user profile data
5. Stores tokens for API access

### Flow 3: Automatic Token Refresh

1. API request detects expired access token
2. `NationbuilderApiClient` automatically triggers refresh
3. `NationbuilderTokenRefreshService` exchanges refresh token
4. New tokens stored and original request retried
5. Transparent to end user

## API Usage Examples

### Making Authenticated API Calls

```ruby
# Initialize API client for a user
user = User.find(1)
api_client = NationbuilderApiClient.new(user: user)

# Make API requests - tokens are automatically managed
people = api_client.get('/api/v2/people')
person = api_client.get('/api/v2/people/123')

# The client handles token refresh automatically
data = api_client.post('/api/v2/people', params: {
  person: {
    first_name: 'John',
    last_name: 'Doe',
    email: 'john@example.com'
  }
})
```

### Manual Token Management

```ruby
# Check token status
user = User.find(1)
token = user.nationbuilder_tokens.first

if token.needs_refresh?
  success = token.refresh!
  puts "Token refresh #{success ? 'succeeded' : 'failed'}"
end

# Check token validity
if token.valid_for_api_use?
  # Safe to make API calls
else
  # Token expired or invalid
end
```

### Background Token Refresh

```ruby
# Enqueue refresh jobs for expiring tokens
NationbuilderTokenRefreshJob.enqueue_for_expiring_tokens(30) # 30 minutes buffer

# Individual user refresh
NationbuilderTokenRefreshJob.perform_later(user.id)
```

## Error Handling

### Error Types

The implementation includes comprehensive error classification:

- **`ConfigurationError`**: Missing environment variables or setup issues
- **`NetworkError`**: Connection timeouts, DNS failures
- **`AuthenticationError`**: Invalid credentials, expired tokens
- **`AuthorizationError`**: Insufficient permissions
- **`RateLimitError`**: API rate limiting
- **`ServerError`**: NationBuilder API server errors
- **`UserCreationError`**: Account creation failures

### Recovery Strategies

```ruby
begin
  api_client.get('/api/v2/people')
rescue NationbuilderOauthErrors::RateLimitError => e
  # Automatic retry with exponential backoff
  retry_after = e.retry_after || 60
  sleep(retry_after)
  retry
rescue NationbuilderOauthErrors::AuthenticationError => e
  # Trigger re-authentication flow
  redirect_to '/auth/nationbuilder'
rescue NationbuilderOauthErrors::NetworkError => e
  # Graceful degradation
  render_cached_data_with_warning
end
```

## Testing

### Test Environment Setup

```ruby
# spec/rails_helper.rb
RSpec.configure do |config|
  config.before(:each) do
    # Set test environment variables
    ENV['NATIONBUILDER_NATION_SLUG'] = 'testnation'
    ENV['NATIONBUILDER_CLIENT_ID'] = 'test_client_id'
    ENV['NATIONBUILDER_CLIENT_SECRET'] = 'test_secret'
  end
end
```

### Mocking OAuth Flows

```ruby
# Mock token exchange
stub_request(:post, 'https://testnation.nationbuilder.com/oauth/token')
  .to_return(
    status: 200,
    body: {
      access_token: 'test_token',
      refresh_token: 'test_refresh',
      expires_in: 3600
    }.to_json,
    headers: { 'Content-Type' => 'application/json' }
  )

# Mock user profile API
stub_request(:get, 'https://testnation.nationbuilder.com/api/v2/people/me')
  .with(headers: { 'Authorization' => 'Bearer test_token' })
  .to_return(
    status: 200,
    body: {
      data: {
        id: 123,
        email: 'test@example.com',
        first_name: 'Test',
        last_name: 'User'
      }
    }.to_json
  )
```

### Test Factories

```ruby
# spec/factories/nationbuilder_tokens.rb
FactoryBot.define do
  factory :nationbuilder_token do
    user
    access_token { 'test_access_token' }
    refresh_token { 'test_refresh_token' }
    expires_at { 1.hour.from_now }
    scope { 'people:read sites:read' }
  end

  trait :expired do
    expires_at { 1.hour.ago }
  end

  trait :expiring_soon do
    expires_at { 3.minutes.from_now }
  end
end
```

## Monitoring & Admin

### Key Metrics

- **Token Health**: Valid/expired/expiring token counts
- **API Performance**: Response times, success rates
- **Error Patterns**: Authentication failures, rate limits
- **Usage Analytics**: API call volumes, popular endpoints

### Alerts & Notifications

The system automatically monitors for:

- High authentication failure rates
- Unusual API error patterns
- Token refresh failures
- System configuration issues
- Security anomalies

## Security Considerations

### Token Security

- All tokens are encrypted at rest using Rails 8 built-in encryption
- Tokens are never logged or exposed in error messages
- Automatic token rotation on refresh
- Secure token cleanup on user deletion

### API Security

- Rate limiting and request throttling
- Request/response correlation IDs for audit trails
- Comprehensive logging without sensitive data exposure
- IP-based session tracking

### Error Handling Security

- Generic error messages to prevent information leakage
- Detailed logging for debugging (server-side only)
- Automatic retry limits to prevent abuse
- Graceful degradation to maintain service availability

## Troubleshooting

### Common Issues

**1. "NATIONBUILDER_NATION_SLUG environment variable is not set"**
- Ensure all required environment variables are configured
- Check `.env` file in development
- Verify environment variable naming (no typos)

**2. "Invalid redirect URI"**
- Ensure redirect URI in NationBuilder app matches `NATIONBUILDER_REDIRECT_URI`
- Check for trailing slashes or protocol mismatches

**3. "Token refresh failed"**
- User may have revoked app access in NationBuilder
- Refresh token may be expired (check `expires_at`)
- Check network connectivity to NationBuilder API

**4. "Authentication failed" during sign-in**
- Verify NationBuilder app credentials
- Check user permissions in NationBuilder
- Review error logs for specific failure reasons

### Debug Mode

Enable detailed logging:

```ruby
# In development environment
Rails.logger.level = :debug

# Check specific OAuth events
Rails.logger.debug "OAuth callback params: #{params.inspect}"
```

### Health Checks

```ruby
# Check system health
dashboard = NationbuilderAdminDashboard.new
health = dashboard.system_health_check

puts "OAuth System Health: #{health[:status]}"
puts "Configuration Issues: #{health[:configuration_errors]}"
puts "Active Token Count: #{health[:active_tokens]}"
```

## Performance Optimization

### Token Refresh Optimization

- Proactive token refresh (30 minutes before expiration)
- Request queuing during refresh to prevent multiple simultaneous refreshes
- Background job processing for bulk token operations

### API Client Optimization

- Connection pooling for HTTP requests
- Response caching where appropriate
- Correlation IDs for request tracing
- Performance metrics collection

### Database Optimization

- Indexed queries on token expiration
- Efficient token cleanup procedures
- Optimized user lookup patterns

## Migration Guide

### From Basic OAuth to Enterprise Implementation

If upgrading from a basic OAuth implementation:

1. **Update Environment Variables**: Add new required variables
2. **Run Migrations**: Execute database schema updates
3. **Update Error Handling**: Replace basic error handling with classified errors
4. **Add Monitoring**: Integrate admin dashboard and metrics
5. **Test Thoroughly**: Verify all flows work correctly

### Version Compatibility

- **Rails**: 8.0+
- **Ruby**: 3.1+
- **PostgreSQL**: 12+
- **NationBuilder API**: V2

## Support

For additional support:

1. Check the Rails logs for detailed error information
2. Review the admin dashboard for system health status
3. Consult the NationBuilder API documentation
4. Review test cases for usage examples

---

This implementation provides enterprise-grade OAuth2 integration with comprehensive error handling, monitoring, and security features suitable for production use.