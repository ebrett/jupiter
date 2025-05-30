# VCR Cassettes for NationBuilder Integration Tests

This directory contains VCR cassettes that record HTTP interactions with the NationBuilder sandbox API.

## Recording New Cassettes

To record new VCR cassettes with real sandbox data:

1. **Set up your environment variables** for the NationBuilder sandbox:
   ```bash
   export NATIONBUILDER_CLIENT_ID="your_sandbox_client_id"
   export NATIONBUILDER_CLIENT_SECRET="your_sandbox_client_secret"
   export NATIONBUILDER_REDIRECT_URI="your_ngrok_callback_url"
   export NATIONBUILDER_NATION_SLUG="your_sandbox_nation_slug"
   ```

2. **Get a valid authorization code** by completing the OAuth flow:
   
   a) **Start Rails server and ngrok:**
   ```bash
   # Terminal 1: Start Rails server
   rails server
   
   # Terminal 2: Start ngrok to create public HTTPS URL
   ngrok http 3000
   # This gives you a URL like: https://abc123.ngrok.io
   ```
   
   b) **Update your redirect URI environment variable:**
   ```bash
   export NATIONBUILDER_REDIRECT_URI="https://abc123.ngrok.io/auth/nationbuilder/callback"
   ```
   
   c) **Initiate OAuth flow** by visiting:
   ```
   http://localhost:3000/auth/nationbuilder
   ```
   This redirects you to NationBuilder's authorization page.
   
   d) **Complete authorization** on NationBuilder's consent screen:
   - Click "Allow" or "Authorize" to grant permission
   
   e) **Capture the authorization code** from the callback URL:
   ```
   https://abc123.ngrok.io/auth/nationbuilder/callback?code=AUTHORIZATION_CODE_HERE&state=session_id
   ```
   Copy the value of the `code` parameter (long alphanumeric string)

3. **Enable tests and update with real tokens**:
   - Change all `xit` to `it` in `spec/requests/nationbuilder_sandbox_integration_spec.rb`
   - Replace `'valid_sandbox_authorization_code'` with your actual authorization code
   - Replace `'valid_sandbox_access_token'` with a real access token (if available)

4. **Run the tests to record cassettes**:
   ```bash
   bundle exec rspec spec/requests/nationbuilder_sandbox_integration_spec.rb
   ```

5. **Clean up sensitive data**:
   - VCR is configured to automatically filter sensitive data
   - Review the generated cassettes to ensure no real tokens are exposed
   - Real tokens will be replaced with `<ACCESS_TOKEN>` and `<REFRESH_TOKEN>`

6. **Restore test file for VCR playback**:
   - Change all `it` back to `xit` to mark tests as pending again
   - Restore dummy tokens for future VCR playback

## Important Notes

- **Authorization codes expire quickly** (usually within 10 minutes)
- **Authorization codes are one-time use only** - each code can only be exchanged once
- **You need ngrok** because NationBuilder requires HTTPS callback URLs
- **The authorization code is different every time** you go through the OAuth flow
- **Never commit real tokens** - VCR filtering should handle this automatically
- **Cassettes expire** - Re-record periodically as sandbox tokens expire
- **Sandbox vs Production** - These tests only work with sandbox credentials
- **Rate Limiting** - Be mindful of NationBuilder API rate limits when recording

## Cassette Files

- `oauth_token_exchange_success.yml` - Successful OAuth token exchange
- `oauth_token_exchange_invalid_code.yml` - Failed token exchange with invalid code
- `user_profile_fetch_success.yml` - Successful user profile fetch
- `user_profile_fetch_expired_token.yml` - Failed profile fetch with expired token
- `full_oauth_flow_success.yml` - Complete OAuth redirect flow test