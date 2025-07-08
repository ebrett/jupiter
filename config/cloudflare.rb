# Cloudflare Turnstile Configuration
#
# This file configures Cloudflare Turnstile integration for challenge handling.
#
# Environment Variables Required:
# - CLOUDFLARE_TURNSTILE_SITE_KEY: Public site key from Cloudflare dashboard
# - CLOUDFLARE_TURNSTILE_SECRET_KEY: Secret key from Cloudflare dashboard
#
# Rails Credentials Required:
# - cloudflare_turnstile_secret_key: Secret key (alternative to env var)
#
# Setup Instructions:
# 1. Sign up for Cloudflare Turnstile at https://dash.cloudflare.com/
# 2. Create a new site and get your site key and secret key
# 3. Add CLOUDFLARE_TURNSTILE_SITE_KEY to your environment variables
# 4. Add secret key using either:
#    - Environment variable: CLOUDFLARE_TURNSTILE_SECRET_KEY
#    - Rails credentials: bin/rails credentials:edit and add:
#      cloudflare_turnstile_secret_key: your_secret_key_here

module CloudflareConfig
  # Get the Turnstile site key from environment
  def self.turnstile_site_key
    ENV["CLOUDFLARE_TURNSTILE_SITE_KEY"]
  end

  # Get the Turnstile secret key from environment or credentials
  def self.turnstile_secret_key
    ENV["CLOUDFLARE_TURNSTILE_SECRET_KEY"] ||
      Rails.application.credentials.cloudflare_turnstile_secret_key
  end

  # Check if Turnstile is properly configured
  def self.configured?
    turnstile_site_key.present? && turnstile_secret_key.present?
  end

  # Turnstile API endpoint for verification
  def self.verification_endpoint
    "https://challenges.cloudflare.com/turnstile/v0/siteverify"
  end
end
