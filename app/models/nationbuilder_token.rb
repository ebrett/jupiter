class NationbuilderToken < ApplicationRecord
  belongs_to :user

  # Rails 7+ built-in encryption for sensitive fields
  encrypts :access_token
  encrypts :refresh_token

  validates :access_token, :refresh_token, :expires_at, presence: true

  # Token rotation tracking
  before_create :set_token_version
  after_update :log_token_update

  # Current token version for rotation tracking
  CURRENT_TOKEN_VERSION = 1

  # Scopes for finding tokens in various states
  scope :expired, -> { where("expires_at <= ?", Time.current) }
  scope :expiring_soon, ->(buffer_minutes = 5) { where("expires_at <= ? AND expires_at > ?", Time.current + buffer_minutes.minutes, Time.current) }
  scope :valid_for_api, -> { where("expires_at > ?", Time.current) }
  scope :needs_refresh, ->(buffer_minutes = 5) { where("expires_at <= ?", Time.current + buffer_minutes.minutes) }
  scope :active, -> { where(rotated_at: nil) }
  scope :rotated, -> { where.not(rotated_at: nil) }
  scope :current_version, -> { where(version: CURRENT_TOKEN_VERSION) }

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
    access_token.present? && !expired? && !rotated?
  end

  # Check if the token needs refresh (expired or expiring soon)
  def needs_refresh?(buffer_minutes = 5)
    expired? || expiring_soon?(buffer_minutes)
  end

  # Check if token has been rotated
  def rotated?
    rotated_at.present?
  end

  # Check if token should be rotated based on age and usage
  def should_rotate?
    return false if rotated?

    # Rotate if token is older than 24 hours
    age_threshold = 24.hours
    created_at < Time.current - age_threshold
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

  # Rotate the token for enhanced security
  def rotate!(new_refresh_token: nil)
    transaction do
      # Mark current token as rotated
      update!(rotated_at: Time.current)

      # Create new token with rotated refresh token
      new_token = user.nationbuilder_tokens.create!(
        access_token: access_token, # Keep same access token temporarily
        refresh_token: new_refresh_token || generate_new_refresh_token,
        expires_at: expires_at,
        scope: scope,
        version: CURRENT_TOKEN_VERSION,
        raw_response: raw_response&.merge(rotated_from: id)
      )

      # Log the rotation
      log_token_rotation(new_token)

      new_token
    end
  end

  # Clean up old rotated tokens
  def self.cleanup_rotated_tokens(older_than: 7.days)
    rotated.where("rotated_at < ?", Time.current - older_than).delete_all
  end

  # Find the most recent active token for a user
  def self.current_for_user(user)
    where(user: user).active.order(created_at: :desc).first
  end

  private

  def set_token_version
    self.version ||= CURRENT_TOKEN_VERSION
  end

  def log_token_update
    return unless saved_change_to_access_token? || saved_change_to_refresh_token?

    Rails.logger.info({
      event: "nationbuilder_token_updated",
      token_id: id,
      user_id: user_id,
      expires_at: expires_at,
      version: version,
      rotated: rotated?
    }.to_json)
  end

  def log_token_rotation(new_token)
    Rails.logger.info({
      event: "nationbuilder_token_rotated",
      old_token_id: id,
      new_token_id: new_token.id,
      user_id: user_id,
      rotation_reason: "scheduled_rotation"
    }.to_json)

    # Audit log the rotation
    if defined?(NationbuilderAuditLogger)
      audit_logger = NationbuilderAuditLogger.new
      audit_logger.log_token_event(:token_rotated,
        user: user,
        details: {
          old_token_id: id,
          new_token_id: new_token.id,
          rotation_timestamp: Time.current,
          rotation_reason: "scheduled_rotation"
        }
      )
    end
  end

  def generate_new_refresh_token
    # Generate a secure random refresh token
    # In production, this should trigger a refresh with the OAuth provider
    SecureRandom.hex(32)
  end
end
