class ReimbursementRequestsController < ApplicationController
  include Authentication

  before_action :require_authentication
  before_action :set_reimbursement_request, only: [ :show, :edit, :update, :destroy, :submit ]

  def index
    @reimbursement_requests = policy_scope(ReimbursementRequest).recent
    authorize ReimbursementRequest

    respond_to do |format|
      format.html # Will render view in Task 7
      format.json { render json: @reimbursement_requests }
    end
  end

  def show
    authorize @reimbursement_request

    respond_to do |format|
      format.html # Will render view in Task 7
      format.json { render json: @reimbursement_request }
    end
  end

  def new
    @reimbursement_request = ReimbursementRequest.new
    authorize @reimbursement_request

    respond_to do |format|
      format.html # Will render view in Task 7
      format.json { render json: @reimbursement_request }
    end
  end

  def create
    @reimbursement_request = ReimbursementRequest.new(create_params)
    @reimbursement_request.user = Current.user
    authorize @reimbursement_request

    # Handle file uploads
    if params[:reimbursement_request][:receipts].present?
      @reimbursement_request.receipts.attach(params[:reimbursement_request][:receipts])
    end

    if @reimbursement_request.save
      respond_to do |format|
        format.html { redirect_to reimbursement_requests_path, notice: "Reimbursement request created successfully." }
        format.json { render json: @reimbursement_request, status: :created }
      end
    else
      respond_to do |format|
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @reimbursement_request.errors, status: :unprocessable_entity }
      end
    end
  end

  def edit
    authorize @reimbursement_request

    respond_to do |format|
      format.html # Will render view in Task 7
      format.json { render json: @reimbursement_request }
    end
  end

  def update
    authorize @reimbursement_request

    # Handle file uploads
    if params[:reimbursement_request][:receipts].present?
      @reimbursement_request.receipts.attach(params[:reimbursement_request][:receipts])
    end

    if @reimbursement_request.update(update_params)
      respond_to do |format|
        format.html { redirect_to @reimbursement_request, notice: "Reimbursement request updated successfully." }
        format.json { render json: @reimbursement_request, status: :ok }
      end
    else
      respond_to do |format|
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @reimbursement_request.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    authorize @reimbursement_request
    @reimbursement_request.destroy
    redirect_to reimbursement_requests_path,
                notice: "Reimbursement request deleted successfully."
  end

  def submit
    authorize @reimbursement_request, :submit?

    begin
      @reimbursement_request.submit!(Current.user)

      # TODO: Send email notification (Task 6)
      # ReimbursementRequestMailer.submitted(@reimbursement_request).deliver_later

      redirect_to @reimbursement_request,
                  notice: "Reimbursement request submitted successfully."
    rescue ReimbursementRequest::InvalidTransition => e
      redirect_to @reimbursement_request,
                  alert: "Cannot submit request: #{e.message}"
    end
  end

  private

  def set_reimbursement_request
    @reimbursement_request = ReimbursementRequest.find(params[:id])
  end

  def create_params
    permitted_attrs = policy(ReimbursementRequest).permitted_attributes_for_create
    params.require(:reimbursement_request).permit(*permitted_attrs)
  end

  def update_params
    permitted_attrs = policy(@reimbursement_request).permitted_attributes_for_update
    params.require(:reimbursement_request).permit(*permitted_attrs)
  end

  rescue_from Pundit::NotAuthorizedError, with: :handle_authorization_error

  def handle_authorization_error(exception)
    if request.format.html?
      if Current.user.nil?
        redirect_to sign_in_path, alert: "Please sign in to access this page."
      else
        redirect_to root_path, alert: "You are not authorized to perform this action."
      end
    else
      head :forbidden
    end
  end
end
