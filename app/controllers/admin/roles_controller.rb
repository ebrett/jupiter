class Admin::RolesController < Admin::BaseController
  before_action :set_role, only: [ :show, :edit, :update ]

  def index
    @roles = policy_scope(Role).includes(:users).order(:name)
    @role_stats = calculate_role_stats

    authorize Role, :index?
  end

  def show
    authorize @role, :show?
    @users_with_role = @role.users.includes(:roles).page(params[:page]).per(25)
  end

  def edit
    authorize @role, :update?
  end

  def update
    authorize @role, :update?

    if @role.update(role_params)
      redirect_to admin_role_path(@role), notice: "Role was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def users_with_role
    @role = policy_scope(Role).find(params[:id])
    authorize @role, :show?

    @users = @role.users.includes(:roles)

    respond_to do |format|
      format.turbo_stream
      format.json { render json: @users.as_json(include: :roles) }
    end
  end

  private

  def set_role
    @role = policy_scope(Role).find(params[:id])
  end

  def role_params
    params.require(:role).permit(:description)
  end

  def calculate_role_stats
    stats = {}
    Role.includes(:users).each do |role|
      stats[role.name] = {
        count: role.users.count,
        percentage: (role.users.count.to_f / User.count * 100).round(1)
      }
    end
    stats
  end
end
