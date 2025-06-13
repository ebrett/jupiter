class NationbuilderProfileSyncService
  include NationbuilderOauthErrors

  def initialize(user:)
    @user = user
  end

  def sync_profile_data
    return false unless should_sync?

    # Get valid access token
    token = get_valid_token
    return false unless token

    # Fetch latest profile data from NationBuilder
    profile_data = fetch_profile_data(token.access_token)
    return false unless profile_data

    # Update user profile with latest data
    update_user_profile(profile_data)

    true
  rescue StandardError => e
    Rails.logger.error "Failed to sync NationBuilder profile for user #{@user.id}: #{e.message}"
    false
  end

  private

  attr_reader :user

  def should_sync?
    # Only sync if user has NationBuilder integration
    user.nationbuilder_user? && user.nationbuilder_tokens.any?
  end

  def get_valid_token
    token = user.nationbuilder_tokens.first
    return nil unless token

    # Refresh token if needed with locking to prevent race conditions
    if token.needs_refresh?
      token.with_lock do
        # Double-check after acquiring lock in case another process refreshed it
        token.reload
        token.refresh! if token.needs_refresh?
      end
    end

    token.valid_for_api_use? ? token : nil
  rescue StandardError => e
    Rails.logger.error "Failed to get valid token for user #{user.id}: #{e.message}"
    nil
  end

  def fetch_profile_data(access_token)
    user_service = NationbuilderUserService.new(access_token: access_token)
    user_service.fetch_user_profile
  rescue StandardError => e
    Rails.logger.error "Failed to fetch profile data for user #{user.id}: #{e.message}"
    nil
  end

  def update_user_profile(profile_data)
    # Wrap all database operations in a transaction
    User.transaction do
      # Update basic fields if they're blank (don't overwrite existing data)
      user.first_name = profile_data[:first_name] if user.first_name.blank?
      user.last_name = profile_data[:last_name] if user.last_name.blank?

      # Always update the profile data to get latest tags and metadata
      user.update_nationbuilder_profile_data!(profile_data)

      user.save! if user.changed?
    end
  end
end
