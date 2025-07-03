# NationBuilder OAuth Integration

Jupiter integrates with NationBuilder for user authentication using OAuth 2.0. This document covers setup, testing, and troubleshooting.

## Overview

The OAuth integration provides:
- Single sign-on authentication with NationBuilder
- Automatic user profile synchronization
- Role-based access control
- Token refresh and management
- Graceful degradation when NationBuilder is unavailable

## Setup

### 1. Register Application with NationBuilder

1. Log in to your NationBuilder nation's control panel
2. Navigate to **Settings → Developer → OAuth Applications**
3. Click **"Register a new application"**
4. Fill in the application details:
   - **Name**: Jupiter (or your preferred name)
   - **Redirect URI**: Your callback URL (see below)
   - Save the application

### 2. Configure Redirect URIs

**Development:**
```
http://localhost:3000/auth/nationbuilder/callback
```

**Production:**
```
https://your-app-name.fly.dev/auth/nationbuilder/callback
```

### 3. Environment Variables

Set the following environment variables:

```bash
# Required OAuth credentials
NATIONBUILDER_CLIENT_ID=your_client_id
NATIONBUILDER_CLIENT_SECRET=your_client_secret
NATIONBUILDER_REDIRECT_URI=your_redirect_uri
NATIONBUILDER_NATION_SLUG=your_nation_slug
```

**Finding your credentials:**
- **Client ID & Secret**: Available after registering your OAuth application
- **Nation Slug**: Your subdomain (e.g., `yournation` from `yournation.nationbuilder.com`)

## Testing OAuth Integration

### Automated Testing

The test suite covers OAuth business logic while mocking external API calls:

```bash
# Run OAuth-related tests
bin/rspec spec/controllers/nationbuilder_auth_controller_spec.rb
bin/rspec spec/services/nationbuilder_*_spec.rb
```

### Manual Testing

**Important**: OAuth functionality requires manual testing in a staging environment with real NationBuilder credentials.

1. **Set up staging environment** with proper credentials
2. **Test OAuth flow:**
   ```
   Visit: /auth/nationbuilder
   → Redirects to NationBuilder consent screen
   → Complete authorization
   → Redirects back to application
   → Verify user session and token storage
   ```
3. **Test admin features:**
   - Visit `/system/oauth_status` to check integration status
   - Verify token refresh functionality
   - Test error handling and graceful degradation

## Architecture

### Core Components

- **NationbuilderAuthController**: Handles OAuth callbacks
- **NationbuilderTokenExchangeService**: Exchanges authorization codes for tokens
- **NationbuilderTokenRefreshService**: Automatically refreshes expired tokens
- **NationbuilderApiClient**: Makes authenticated requests with automatic token refresh
- **NationbuilderUserService**: Syncs user profiles from NationBuilder

### Error Handling

The system includes comprehensive error handling:

- **Classified Errors**: `NationbuilderOauthErrors` for structured error types
- **Audit Logging**: All OAuth events tracked for debugging
- **Graceful Degradation**: Application continues with reduced functionality during API failures
- **Automatic Retry**: Exponential backoff for transient failures

### Token Management

- **Secure Storage**: Tokens encrypted using Rails 8 built-in encryption
- **Automatic Refresh**: Background jobs refresh tokens before expiration
- **Cleanup**: Expired tokens removed automatically

## Deployment

### Fly.io Deployment

Set production secrets:

```bash
# OAuth credentials
fly secrets set NATIONBUILDER_CLIENT_ID="your_client_id"
fly secrets set NATIONBUILDER_CLIENT_SECRET="your_client_secret"
fly secrets set NATIONBUILDER_REDIRECT_URI="https://your-app-name.fly.dev/auth/nationbuilder/callback"
fly secrets set NATIONBUILDER_NATION_SLUG="your_nation_slug"

# Rails configuration
fly secrets set SECRET_KEY_BASE="$(openssl rand -hex 64)"
fly secrets set RAILS_MASTER_KEY="your_master_key_content"
```

### Verification

After deployment:

1. Visit your application
2. Click "Sign in with NationBuilder"
3. Complete OAuth flow
4. Check `/system/oauth_status` for integration health
5. Monitor logs: `fly logs`

## Troubleshooting

### Common Issues

**"Invalid redirect URI" error:**
- Verify redirect URI matches exactly between NationBuilder and environment variables
- Check for trailing slashes or case differences
- Ensure HTTPS in production

**Token refresh failures:**
- Check nation slug is correct
- Verify client credentials are valid
- Monitor background job logs

**SSL/Certificate errors:**
- Ensure production environment uses HTTPS
- Check certificate validity
- Verify NationBuilder can reach your callback URL

### Debug Tools

```bash
# Check OAuth status
curl https://your-app.fly.dev/system/oauth_status

# View application logs
fly logs

# Check environment variables
fly secrets list

# Debug OAuth in Rails console
bin/rails console
> NationbuilderApiClient.new.test_connection
```

### Getting Help

- Review audit logs at `/system/oauth_status`
- Check NationBuilder API documentation
- Monitor application logs for detailed error messages
- Test with different user accounts and permissions