# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# Add idempotent development seeds here
# Example:
# User.find_or_create_by!(email: 'admin@example.com') do |user|
#   user.password = 'password'
#   user.admin = true
# end

# Test users for development and QA
# Credentials: email_address / password
users = [
  { email_address: 'admin@example.com', password: 'password123' },
  { email_address: 'user1@example.com', password: 'password123' },
  { email_address: 'user2@example.com', password: 'password123' },
  { email_address: 'qa@example.com', password: 'password123' },
  { email_address: 'guest@example.com', password: 'password123' }
]

users.each do |attrs|
  User.find_or_create_by!(email_address: attrs[:email_address]) do |user|
    user.password = attrs[:password]
  end
end
