class Account::NationbuilderLinksController < ApplicationController
  before_action :authenticate!

  def show
    @user = Current.user
    @has_nationbuilder = @user.nationbuilder_uid.present?
    @nationbuilder_token = @user.nationbuilder_tokens.active.first if @has_nationbuilder
  end

  def status
    @user = Current.user
    render json: {
      linked: @user.nationbuilder_uid.present?,
      nationbuilder_uid: @user.nationbuilder_uid,
      last_synced: @user.nationbuilder_tokens.active.first&.updated_at
    }
  end

  def create
    # Redirect to NationBuilder OAuth flow with linking intent
    session[:linking_nationbuilder] = true
    redirect_to "/auth/nationbuilder", allow_other_host: false
  end

  def destroy
    @user = Current.user

    if @user.email_password_user?
      # Only unlink if user has email/password auth set up
      @user.update!(nationbuilder_uid: nil)
      @user.nationbuilder_tokens.destroy_all

      flash[:notice] = "NationBuilder account unlinked successfully."
    else
      flash[:alert] = "Cannot unlink NationBuilder account without an email/password login."
    end

    redirect_to account_nationbuilder_link_path
  end
end
