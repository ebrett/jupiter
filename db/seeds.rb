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

# Create roles first
roles_data = [
  {
    name: 'submitter',
    description: 'Can create and submit reimbursement requests'
  },
  {
    name: 'country_chapter_admin',
    description: 'Can approve/deny requests for their region'
  },
  {
    name: 'treasury_team_admin',
    description: 'Can process payments and manage financial operations'
  },
  {
    name: 'super_admin',
    description: 'Full system access and user management'
  },
  {
    name: 'viewer',
    description: 'Read-only access to view requests and reports'
  }
]

roles_data.each do |role_attrs|
  Role.find_or_create_by!(name: role_attrs[:name]) do |role|
    role.description = role_attrs[:description]
  end
end

# Test users for development and QA with roles
# Credentials: email_address / password
users_data = [
  { 
    email_address: 'admin@example.com', 
    password: 'password123',
    first_name: 'Super',
    last_name: 'Admin',
    roles: ['super_admin']
  },
  { 
    email_address: 'treasury@example.com', 
    password: 'password123',
    first_name: 'Treasury',
    last_name: 'Admin',
    roles: ['treasury_team_admin']
  },
  { 
    email_address: 'chapter@example.com', 
    password: 'password123',
    first_name: 'Chapter',
    last_name: 'Admin',
    roles: ['country_chapter_admin']
  },
  { 
    email_address: 'user1@example.com', 
    password: 'password123',
    first_name: 'Regular',
    last_name: 'User',
    roles: ['submitter']
  },
  { 
    email_address: 'viewer@example.com', 
    password: 'password123',
    first_name: 'View',
    last_name: 'Only',
    roles: ['viewer']
  },
  { 
    email_address: 'multi@example.com', 
    password: 'password123',
    first_name: 'Multi',
    last_name: 'Role',
    roles: ['submitter', 'viewer']
  }
]

users_data.each do |user_attrs|
  user = User.find_or_create_by!(email_address: user_attrs[:email_address]) do |u|
    u.password = user_attrs[:password]
    u.first_name = user_attrs[:first_name] if user_attrs[:first_name]
    u.last_name = user_attrs[:last_name] if user_attrs[:last_name]
  end

  # Assign roles
  user_attrs[:roles]&.each do |role_name|
    user.add_role(role_name)
  end
end