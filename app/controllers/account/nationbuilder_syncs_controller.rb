class Account::NationbuilderSyncsController < ApplicationController
  before_action :ensure_nationbuilder_user

  def create
    # Trigger sync job
    NationbuilderProfileSyncJob.perform_later(Current.user.id)

    redirect_to user_path(Current.user), notice: "NationBuilder profile sync has been initiated."
  end

  private

  def ensure_nationbuilder_user
    unless Current.user.nationbuilder_user?
      redirect_to user_path(Current.user), alert: "You don't have a connected NationBuilder account."
    end
  end
end
