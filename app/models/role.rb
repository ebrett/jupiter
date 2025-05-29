class Role < ApplicationRecord
  has_many :user_roles, dependent: :destroy
  has_many :users, through: :user_roles

  validates :name, presence: true, uniqueness: true
  validates :description, presence: true

  # Define available roles
  ROLES = %w[
    submitter
    country_chapter_admin
    treasury_team_admin
    super_admin
    viewer
  ].freeze

  validates :name, inclusion: { in: ROLES }

  scope :by_hierarchy, -> { order(:name) }
end
