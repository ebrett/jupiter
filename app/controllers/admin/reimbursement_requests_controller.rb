class Admin::ReimbursementRequestsController < AdminController
  before_action :set_reimbursement_request, only: [ :show, :approve, :reject, :request_info, :mark_paid ]
  before_action :authorize_admin_access

  def index
    @reimbursement_requests = policy_scope(ReimbursementRequest)

    # Apply filters
    @reimbursement_requests = @reimbursement_requests.by_status(params[:status]) if params[:status].present?
    @reimbursement_requests = @reimbursement_requests.for_user(params[:user_id]) if params[:user_id].present?

    @reimbursement_requests = @reimbursement_requests.includes(:user, :approved_by, :events).recent

    respond_to do |format|
      format.html
      format.json { render json: @reimbursement_requests.as_json(include: [ :user, :approved_by ]) }
    end
  end

  def show
    authorize @reimbursement_request, :show?

    respond_to do |format|
      format.html
      format.json {
        render json: @reimbursement_request.as_json(
          include: [
            :user,
            :approved_by,
            { events: { include: :user } }
          ]
        )
      }
    end
  end

  def approve
    authorize @reimbursement_request, :approve?

    # Validate request can be approved
    unless @reimbursement_request.can_approve?
      render json: { errors: [ "Request cannot be approved from #{@reimbursement_request.status} status" ] }, status: :unprocessable_entity
      return
    end

    begin
      approved_amount = params[:approved_amount_cents]&.to_i
      approval_notes = params[:approval_notes]

      @reimbursement_request.approve!(Current.user, amount: approved_amount, notes: approval_notes)

      respond_to do |format|
        format.html { redirect_to admin_reimbursement_request_path(@reimbursement_request), notice: "Request approved successfully." }
        format.json { render json: { status: "success", message: "Request approved successfully" } }
      end
    rescue ReimbursementRequest::InvalidTransition => e
      respond_to do |format|
        format.html { redirect_to admin_reimbursement_request_path(@reimbursement_request), alert: e.message }
        format.json { render json: { errors: [ e.message ] }, status: :unprocessable_entity }
      end
    end
  end

  def reject
    authorize @reimbursement_request, :reject?

    # Validate rejection reason is provided
    rejection_reason = params[:rejection_reason]
    if rejection_reason.blank?
      render json: { errors: [ "Rejection reason is required" ] }, status: :unprocessable_entity
      return
    end

    # Validate request can be rejected
    unless @reimbursement_request.can_reject?
      render json: { errors: [ "Request cannot be rejected from #{@reimbursement_request.status} status" ] }, status: :unprocessable_entity
      return
    end

    begin
      @reimbursement_request.reject!(Current.user, reason: rejection_reason)

      respond_to do |format|
        format.html { redirect_to admin_reimbursement_request_path(@reimbursement_request), notice: "Request rejected." }
        format.json { render json: { status: "success", message: "Request rejected successfully" } }
      end
    rescue ReimbursementRequest::InvalidTransition => e
      respond_to do |format|
        format.html { redirect_to admin_reimbursement_request_path(@reimbursement_request), alert: e.message }
        format.json { render json: { errors: [ e.message ] }, status: :unprocessable_entity }
      end
    end
  end

  def request_info
    authorize @reimbursement_request, :request_info?

    # Validate info request message is provided
    info_request = params[:info_request]
    if info_request.blank?
      render json: { errors: [ "Information request message is required" ] }, status: :unprocessable_entity
      return
    end

    # Validate request can have info requested
    unless @reimbursement_request.can_request_info?
      render json: { errors: [ "Cannot request info for request in #{@reimbursement_request.status} status" ] }, status: :unprocessable_entity
      return
    end

    begin
      @reimbursement_request.request_more_info!(Current.user, notes: info_request)

      respond_to do |format|
        format.html { redirect_to admin_reimbursement_request_path(@reimbursement_request), notice: "Information requested from user." }
        format.json { render json: { status: "success", message: "Information requested successfully" } }
      end
    rescue ReimbursementRequest::InvalidTransition => e
      respond_to do |format|
        format.html { redirect_to admin_reimbursement_request_path(@reimbursement_request), alert: e.message }
        format.json { render json: { errors: [ e.message ] }, status: :unprocessable_entity }
      end
    end
  end

  def mark_paid
    authorize @reimbursement_request, :mark_paid?

    # Validate request can be marked as paid
    unless @reimbursement_request.can_mark_paid?
      render json: { errors: [ "Request cannot be marked as paid from #{@reimbursement_request.status} status" ] }, status: :unprocessable_entity
      return
    end

    begin
      payment_reference = params[:payment_reference]
      @reimbursement_request.mark_paid!(Current.user)

      respond_to do |format|
        format.html { redirect_to admin_reimbursement_request_path(@reimbursement_request), notice: "Request marked as paid." }
        format.json { render json: { status: "success", message: "Request marked as paid successfully" } }
      end
    rescue ReimbursementRequest::InvalidTransition => e
      respond_to do |format|
        format.html { redirect_to admin_reimbursement_request_path(@reimbursement_request), alert: e.message }
        format.json { render json: { errors: [ e.message ] }, status: :unprocessable_entity }
      end
    end
  end

  def bulk_approve
    authorize ReimbursementRequest, :bulk_approve?

    request_ids = params[:request_ids] || []
    approval_notes = params[:approval_notes]

    if request_ids.empty?
      render json: { errors: [ "No requests selected for bulk approval" ] }, status: :unprocessable_entity
      return
    end

    success_count = 0
    errors = []

    ReimbursementRequest.transaction do
      request_ids.each do |request_id|
        request = ReimbursementRequest.find_by(id: request_id)
        next unless request && policy(request).approve?

        if request.can_approve?
          request.approve!(Current.user, notes: approval_notes)
          success_count += 1
        else
          errors << "Request #{request.request_number} cannot be approved from #{request.status} status"
        end
      rescue => e
        errors << "Request #{request&.request_number || request_id}: #{e.message}"
      end
    end

    if success_count > 0
      message = "Successfully approved #{success_count} request(s)"
      message += ". Errors: #{errors.join(', ')}" if errors.any?
      render json: { status: "success", message: message, approved_count: success_count }
    else
      render json: { errors: errors.presence || [ "No requests could be approved" ] }, status: :unprocessable_entity
    end
  end

  def export
    authorize ReimbursementRequest, :export?

    @reimbursement_requests = policy_scope(ReimbursementRequest)

    # Apply same filters as index
    @reimbursement_requests = @reimbursement_requests.by_status(params[:status]) if params[:status].present?
    @reimbursement_requests = @reimbursement_requests.for_user(params[:user_id]) if params[:user_id].present?

    @reimbursement_requests = @reimbursement_requests.includes(:user, :approved_by).recent

    respond_to do |format|
      format.csv do
        csv_data = generate_csv(@reimbursement_requests)
        send_data csv_data,
                  filename: "reimbursement_requests_#{Date.current.strftime('%Y%m%d')}.csv",
                  type: "text/csv; charset=utf-8",
                  disposition: "attachment"
      end
    end
  end

  private

  def set_reimbursement_request
    @reimbursement_request = ReimbursementRequest.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    respond_to do |format|
      format.html { redirect_to admin_reimbursement_requests_path, alert: "Request not found." }
      format.json { render json: { errors: [ "Request not found" ] }, status: :not_found }
    end
  end

  def authorize_admin_access
    authorize ReimbursementRequest, :admin_access?
  end

  def generate_csv(requests)
    require "csv"

    CSV.generate(headers: true) do |csv|
      csv << [
        "Request Number",
        "Title",
        "Description",
        "Amount",
        "Currency",
        "Category",
        "Priority",
        "Status",
        "Submitter Name",
        "Submitter Email",
        "Expense Date",
        "Submitted At",
        "Approved At",
        "Approved By",
        "Approved Amount",
        "Paid At"
      ]

      requests.each do |request|
        csv << [
          request.request_number,
          request.title,
          request.description,
          request.amount_in_dollars,
          request.currency,
          request.category.humanize,
          request.priority.humanize,
          request.status.humanize,
          "#{request.user.first_name} #{request.user.last_name}",
          request.user.email_address,
          request.expense_date&.strftime("%Y-%m-%d"),
          request.submitted_at&.strftime("%Y-%m-%d %H:%M"),
          request.approved_at&.strftime("%Y-%m-%d %H:%M"),
          request.approved_by ? "#{request.approved_by.first_name} #{request.approved_by.last_name}" : nil,
          request.approved_amount,
          request.paid_at&.strftime("%Y-%m-%d %H:%M")
        ]
      end
    end
  end
end
