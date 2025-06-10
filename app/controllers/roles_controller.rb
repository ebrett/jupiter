class RolesController < ApplicationController
  before_action :set_role, only: [ :show, :edit, :update, :users_with_role ]

  def index
    @roles = policy_scope(Role)
    authorize Role, :index?
  end

  def show
    authorize @role, :show?
  end

  def edit
    authorize @role, :update?
  end

  def update
    authorize @role, :update?
    if @role.update(role_params)
      redirect_to role_path(@role), notice: "Role was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def users_with_role
    authorize @role, :show?
    @users = @role.users
  end

  private
    def set_role
      @role = Role.find(params[:id])
    end

    def role_params
      params.require(:role).permit(:description)
    end
end
