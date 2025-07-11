class CloudflareChallenge < ApplicationRecord
  belongs_to :user, optional: true

  validates :challenge_id, presence: true, uniqueness: true
  validates :oauth_state, presence: true
  validates :challenge_type, inclusion: { in: %w[turnstile browser_challenge rate_limit] }

  scope :active, -> { where("expires_at > ?", Time.current) }
  scope :for_session, ->(session_id) { where(session_id: session_id) }

  def expired?
    expires_at < Time.current
  end

  def challenge_url
    Rails.application.routes.url_helpers.cloudflare_challenge_path(challenge_id)
  end

  def manual_verification?
    challenge_type == "browser_challenge"
  end

  def verification_completed?
    # For manual verification, we consider it completed if the challenge has been touched
    # after creation (indicating user has attempted manual verification)
    manual_verification? && updated_at > created_at
  end
end
