class NationbuilderToken < ApplicationRecord
  belongs_to :user

  # Rails 7+ built-in encryption for sensitive fields
  encrypts :access_token
  encrypts :refresh_token

  validates :access_token, :refresh_token, :expires_at, presence: true

  # Scopes for finding tokens in various states
  scope :expired, -> { where("expires_at <= ?", Time.current) }
  scope :expiring_soon, ->(buffer_minutes = 5) { where("expires_at <= ? AND expires_at > ?", Time.current + buffer_minutes.minutes, Time.current) }
  scope :valid_for_api, -> { where("expires_at > ?", Time.current) }
  scope :needs_refresh, ->(buffer_minutes = 5) { where("expires_at <= ?", Time.current + buffer_minutes.minutes) }

  # Check if the token is expired
  def expired?
    expires_at <= Time.current
  end

  # Check if the token is close to expiring (within 5 minutes)
  def expiring_soon?(buffer_minutes = 5)
    expires_at <= Time.current + buffer_minutes.minutes
  end

  # Check if the token is valid (not expired and has required fields)
  def valid_for_api_use?
    access_token.present? && !expired?
  end

  # Check if the token needs refresh (expired or expiring soon)
  def needs_refresh?(buffer_minutes = 5)
    expired? || expiring_soon?(buffer_minutes)
  end

  # Refresh the token using the refresh service
  def refresh!
    service = NationbuilderTokenRefreshService.new(
      client_id: ENV["NATIONBUILDER_CLIENT_ID"],
      client_secret: ENV["NATIONBUILDER_CLIENT_SECRET"]
    )
    service.refresh_token(self)
  end

  # Get the time remaining until expiration
  def time_until_expiry
    return 0 if expired?
    expires_at - Time.current
  end

  # Update tokens after refresh
  def update_tokens!(access_token:, refresh_token:, expires_in:, scope:, raw_response: nil)
    update!(access_token: access_token,
            refresh_token: refresh_token,
            expires_at: Time.current + expires_in.seconds,
            scope: scope,
            raw_response: raw_response)
  end
end
