class NationbuilderProfileSyncJob < ApplicationJob
  queue_as :default

  # Retry with exponential backoff for transient failures
  retry_on StandardError, wait: :polynomially_longer, attempts: 3

  # Don't retry on permanent failures
  discard_on ActiveRecord::RecordNotFound

  def perform(user_id)
    user = User.find(user_id)

    # Skip if user no longer has NationBuilder integration
    return unless user.nationbuilder_user?

    # Perform the sync
    sync_service = NationbuilderProfileSyncService.new(user: user)
    success = sync_service.sync_profile_data

    if success
      Rails.logger.info "Successfully synced NationBuilder profile for user #{user_id}"
    else
      Rails.logger.warn "Failed to sync NationBuilder profile for user #{user_id}"
    end
  end
end
