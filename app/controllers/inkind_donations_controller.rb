class InkindDonationsController < ApplicationController
  include Authentication
  require "csv"

  before_action :require_authentication
  before_action :set_inkind_request, only: [ :show ]

  def index
    @inkind_requests = policy_scope(InkindRequest).recent
    authorize InkindRequest
  end

  def show
    authorize @inkind_request
  end

  def new
    @inkind_request = InkindRequest.new(request_type: "inkind")
    authorize @inkind_request
    @expense_categories = ExpenseCategory.options_for_select
  end

  def create
    @inkind_request = InkindRequest.new(inkind_request_params)
    authorize @inkind_request

    # Set auto-generated fields
    @inkind_request.form_data = @inkind_request.form_data.merge(
      "submitter_email" => Current.user.email_address,
      "submitter_name" => "#{Current.user.first_name} #{Current.user.last_name}".strip,
      "country" => "US" # TODO: Make this configurable or derive from user profile
    )
    @inkind_request.request_type = "inkind"

    if @inkind_request.save
      redirect_to inkind_donations_path, notice: "In-kind donation submitted successfully."
    else
      @expense_categories = ExpenseCategory.options_for_select
      render :new, status: :unprocessable_entity
    end
  end

  def export
    authorize InkindRequest, :export?

    @inkind_requests = policy_scope(InkindRequest)

    respond_to do |format|
      format.csv do
        csv_data = generate_csv(@inkind_requests)
        timestamp = Time.current.strftime("%Y%m%d_%H%M%S")
        filename = "inkind_donations_#{timestamp}.csv"

        send_data csv_data,
                  filename: filename,
                  type: "text/csv",
                  disposition: "attachment"
      end
    end
  end

  private

  def set_inkind_request
    @inkind_request = InkindRequest.find(params[:id])
  end

  def inkind_request_params
    params.require(:inkind_request).permit(
      :amount_requested,
      form_data: [
        :donor_name, :donor_email, :donor_address,
        :donation_type, :item_description, :expense_category_code,
        :donation_date
      ]
    )
  end

  def generate_csv(requests)
    CSV.generate(headers: true) do |csv|
      csv << InkindRequest.csv_headers

      requests.each do |request|
        csv << request.to_csv_row
      end
    end
  end

  def handle_authorization_error
    if request.format.html?
      if Current.user.nil?
        redirect_to new_session_path, alert: "Please sign in to access this page."
      else
        redirect_to root_path, alert: "You are not authorized to access this page. Please contact an administrator if you need the submitter role."
      end
    else
      head :forbidden
    end
  end
end
