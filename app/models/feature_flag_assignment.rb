class FeatureFlagAssignment < ApplicationRecord
  belongs_to :feature_flag
  belongs_to :assignable, polymorphic: true

  validates :feature_flag_id, uniqueness: { scope: [ :assignable_type, :assignable_id ] }
  validate :valid_assignable_type

  scope :for_users, -> { where(assignable_type: "User") }
  scope :for_roles, -> { where(assignable_type: "Role") }

  private

  def valid_assignable_type
    unless %w[User Role].include?(assignable_type)
      errors.add(:assignable_type, "must be User or Role")
    end
  end
end
