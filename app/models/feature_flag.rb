class FeatureFlag < ApplicationRecord
  belongs_to :created_by, class_name: "User", optional: true
  belongs_to :updated_by, class_name: "User", optional: true
  has_many :feature_flag_assignments, dependent: :destroy

  validates :name, presence: true, uniqueness: true, format: { with: /\A[a-z][a-z0-9_]*\z/, message: "must be lowercase with underscores only" }
  validates :description, presence: true

  scope :enabled, -> { where(enabled: true) }
  scope :disabled, -> { where(enabled: false) }

  def enable!
    update!(enabled: true)
  end

  def disable!
    update!(enabled: false)
  end

  def toggle!
    update!(enabled: !enabled?)
  end
end
