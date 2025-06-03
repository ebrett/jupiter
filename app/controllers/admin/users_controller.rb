class Admin::UsersController < Admin::BaseController
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
      redirect_to admin_user_path(@user), notice: "User was successfully updated."
    else
      render :show, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @user, :destroy?

    if @user.destroy
      redirect_to admin_users_path, notice: "User was successfully deleted."
    else
      redirect_to admin_users_path, alert: "Unable to delete user."
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
        format.turbo_stream { render turbo_stream: turbo_stream.replace("user_roles_#{@user.id}", partial: "admin/users/user_roles", locals: { user: @user }) }
        format.html { redirect_to manage_roles_admin_user_path(@user), notice: "Role '#{role.name.humanize}' was successfully assigned to #{@user.email_address}." }
      end
    else
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("user_roles_#{@user.id}", partial: "admin/users/user_roles", locals: { user: @user }) }
        format.html { redirect_to manage_roles_admin_user_path(@user), alert: "Unable to assign role." }
      end
    end
  end

  def remove_role
    authorize @user, :update?

    role = Role.find(params[:role_id])

    if @user.remove_role(role.name)
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("user_roles_#{@user.id}", partial: "admin/users/user_roles", locals: { user: @user }) }
        format.html { redirect_to manage_roles_admin_user_path(@user), notice: "Role '#{role.name.humanize}' was successfully removed from #{@user.email_address}." }
      end
    else
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("user_roles_#{@user.id}", partial: "admin/users/user_roles", locals: { user: @user }) }
        format.html { redirect_to manage_roles_admin_user_path(@user), alert: "Unable to remove role." }
      end
    end
  end

  def bulk_assign_roles
    authorize User, :index?

    user_ids = params[:user_ids] || []
    role_ids = params[:role_ids] || []

    if user_ids.empty? || role_ids.empty?
      redirect_to admin_users_path, alert: "Please select users and roles."
      return
    end

    users = policy_scope(User).where(id: user_ids)
    roles = Role.where(id: role_ids)

    success_count = 0
    users.each do |user|
      roles.each do |role|
        if user.add_role(role.name)
          success_count += 1
        end
      end
    end

    redirect_to admin_users_path, notice: "Successfully assigned #{success_count} role(s) to #{users.count} user(s)."
  end

  private

  def set_user
    @user = policy_scope(User).find(params[:id])
  end

  def user_params
    params.require(:user).permit(:email_address, :first_name, :last_name)
  end
end
