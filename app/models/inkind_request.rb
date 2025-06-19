class InkindRequest < Request
  DONATION_TYPES = %w[Goods Services].freeze

  validates :request_type, inclusion: { in: ['inkind'] }
  validate :validate_inkind_form_data

  def self.csv_headers
    [
      'Timestamp',
      'Email Address', 
      'Name',
      'Country',
      'Donor Name',
      'Donor Email',
      'Donor Address',
      'Donation Type',
      'Item Description',
      'QuickBooks Coding',
      'Fair Market Value',
      'Currency',
      'Amount (USD)',
      'Exchange Rate',
      'Donation Date',
      'Acknowledgment Sent',
      'Status',
      'Approver Email',
      'Approver Name',
      'Approval Date',
      'Notes'
    ]
  end

  def donor_name
    form_data['donor_name']
  end

  def donor_email
    form_data['donor_email']
  end

  def donor_address
    form_data['donor_address']
  end

  def donation_type
    form_data['donation_type']
  end

  def item_description
    form_data['item_description']
  end

  def expense_category_code
    form_data['expense_category_code']
  end

  def fair_market_value
    amount_requested
  end

  def donation_date
    Date.parse(form_data['donation_date']) if form_data['donation_date']
  rescue Date::Error
    nil
  end

  def country
    form_data['country']
  end

  def submitter_email
    form_data['submitter_email']
  end

  def submitter_name
    form_data['submitter_name']
  end

  def to_csv_row
    [
      created_at.iso8601,
      submitter_email,
      submitter_name,
      country,
      donor_name,
      donor_email,
      donor_address,
      donation_type,
      item_description,
      expense_category_code,
      fair_market_value,
      currency_code,
      amount_usd,
      exchange_rate,
      donation_date&.iso8601,
      false, # acknowledgment_sent - always false for Phase 1
      status.humanize,
      '', # approver_email - empty for Phase 1
      '', # approver_name - empty for Phase 1  
      '', # approval_date - empty for Phase 1
      metadata&.dig('notes') || ''
    ]
  end

  private

  def validate_inkind_form_data
    return unless form_data.is_a?(Hash)

    required_fields = %w[
      donor_name donor_email donor_address donation_type 
      item_description expense_category_code donation_date
      country submitter_email submitter_name
    ]

    required_fields.each do |field|
      if form_data[field].blank?
        errors.add(:form_data, "#{field.humanize} is required")
      end
    end

    # Validate email format
    if form_data['donor_email'].present? && !form_data['donor_email'].match?(/\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i)
      errors.add(:form_data, "Donor email must be a valid email address")
    end

    # Validate donation type
    if form_data['donation_type'].present? && !DONATION_TYPES.include?(form_data['donation_type'])
      errors.add(:form_data, "Donation type must be one of: #{DONATION_TYPES.join(', ')}")
    end

    # Validate donation date
    if form_data['donation_date'].present?
      begin
        date = Date.parse(form_data['donation_date'])
        if date > Date.current
          errors.add(:form_data, "Donation date cannot be in the future")
        end
      rescue Date::Error
        errors.add(:form_data, "Donation date must be a valid date")
      end
    end

    # Validate text field lengths
    validate_field_length('donor_name', 255)
    validate_field_length('donor_email', 255)
    validate_field_length('donor_address', 500)
    validate_field_length('item_description', 1000)
  end

  def validate_field_length(field, max_length)
    if form_data[field].present? && form_data[field].length > max_length
      errors.add(:form_data, "#{field.humanize} cannot exceed #{max_length} characters")
    end
  end
end