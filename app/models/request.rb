class Request < ApplicationRecord
  enum :status, {
    submitted: 0,
    approved: 1,
    rejected: 2,
    paid: 3
  }

  enum :request_type, {
    reimbursement: 'R',
    vendor: 'V',
    inkind: 'I'
  }

  validates :request_number, presence: true, uniqueness: true
  validates :request_type, presence: true
  validates :amount_requested, presence: true, numericality: { greater_than: 0 }
  validates :currency_code, presence: true
  validates :amount_usd, presence: true, numericality: { greater_than: 0 }
  validates :exchange_rate, presence: true, numericality: { greater_than: 0 }
  validates :form_data, presence: true

  before_validation :generate_request_number, on: :create
  before_validation :set_defaults, on: :create

  scope :by_type, ->(type) { where(request_type: type) }
  scope :recent, -> { order(created_at: :desc) }

  private

  def generate_request_number
    return if request_number.present?
    
    prefix = case request_type
             when 'inkind' then 'IK'
             when 'reimbursement' then 'RB'
             when 'vendor' then 'VP'
             else 'REQ'
             end
    
    year = Date.current.year
    sequence = Request.where("request_number LIKE ?", "#{prefix}-#{year}-%").count + 1
    self.request_number = "#{prefix}-#{year}-#{sequence.to_s.rjust(3, '0')}"
  end

  def set_defaults
    self.currency_code ||= 'USD'
    self.exchange_rate ||= 1.0
    self.amount_usd ||= amount_requested if currency_code == 'USD'
  end
end