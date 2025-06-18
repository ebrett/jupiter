class Admin::FeatureFlagsController < AdminController
  before_action :set_feature_flag, only: [ :show, :edit, :update, :destroy, :toggle ]

  def index
    @feature_flags = FeatureFlag.includes(:created_by, :updated_by, :feature_flag_assignments)
                                .order(:name)
                                .page(params[:page])
  end

  def show
    @assignments = @feature_flag.feature_flag_assignments
                                .includes(:assignable)
                                .order(:assignable_type, :created_at)
  end

  def new
    @feature_flag = FeatureFlag.new
  end

  def create
    @feature_flag = FeatureFlag.new(feature_flag_params)
    @feature_flag.created_by = current_user
    @feature_flag.updated_by = current_user

    if @feature_flag.save
      redirect_to admin_feature_flag_path(@feature_flag), notice: "Feature flag was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    @feature_flag.updated_by = current_user

    if @feature_flag.update(feature_flag_params)
      FeatureFlagService.clear_cache(@feature_flag.name)
      redirect_to admin_feature_flag_path(@feature_flag), notice: "Feature flag was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    flag_name = @feature_flag.name
    @feature_flag.destroy
    FeatureFlagService.clear_cache(flag_name)
    redirect_to admin_feature_flags_path, notice: "Feature flag was successfully deleted."
  end

  def toggle
    @feature_flag.toggle!
    @feature_flag.update!(updated_by: current_user)
    FeatureFlagService.clear_cache(@feature_flag.name)

    respond_to do |format|
      format.json { render json: { enabled: @feature_flag.enabled? } }
      format.html { redirect_back(fallback_location: admin_feature_flags_path) }
    end
  end

  def clear_cache
    FeatureFlagService.clear_cache
    redirect_to admin_feature_flags_path, notice: "Feature flag cache cleared successfully."
  end

  private

  def set_feature_flag
    @feature_flag = FeatureFlag.find(params[:id])
  end

  def feature_flag_params
    params.require(:feature_flag).permit(:name, :description, :enabled)
  end
end
