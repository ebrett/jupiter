class Admin::FeatureFlagAssignmentsController < AdminController
  before_action :set_feature_flag
  before_action :set_assignment, only: [ :destroy ]

  def create
    authorize FeatureFlagAssignment

    if params[:user_id].present?
      create_user_assignment
    elsif params[:role_id].present?
      create_role_assignment
    else
      redirect_to admin_feature_flag_path(@feature_flag), alert: "Please select a user or role."
    end
  end

  def destroy
    authorize @assignment
    flag_name = @feature_flag.name
    @assignment.destroy
    FeatureFlagService.clear_cache(flag_name)
    redirect_to admin_feature_flag_path(@feature_flag), notice: "Assignment removed successfully."
  end

  private

  def set_feature_flag
    @feature_flag = FeatureFlag.find(params[:feature_flag_id])
  end

  def set_assignment
    @assignment = @feature_flag.feature_flag_assignments.find(params[:id])
  end

  def create_user_assignment
    user = User.find(params[:user_id])

    assignment = @feature_flag.feature_flag_assignments.build(assignable: user)

    if assignment.save
      FeatureFlagService.clear_cache(@feature_flag.name)
      redirect_to admin_feature_flag_path(@feature_flag), notice: "Feature flag assigned to #{user.email_address}."
    else
      redirect_to admin_feature_flag_path(@feature_flag), alert: "Failed to assign feature flag to user."
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to admin_feature_flag_path(@feature_flag), alert: "User not found."
  end

  def create_role_assignment
    role = Role.find(params[:role_id])

    assignment = @feature_flag.feature_flag_assignments.build(assignable: role)

    if assignment.save
      FeatureFlagService.clear_cache(@feature_flag.name)
      redirect_to admin_feature_flag_path(@feature_flag), notice: "Feature flag assigned to role: #{role.name}."
    else
      redirect_to admin_feature_flag_path(@feature_flag), alert: "Failed to assign feature flag to role."
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to admin_feature_flag_path(@feature_flag), alert: "Role not found."
  end
end
