class NationbuilderTokenRefreshJob < ApplicationJob
  queue_as :default

  # Refresh a specific user's token
  def perform(user_id)
    user = User.find_by(id: user_id)
    return unless user

    nationbuilder_token = user.nationbuilder_tokens.first
    return unless nationbuilder_token&.needs_refresh?

    Rails.logger.info "Proactively refreshing token for user #{user_id}"
    
    success = nationbuilder_token.refresh!
    
    if success
      Rails.logger.info "Successfully refreshed token for user #{user_id}"
    else
      Rails.logger.error "Failed to refresh token for user #{user_id}"
      # Could trigger notifications or alerts here
    end
  end

  # Class method to enqueue refresh jobs for all users with expiring tokens
  def self.enqueue_for_expiring_tokens(buffer_minutes = 30)
    expiring_tokens = NationbuilderToken.joins(:user)
                                       .where('expires_at <= ?', Time.current + buffer_minutes.minutes)
                                       .where('expires_at > ?', Time.current)
                                       .includes(:user)

    Rails.logger.info "Found #{expiring_tokens.count} tokens expiring within #{buffer_minutes} minutes"

    expiring_tokens.find_each do |token|
      perform_later(token.user_id)
    end
    
    nil # Ensure no return value interferes with logging
  end

  # Class method to schedule periodic refresh checks
  def self.schedule_periodic_refresh
    # This would typically be called by a cron job or scheduler like whenever gem
    # For example, run every 15 minutes to check for tokens expiring in the next 30 minutes
    enqueue_for_expiring_tokens(30)
  end
end