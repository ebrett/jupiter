class User < ApplicationRecord
  has_secure_password validations: false
  has_many :sessions, dependent: :destroy
  has_many :nationbuilder_tokens, dependent: :destroy
  has_many :user_roles, dependent: :destroy
  has_many :roles, through: :user_roles

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :email_address, presence: true, uniqueness: true
  validates :password, presence: true, if: :password_required?
  validates :password, length: { minimum: 8 }, if: :password_required?
  validates :password, confirmation: true, if: :password_required?
  validates :verification_token, uniqueness: true, allow_nil: true

  before_create :auto_verify_nationbuilder_users
  before_create :generate_verification_for_email_users

  # Scopes
  scope :verified, -> { where.not(email_verified_at: nil) }
  scope :unverified, -> { where(email_verified_at: nil) }

  # Class methods
  def self.find_by_verification_token(token)
    find_by(verification_token: token)
  end

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
    has_role?(:system_administrator) || has_role?(:treasury_team_admin) || has_role?(:country_chapter_admin)
  end

  # Check if user can approve requests
  def can_approve?
    has_role?(:country_chapter_admin) || has_role?(:treasury_team_admin) || has_role?(:system_administrator)
  end

  # Check if user can process payments
  def can_process_payments?
    has_role?(:treasury_team_admin) || has_role?(:system_administrator)
  end

  # Authentication methods
  def nationbuilder_user?
    nationbuilder_uid.present?
  end

  def email_password_user?
    password_digest.present?
  end

  # Email verification methods
  def email_verified?
    email_verified_at.present?
  end

  def verification_pending?
    !email_verified? && verification_token.present?
  end

  def generate_verification_token
    self.verification_token = SecureRandom.urlsafe_base64(32)
    self.verification_sent_at = Time.current
  end

  def verify_email!
    update!(
      email_verified_at: Time.current,
      verification_token: nil,
      verification_sent_at: nil
    )
  end

  def verification_expired?
    return false unless verification_sent_at

    verification_sent_at < 24.hours.ago
  end

  def can_resend_verification?
    return false if email_verified?
    return true unless verification_sent_at

    verification_sent_at < 1.hour.ago
  end

  def send_verification_email
    return false if email_verified?

    generate_verification_token
    save!

    EmailVerificationMailer.verify_email(self).deliver_now
    true
  rescue => e
    Rails.logger.error "Failed to send verification email for user #{id}: #{e.message}"
    false
  end

  # NationBuilder profile data methods
  def nationbuilder_tags
    return [] unless nationbuilder_profile_data
    nationbuilder_profile_data["tags"] || []
  end

  def nationbuilder_phone
    return nil unless nationbuilder_profile_data
    nationbuilder_profile_data["phone"]
  end

  def nationbuilder_raw_data
    return {} unless nationbuilder_profile_data
    nationbuilder_profile_data["raw_data"] || {}
  end

  def has_nationbuilder_profile_data?
    nationbuilder_profile_data.present?
  end

  def update_nationbuilder_profile_data!(profile_data)
    self.nationbuilder_profile_data = {
      "tags" => profile_data[:tags] || [],
      "phone" => profile_data[:phone],
      "raw_data" => profile_data[:raw_data] || {},
      "last_synced_at" => Time.current.iso8601
    }
    save!
  end

  private

  def password_required?
    # Password is required if:
    # 1. New record and it's an email/password user (no NationBuilder UID)
    # 2. Password is being explicitly set/changed
    (new_record? && !nationbuilder_user?) || password.present?
  end

  def auto_verify_nationbuilder_users
    if nationbuilder_user?
      self.email_verified_at = Time.current
    end
  end

  def generate_verification_for_email_users
    if !nationbuilder_user? && !email_verified?
      generate_verification_token
    end
  end
end
