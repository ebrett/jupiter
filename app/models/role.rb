class Role < ApplicationRecord
  has_many :user_roles, dependent: :destroy
  has_many :users, through: :user_roles

  validates :name, presence: true, uniqueness: true
  validates :description, presence: true

  # Ransack configuration - explicitly allowlist searchable attributes
  def self.ransackable_attributes(auth_object = nil)
    [ "created_at", "description", "id", "id_value", "name", "updated_at" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "users", "user_roles" ]
  end

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

  # Creates all predefined roles if they don't exist
  def self.initialize_all
    role_descriptions = {
      "submitter" => "Can create and submit reimbursement requests",
      "country_chapter_admin" => "Can approve/deny requests for their region",
      "treasury_team_admin" => "Can process payments and manage financial operations",
      "super_admin" => "Full system access and user management",
      "viewer" => "Read-only access to view requests and reports"
    }

    ROLES.each do |role_name|
      # Find or create role with its description
      Role.find_or_create_by(name: role_name) do |role|
        role.description = role_descriptions[role_name]
      end
    end

    # Return all roles
    Role.all
  end
end
