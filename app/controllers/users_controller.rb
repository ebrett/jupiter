class UsersController < ApplicationController
  before_action :set_user, only: [ :show, :update, :destroy, :manage_roles, :assign_role, :remove_role ]

  def index
    @q = policy_scope(User).ransack(params[:q])
    @users = @q.result.includes(:roles).page(params[:page]).per(25)
    @roles = Role.all

    authorize User, :index?
  end

  def show
    authorize @user, :show?
  end

  def update
    authorize @user, :update?

    if @user.update(user_params)
      redirect_to user_path(@user), notice: "User was successfully updated."
    else
      render :show, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @user, :destroy?

    if @user.destroy
      redirect_to users_path, notice: "User was successfully deleted."
    else
      redirect_to users_path, alert: "Unable to delete user."
    end
  end

  def manage_roles
    authorize @user, :update?
    @available_roles = Role.all
    @user_roles = @user.roles
  end

  def assign_role
    authorize @user, :update?

    role = Role.find(params[:role_id])

    if @user.add_role(role.name)
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("user_roles_#{@user.id}", partial: "users/user_roles", locals: { user: @user }) }
        format.html { redirect_to manage_roles_user_path(@user), notice: "Role '#{role.name.humanize}' was successfully assigned to #{@user.email_address}." }
      end
    else
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("user_roles_#{@user.id}", partial: "users/user_roles", locals: { user: @user }) }
        format.html { redirect_to manage_roles_user_path(@user), alert: "Unable to assign role." }
      end
    end
  end

  def remove_role
    authorize @user, :update?

    role = Role.find(params[:role_id])

    if @user.remove_role(role.name)
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("user_roles_#{@user.id}", partial: "users/user_roles", locals: { user: @user }) }
        format.html { redirect_to manage_roles_user_path(@user), notice: "Role '#{role.name.humanize}' was successfully removed from #{@user.email_address}." }
      end
    else
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("user_roles_#{@user.id}", partial: "users/user_roles", locals: { user: @user }) }
        format.html { redirect_to manage_roles_user_path(@user), alert: "Unable to remove role." }
      end
    end
  end

  def bulk_assign_roles
    authorize User, :update?
    # Implement bulk role assignment logic here
    redirect_to users_path, notice: "Bulk role assignment not yet implemented."
  end

  private
    def set_user
      @user = User.find(params[:id])
    end

    def user_params
      params.require(:user).permit(:email_address, :first_name, :last_name, role_ids: [])
    end
end
