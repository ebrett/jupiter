class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :nationbuilder_tokens, dependent: :destroy
  has_many :user_roles, dependent: :destroy
  has_many :roles, through: :user_roles

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :email_address, presence: true, uniqueness: true
  validates :password_digest, presence: true

  # Ransack configuration - explicitly allowlist searchable attributes
  def self.ransackable_attributes(auth_object = nil)
    [ "created_at", "email_address", "first_name", "id", "id_value", "last_name", "nationbuilder_uid", "updated_at" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "roles", "user_roles" ]
  end

  # Role management methods
  def has_role?(role_name)
    roles.exists?(name: role_name.to_s)
  end

  def add_role(role_name)
    role = Role.find_by(name: role_name.to_s)
    return false unless role

    roles << role unless has_role?(role_name)
    true
  end

  def remove_role(role_name)
    role = Role.find_by(name: role_name.to_s)
    return false unless role

    roles.delete(role)
  end

  def role_names
    roles.pluck(:name)
  end

  # Check if user has any admin privileges
  def admin?
    has_role?(:super_admin) || has_role?(:treasury_team_admin) || has_role?(:country_chapter_admin)
  end

  # Check if user can approve requests
  def can_approve?
    has_role?(:country_chapter_admin) || has_role?(:treasury_team_admin) || has_role?(:super_admin)
  end

  # Check if user can process payments
  def can_process_payments?
    has_role?(:treasury_team_admin) || has_role?(:super_admin)
  end
end
