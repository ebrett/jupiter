require 'vcr'

VCR.configure do |config|
  config.cassette_library_dir = "spec/fixtures/vcr_cassettes"
  config.hook_into :webmock
  config.ignore_localhost = true
  config.default_cassette_options = {
    record: :once,
    match_requests_on: [ :method, :uri, :body ]
  }

  # Filter sensitive data
  config.filter_sensitive_data('<NATIONBUILDER_CLIENT_ID>') { ENV['NATIONBUILDER_CLIENT_ID'] }
  config.filter_sensitive_data('<NATIONBUILDER_CLIENT_SECRET>') { ENV['NATIONBUILDER_CLIENT_SECRET'] }
  config.filter_sensitive_data('<ACCESS_TOKEN>') { |interaction|
    if interaction.response.body.include?('access_token')
      JSON.parse(interaction.response.body)['access_token']
    end
  }
  config.filter_sensitive_data('<REFRESH_TOKEN>') { |interaction|
    if interaction.response.body.include?('refresh_token')
      JSON.parse(interaction.response.body)['refresh_token']
    end
  }

  # Configure for different test environments
  config.configure_rspec_metadata!
end
