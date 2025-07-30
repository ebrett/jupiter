class VendorRequest < Request
  validates :request_type, inclusion: { in: [ "vendor" ] }
  validate :validate_vendor_form_data

  def self.csv_headers
    [
      "Timestamp",
      "Email Address",
      "Name",
      "Urgency",
      "Country",
      "Chapter",
      "Purpose",
      "QuickBooks Coding",
      "Amount Requested",
      "Exchange Rate",
      "Currency",
      "Amount (USD)",
      "Description",
      "Date Incurred",
      "Request Type",
      "Payment Method",
      "Receipt URLs",
      "Payee Name",
      "Payee Email",
      "Payee Address",
      "Vendor Name",
      "Vendor Email",
      "Vendor Address",
      "Invoice Number",
      "Invoice Date",
      "Due Date",
      "Status",
      "Approver Email",
      "Approver Name",
      "Approval Date",
      "Payment Date",
      "Check Number",
      "Notes"
    ]
  end

  # Form data accessors
  def purpose
    form_data["purpose"]
  end

  def expense_category_code
    form_data["expense_category_code"]
  end

  def vendor_name
    form_data["vendor_name"]
  end

  def vendor_email
    form_data["vendor_email"]
  end

  def vendor_address
    form_data["vendor_address"]
  end

  def vendor_tax_id
    form_data["vendor_tax_id"]
  end

  def invoice_number
    form_data["invoice_number"]
  end

  def invoice_date
    return nil unless form_data["invoice_date"].present?
    Date.parse(form_data["invoice_date"])
  rescue Date::Error
    nil
  end

  def due_date
    return nil unless form_data["due_date"].present?
    Date.parse(form_data["due_date"])
  rescue Date::Error
    nil
  end

  def payment_terms
    form_data["payment_terms"]
  end

  def invoice_urls
    form_data["invoice_urls"] || []
  end

  def description
    form_data["description"]
  end

  def country
    form_data["country"]
  end

  def chapter
    form_data["chapter"]
  end

  def submitter_email
    form_data["submitter_email"]
  end

  def submitter_name
    form_data["submitter_name"]
  end

  def urgency
    form_data["urgency"]
  end

  def to_csv_row
    [
      created_at.iso8601,
      submitter_email,
      submitter_name,
      urgency,
      country,
      chapter,
      purpose,
      expense_category_code,
      amount_requested,
      exchange_rate,
      currency_code,
      amount_usd,
      description,
      invoice_date&.iso8601, # Using invoice_date instead of date_incurred for vendors
      "V", # Request Type
      "", # Payment Method (empty for vendor payments)
      invoice_urls.join(";"), # Invoice URLs instead of receipt URLs
      "", # Payee Name (empty for vendor payments)
      "", # Payee Email (empty for vendor payments)
      "", # Payee Address (empty for vendor payments)
      vendor_name,
      vendor_email,
      vendor_address,
      invoice_number,
      invoice_date&.iso8601,
      due_date&.iso8601,
      status.humanize,
      "", # Approver Email (empty for Phase 1)
      "", # Approver Name (empty for Phase 1)
      "", # Approval Date (empty for Phase 1)
      "", # Payment Date (empty for Phase 1)
      "", # Check Number (empty for Phase 1)
      metadata&.dig("notes") || ""
    ]
  end

  private

  def validate_vendor_form_data
    return unless form_data.is_a?(Hash)

    required_fields = %w[
      purpose expense_category_code vendor_name vendor_address
      invoice_number invoice_date description country
      submitter_email submitter_name
    ]

    required_fields.each do |field|
      if form_data[field].blank?
        errors.add(:form_data, "#{field.humanize} is required")
      end
    end

    # Validate email formats (optional for vendor_email, required for submitter_email)
    validate_email_field("vendor_email", required: false)
    validate_email_field("submitter_email", required: true)

    # Validate dates
    validate_date_field("invoice_date", required: true)
    validate_date_field("due_date", required: false)

    # Validate due date is after invoice date
    if form_data["invoice_date"].present? && form_data["due_date"].present?
      begin
        inv_date = Date.parse(form_data["invoice_date"])
        due_date = Date.parse(form_data["due_date"])
        if due_date < inv_date
          errors.add(:form_data, "Due date cannot be before invoice date")
        end
      rescue Date::Error
        # Individual date validation will catch this
      end
    end

    # Validate text field lengths
    validate_field_length("purpose", 255)
    validate_field_length("vendor_name", 255)
    validate_field_length("vendor_email", 255)
    validate_field_length("vendor_address", 500)
    validate_field_length("vendor_tax_id", 50)
    validate_field_length("invoice_number", 100)
    validate_field_length("payment_terms", 100)
    validate_field_length("description", 1000)
    validate_field_length("chapter", 255)
  end

  def validate_email_field(field, required: true)
    email = form_data[field]
    if required && email.blank?
      errors.add(:form_data, "#{field.humanize} is required")
    elsif email.present? && !email.match?(/\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i)
      errors.add(:form_data, "#{field.humanize} must be a valid email address")
    end
  end

  def validate_date_field(field, required: true)
    date_str = form_data[field]
    if required && date_str.blank?
      errors.add(:form_data, "#{field.humanize} is required")
    elsif date_str.present?
      begin
        Date.parse(date_str)
      rescue Date::Error
        errors.add(:form_data, "#{field.humanize} must be a valid date")
      end
    end
  end

  def validate_field_length(field, max_length)
    if form_data[field].present? && form_data[field].length > max_length
      errors.add(:form_data, "#{field.humanize} cannot exceed #{max_length} characters")
    end
  end
end
