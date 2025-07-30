class ReimbursementRequest < ApplicationRecord
  # Custom exception for invalid state transitions
  class InvalidTransition < StandardError; end

  # Associations
  belongs_to :user
  belongs_to :approved_by, class_name: "User", optional: true
  has_many :events, class_name: "ReimbursementRequestEvent", dependent: :destroy
  has_many_attached :receipts

  # Enums
  enum :status, {
    draft: "draft",
    submitted: "submitted",
    under_review: "under_review",
    approved: "approved",
    rejected: "rejected",
    paid: "paid"
  }

  enum :category, {
    travel: "travel",
    accommodation: "accommodation",
    meals: "meals",
    supplies: "supplies",
    communications: "communications",
    events: "events",
    other: "other"
  }

  enum :priority, {
    low: "low",
    normal: "normal",
    high: "high",
    urgent: "urgent"
  }

  # Validations
  validates :title, presence: true, length: { maximum: 255 }
  validates :description, presence: true, length: { maximum: 2000 }
  validates :amount_cents, presence: true, numericality: { greater_than: 0 }
  validates :currency, presence: true, format: { with: /\A[A-Z]{3}\z/, message: "must be a valid 3-letter ISO currency code" }
  validates :expense_date, presence: true
  validates :category, presence: true
  validates :request_number, presence: true, uniqueness: true
  validates :status, presence: true
  validates :priority, presence: true

  # Custom validations
  validate :expense_date_not_in_future
  validate :status_transition_timestamps
  validate :approval_fields_when_approved
  validate :rejection_fields_when_rejected

  # Scopes
  scope :by_status, ->(status) { where(status: status) }
  scope :recent, -> { order(created_at: :desc) }
  scope :pending_approval, -> { where(status: [ "submitted", "under_review" ]) }
  scope :for_user, ->(user) { where(user: user) }

  # Callbacks
  before_validation :generate_request_number, on: :create
  before_validation :set_defaults, on: :create

  # Helper methods
  def amount_in_dollars
    return 0.0 unless amount_cents
    amount_cents / 100.0
  end

  def amount_in_dollars=(value)
    self.amount_cents = (value.to_f * 100).to_i
  end

  # State transition methods
  def submit!(acting_user)
    raise InvalidTransition, "Cannot submit request in #{status} status" unless can_submit?

    transaction do
      update!(
        status: "submitted",
        submitted_at: Time.current
      )
      log_event("submitted", acting_user, "draft", "submitted")
    end
  end

  def approve!(acting_user, amount: nil, notes: nil)
    raise InvalidTransition, "Cannot approve request in #{status} status" unless can_approve?

    transaction do
      previous_status = status
      update!(
        status: "approved",
        approved_at: Time.current,
        approved_by: acting_user,
        approved_amount_cents: amount || amount_cents,
        approval_notes: notes
      )
      log_event("approved", acting_user, previous_status, "approved", { notes: notes, amount: approved_amount_cents })
    end
  end

  def reject!(acting_user, reason:)
    raise InvalidTransition, "Cannot reject request in #{status} status" unless can_reject?

    transaction do
      previous_status = status
      update!(
        status: "rejected",
        rejected_at: Time.current,
        rejection_reason: reason
      )
      log_event("rejected", acting_user, previous_status, "rejected", { reason: reason })
    end
  end

  def mark_paid!(acting_user)
    raise InvalidTransition, "Cannot mark as paid request in #{status} status" unless can_mark_paid?

    transaction do
      previous_status = status
      update!(
        status: "paid",
        paid_at: Time.current
      )
      log_event("paid", acting_user, previous_status, "paid")
    end
  end

  def request_more_info!(acting_user, notes: nil)
    raise InvalidTransition, "Cannot request info for request in #{status} status" unless can_request_info?

    transaction do
      previous_status = status
      update!(
        status: "under_review",
        reviewed_at: Time.current
      )
      log_event("info_requested", acting_user, previous_status, "under_review", { notes: notes })
    end
  end

  # Query methods
  def can_submit?
    draft?
  end

  def can_approve?
    submitted? || under_review?
  end

  def can_reject?
    submitted? || under_review?
  end

  def can_mark_paid?
    approved?
  end

  def can_request_info?
    submitted?
  end

  # Amount formatting methods
  def amount
    amount_cents / 100.0
  end

  def formatted_amount
    case currency
    when "USD"
      "$#{"%.2f" % amount}"
    when "EUR"
      "€#{"%.2f" % amount}"
    when "GBP"
      "£#{"%.2f" % amount}"
    else
      "#{currency} #{"%.2f" % amount}"
    end
  end

  def approved_amount
    return nil unless approved_amount_cents
    approved_amount_cents / 100.0
  end

  def formatted_approved_amount
    return nil unless approved_amount_cents
    case currency
    when "USD"
      "$#{"%.2f" % approved_amount}"
    when "EUR"
      "€#{"%.2f" % approved_amount}"
    when "GBP"
      "£#{"%.2f" % approved_amount}"
    else
      "#{currency} #{"%.2f" % approved_amount}"
    end
  end

  private

  def generate_request_number
    return if request_number.present?

    year = Date.current.year
    sequence = ReimbursementRequest.where("request_number LIKE ?", "RB-#{year}-%").count + 1
    self.request_number = "RB-#{year}-#{sequence.to_s.rjust(3, '0')}"
  end

  def set_defaults
    self.currency ||= "USD"
    self.priority ||= "normal"
  end

  def expense_date_not_in_future
    return unless expense_date.present?

    if expense_date > Date.current
      errors.add(:expense_date, "cannot be in the future")
    end
  end

  def status_transition_timestamps
    case status
    when "submitted", "under_review", "approved", "rejected", "paid"
      errors.add(:submitted_at, "must be present") if submitted_at.blank?
    end

    case status
    when "approved", "paid"
      errors.add(:approved_at, "must be present") if approved_at.blank?
      errors.add(:approved_by_id, "must be present") if approved_by_id.blank?
    end

    case status
    when "rejected"
      errors.add(:rejected_at, "must be present") if rejected_at.blank?
    end

    case status
    when "paid"
      errors.add(:paid_at, "must be present") if paid_at.blank?
    end
  end

  def approval_fields_when_approved
    return unless approved?

    errors.add(:approved_amount_cents, "must be present when approved") if approved_amount_cents.blank?
  end

  def rejection_fields_when_rejected
    return unless rejected?

    errors.add(:rejection_reason, "must be present when rejected") if rejection_reason.blank?
  end

  def log_event(event_type, acting_user, from_status, to_status, event_data = {})
    events.create!(
      event_type: event_type,
      user: acting_user,
      from_status: from_status,
      to_status: to_status,
      event_data: event_data
    )
  end
end
