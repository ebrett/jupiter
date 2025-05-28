class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :nationbuilder_tokens, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :email_address, presence: true, uniqueness: true
  validates :password_digest, presence: true
end
