class ReimbursementRequestEvent < ApplicationRecord
  # Associations
  belongs_to :reimbursement_request
  belongs_to :user

  # Validations
  validates :event_type, presence: true, inclusion: {
    in: %w[submitted approved rejected paid info_requested],
    message: "must be a valid event type"
  }

  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :by_type, ->(type) { where(event_type: type) }
  scope :for_request, ->(request) { where(reimbursement_request: request) }

  # Query methods
  def submission_event?
    event_type == "submitted"
  end

  def approval_event?
    event_type == "approved"
  end

  def rejection_event?
    event_type == "rejected"
  end

  def payment_event?
    event_type == "paid"
  end

  def info_request_event?
    event_type == "info_requested"
  end

  # Formatting methods
  def formatted_event_type
    case event_type
    when "submitted"
      "Request Submitted"
    when "approved"
      "Request Approved"
    when "rejected"
      "Request Rejected"
    when "paid"
      "Payment Processed"
    when "info_requested"
      "Additional Information Requested"
    else
      event_type.humanize
    end
  end

  def event_description
    base_description = "#{formatted_event_type} by #{user.name || user.email}"

    case event_type
    when "approved"
      if event_data["notes"].present?
        "#{base_description} - #{event_data['notes']}"
      else
        base_description
      end
    when "rejected"
      if event_data["reason"].present?
        "#{base_description} - Reason: #{event_data['reason']}"
      else
        base_description
      end
    when "info_requested"
      if event_data["notes"].present?
        "#{base_description} - #{event_data['notes']}"
      else
        base_description
      end
    else
      base_description
    end
  end

  # Status change information
  def status_change_summary
    return nil unless from_status && to_status

    "#{from_status.humanize} → #{to_status.humanize}"
  end

  # Event data accessors
  def approval_notes
    event_data["notes"] if approval_event?
  end

  def rejection_reason
    event_data["reason"] if rejection_event?
  end

  def approved_amount_cents
    event_data["amount"] if approval_event?
  end

  def info_request_notes
    event_data["notes"] if info_request_event?
  end
end
