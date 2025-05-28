class NationbuilderToken < ApplicationRecord
  belongs_to :user

  # Rails 7+ built-in encryption for sensitive fields
  encrypts :access_token
  encrypts :refresh_token

  validates :access_token, :refresh_token, :expires_at, presence: true

  # Check if the token is expired
  def expired?
    expires_at <= Time.current
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
