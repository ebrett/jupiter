class Session < ApplicationRecord
  belongs_to :user

  # Session duration constants
  DEFAULT_SESSION_DURATION = 2.weeks
  REMEMBER_ME_DURATION = 6.months

  def expired?
    return false unless created_at

    duration = remember_me? ? REMEMBER_ME_DURATION : DEFAULT_SESSION_DURATION
    created_at < duration.ago
  end

  def expires_at
    return nil unless created_at

    duration = remember_me? ? REMEMBER_ME_DURATION : DEFAULT_SESSION_DURATION
    created_at + duration
  end

  def time_until_expiry
    return nil unless created_at
    return nil if expired?

    expires_at - Time.current
  end
end
