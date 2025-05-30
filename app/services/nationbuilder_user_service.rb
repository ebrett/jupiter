require 'ostruct'
require 'net/http'
require 'uri'
require 'json'

class NationbuilderUserService
  include NationbuilderOauthErrors

  # Define custom error classes
  class UserCreationError < StandardError; end

  def initialize(access_token:)
    @access_token = access_token
    @nation_slug = ENV["NATIONBUILDER_NATION_SLUG"]
    
    raise ConfigurationError, "NATIONBUILDER_NATION_SLUG environment variable is not set" if @nation_slug.nil? || @nation_slug.strip.empty?
    raise ArgumentError, "Access token is required" if @access_token.blank?
  end

  def fetch_user_profile
    response = make_request("/api/v1/people/me")
    
    if response.success?
      parse_user_data(response.body)
    else
      raise ApiError, "Failed to fetch user profile: #{response.status} #{response.body}"
    end
  end

  def find_or_create_user(profile_data)
    # Try to find existing user by NationBuilder UID first
    user = User.find_by(nationbuilder_uid: profile_data[:id].to_s)
    
    if user
      # Update existing user with latest profile data
      update_user_profile(user, profile_data)
      user
    else
      # Check if user exists by email
      existing_user = User.find_by(email_address: profile_data[:email])
      
      if existing_user
        # Link existing account to NationBuilder
        existing_user.update!(nationbuilder_uid: profile_data[:id].to_s)
        update_user_profile(existing_user, profile_data)
        existing_user
      else
        # Create new user from NationBuilder profile
        create_user_from_profile(profile_data)
      end
    end
  end

  private

  def make_request(path)
    uri = URI("https://#{@nation_slug}.nationbuilder.com#{path}")
    
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    
    request = Net::HTTP::Get.new(uri)
    request["Authorization"] = "Bearer #{@access_token}"
    request["Accept"] = "application/json"
    
    response = http.request(request)
    
    OpenStruct.new(
      success?: response.code.to_i.between?(200, 299),
      status: response.code.to_i,
      body: response.body
    )
  rescue StandardError => e
    Rails.logger.error "NationBuilder API request failed: #{e.message}"
    raise NetworkError, "Network error while fetching user profile: #{e.message}"
  end

  def parse_user_data(response_body)
    data = JSON.parse(response_body, symbolize_names: true)
    
    # Handle NationBuilder V1 API response structure  
    # V1 API wraps the person data in a 'person' key
    person_data = data[:person] || data[:data] || data
    
    {
      id: person_data[:id],
      email: person_data[:email],
      first_name: person_data[:first_name],
      last_name: person_data[:last_name],
      full_name: "#{person_data[:first_name]} #{person_data[:last_name]}".strip,
      phone: person_data[:phone],
      tags: person_data[:tags],
      raw_data: person_data
    }
  rescue JSON::ParserError => e
    Rails.logger.error "Failed to parse NationBuilder user data: #{e.message}"
    raise ApiError, "Invalid response format from NationBuilder API"
  end

  def create_user_from_profile(profile_data)
    # Generate a secure random password for OAuth users
    temp_password = SecureRandom.alphanumeric(32)
    
    User.create!(
      email_address: profile_data[:email],
      password: temp_password,
      password_confirmation: temp_password,
      nationbuilder_uid: profile_data[:id].to_s,
      first_name: profile_data[:first_name],
      last_name: profile_data[:last_name]
    )
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error "Failed to create user from NationBuilder profile: #{e.message}"
    raise UserCreationError, "Unable to create user account: #{e.message}"
  end

  def update_user_profile(user, profile_data)
    # Only update non-sensitive fields from NationBuilder
    user.update!(
      first_name: profile_data[:first_name],
      last_name: profile_data[:last_name]
      # Don't update email_address to avoid conflicts
    )
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.warn "Failed to update user profile from NationBuilder: #{e.message}"
    # Don't raise error for profile updates - user creation/login should still succeed
  end
end