class VendorRequestsController < ApplicationController
  include Authentication
  require "csv"

  before_action :require_authentication
  before_action :set_vendor_request, only: [ :show ]

  def index
    @vendor_requests = policy_scope(VendorRequest).recent
    authorize VendorRequest
  end

  def show
    authorize @vendor_request
  end

  def new
    @vendor_request = VendorRequest.new(request_type: "vendor")
    authorize @vendor_request
    @expense_categories = ExpenseCategory.options_for_select
  end

  def create
    @vendor_request = VendorRequest.new(vendor_request_params)
    authorize @vendor_request

    # Set auto-generated fields
    form_data = @vendor_request.form_data || {}
    @vendor_request.form_data = form_data.merge(
      "submitter_email" => Current.user.email_address,
      "submitter_name" => "#{Current.user.first_name} #{Current.user.last_name}".strip,
      "country" => "US" # TODO: Make this configurable or derive from user profile
    )
    @vendor_request.request_type = "vendor"

    # Handle file uploads - store URLs in form_data for CSV compatibility
    if params[:vendor_request][:invoices].present?
      @vendor_request.invoices.attach(params[:vendor_request][:invoices])
      invoice_urls = @vendor_request.invoices.map { |invoice| url_for(invoice) }
      @vendor_request.form_data = @vendor_request.form_data.merge("invoice_urls" => invoice_urls)
    end

    if @vendor_request.save
      redirect_to vendor_requests_path, notice: "Vendor payment request submitted successfully."
    else
      @expense_categories = ExpenseCategory.options_for_select
      render :new, status: :unprocessable_entity
    end
  end

  def export
    authorize VendorRequest, :export?

    @vendor_requests = policy_scope(VendorRequest)

    respond_to do |format|
      format.csv do
        csv_data = generate_csv(@vendor_requests)
        timestamp = Time.current.strftime("%Y%m%d_%H%M%S")
        filename = "vendor_requests_#{timestamp}.csv"

        send_data csv_data,
                  filename: filename,
                  type: "text/csv",
                  disposition: "attachment"
      end
    end
  end

  private

  def set_vendor_request
    @vendor_request = VendorRequest.find(params[:id])
  end

  def vendor_request_params
    params.require(:vendor_request).permit(
      :amount_requested,
      :currency_code,
      form_data: [
        :purpose, :expense_category_code, :vendor_name, :vendor_email,
        :vendor_address, :vendor_tax_id, :invoice_number, :invoice_date,
        :due_date, :payment_terms, :description, :chapter, :urgency
      ],
      invoices: []
    )
  end

  def generate_csv(requests)
    CSV.generate(headers: true) do |csv|
      csv << VendorRequest.csv_headers

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
