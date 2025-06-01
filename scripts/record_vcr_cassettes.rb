#!/usr/bin/env ruby
# Script to help record VCR cassettes for NationBuilder sandbox integration

puts <<~INSTRUCTIONS
  VCR Cassette Recording Script for NationBuilder Sandbox
  ======================================================

  This script helps you record real API interactions with the NationBuilder sandbox.

  Prerequisites:
  1. Set up your NationBuilder sandbox environment variables:
     export NATIONBUILDER_CLIENT_ID="your_sandbox_client_id"
     export NATIONBUILDER_CLIENT_SECRET="your_sandbox_client_secret"
     export NATIONBUILDER_REDIRECT_URI="your_ngrok_callback_url"
     export NATIONBUILDER_NATION_SLUG="your_sandbox_nation_slug"

  2. Get a valid authorization code by completing the OAuth flow:
  #{'   '}
     a) Start Rails server and ngrok:
        # Terminal 1: Start Rails server
        rails server
  #{'      '}
        # Terminal 2: Start ngrok to create public HTTPS URL
        ngrok http 3000
        # This gives you a URL like: https://abc123.ngrok.io
  #{'   '}
     b) Update your redirect URI environment variable:
        export NATIONBUILDER_REDIRECT_URI="https://abc123.ngrok.io/auth/nationbuilder/callback"
  #{'   '}
     c) Initiate OAuth flow by visiting:
        http://localhost:3000/auth/nationbuilder
  #{'      '}
        This redirects you to NationBuilder's authorization page like:
        https://yoursandbox.nationbuilder.com/oauth/authorize?client_id=...&scope=default
  #{'   '}
     d) Complete authorization on NationBuilder's consent screen:
        - Click "Allow" or "Authorize" to grant permission
  #{'      '}
     e) Capture the authorization code from the callback URL:
        The callback URL will look like:
        https://abc123.ngrok.io/auth/nationbuilder/callback?code=AUTHORIZATION_CODE_HERE&state=session_id
  #{'      '}
        Copy the value of the 'code' parameter (it looks like a long alphanumeric string)

  Steps to record cassettes:

  1. Enable the pending tests and update with real authorization code:
     spec/requests/nationbuilder_sandbox_integration_spec.rb
  #{'   '}
     a) Change all 'xit' back to 'it' to enable the tests
     b) Update the authorization code:
        Change:
          let(:authorization_code) { 'valid_sandbox_authorization_code' }
        To:
          let(:authorization_code) { 'YOUR_REAL_CODE_FROM_STEP_2e' }

  2. If you have a valid access token, update:
       let(:access_token) { 'valid_sandbox_access_token' }
     To:
       let(:access_token) { 'YOUR_REAL_ACCESS_TOKEN_HERE' }

  3. Delete any existing cassettes you want to re-record:
     rm spec/fixtures/vcr_cassettes/nationbuilder/*.yml

  4. Run the tests to record new cassettes:
     bundle exec rspec spec/requests/nationbuilder_sandbox_integration_spec.rb

  5. Verify the cassettes were created and sensitive data was filtered:
     ls -la spec/fixtures/vcr_cassettes/nationbuilder/
     cat spec/fixtures/vcr_cassettes/nationbuilder/oauth_token_exchange_success.yml

  6. After recording, restore the test file for VCR playback:
     a) Change all 'it' back to 'xit' to mark tests as pending again
     b) Restore dummy tokens:
        let(:authorization_code) { 'valid_sandbox_authorization_code' }
        let(:access_token) { 'valid_sandbox_access_token' }

  Important Notes:
  - Authorization codes expire quickly (usually within 10 minutes)
  - Authorization codes are one-time use only - each code can only be exchanged once
  - You need ngrok because NationBuilder requires HTTPS callback URLs
  - The authorization code is different every time you go through the OAuth flow
  - VCR automatically filters sensitive data like tokens and secrets
  - Real tokens are replaced with placeholders like <ACCESS_TOKEN>
  - Never commit files containing real tokens to git
  - Cassettes may need periodic re-recording as tokens expire

INSTRUCTIONS

# Check if environment variables are set
required_vars = %w[NATIONBUILDER_CLIENT_ID NATIONBUILDER_CLIENT_SECRET NATIONBUILDER_REDIRECT_URI NATIONBUILDER_NATION_SLUG]
missing_vars = required_vars.select { |var| ENV[var].nil? || ENV[var].empty? }

if missing_vars.any?
  puts "❌ Missing required environment variables:"
  missing_vars.each { |var| puts "   - #{var}" }
  puts "\n   Set these variables and try again."
  exit 1
else
  puts "✅ All required environment variables are set:"
  required_vars.each { |var| puts "   - #{var}: #{ENV[var][0..10]}..." }
end

puts "\n📝 Ready to record VCR cassettes!"
puts "   Follow the steps above to capture real API interactions."
