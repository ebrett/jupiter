# System Test OAuth Stubs
#
# This file provides WebMock stubs for OAuth-related endpoints to prevent
# system tests from making actual HTTP requests during test runs.

require 'webmock/rspec'

RSpec.configure do |config|
  config.before(:each, type: :system) do
    # Disable NationBuilder OAuth for all system tests to avoid timeouts
    # System tests should focus on UI/UX, not OAuth integration
    nationbuilder_flag = FeatureFlag.find_or_create_by!(name: 'nationbuilder_signin') do |flag|
      flag.description = 'NationBuilder OAuth feature flag'
      flag.enabled = false
    end
    nationbuilder_flag.update!(enabled: false)

    # Disable Cloudflare challenge handling for system tests
    cloudflare_flag = FeatureFlag.find_or_create_by!(name: 'cloudflare_challenge_handling') do |flag|
      flag.description = 'Cloudflare challenge handling feature flag'
      flag.enabled = false
    end
    cloudflare_flag.update!(enabled: false)

    # Allow local connections for Selenium WebDriver, but stub external OAuth requests
    WebMock.allow_net_connect!(net_http_connect_on_start: true, allow_localhost: true)
    WebMock.stub_request(:any, /nationbuilder\.com/).to_timeout
    WebMock.stub_request(:any, /challenges\.cloudflare\.com/).to_timeout
  end

  config.after(:each, type: :system) do
    # Reset WebMock but keep allowing local connections for subsequent tests
    WebMock.reset!
  end
end
