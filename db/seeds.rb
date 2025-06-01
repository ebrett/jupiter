# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# Environment-based seeding configuration
SEED_CONFIG = {
  'development' => {
    create_test_users: true,
    create_admin_users: true,
    create_edge_case_users: true,
    verbose_output: true
  },
  'test' => {
    create_test_users: true,
    create_admin_users: true,
    create_edge_case_users: false,
    verbose_output: false
  },
  'production' => {
    create_test_users: false,
    create_admin_users: true,  # Only essential admin
    create_edge_case_users: false,
    verbose_output: false
  }
}.freeze

current_config = SEED_CONFIG[Rails.env] || SEED_CONFIG['development']

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

# Define user data sets based on environment needs
admin_users = [
  {
    email_address: 'admin@example.com',
    password: 'password123',
    first_name: 'Super',
    last_name: 'Admin',
    roles: [ 'super_admin' ],
    nationbuilder_uid: 'nb_admin_123',
    category: :admin
  }
]

test_users = [
  {
    email_address: 'treasury@example.com',
    password: 'password123',
    first_name: 'Treasury',
    last_name: 'Manager',
    roles: [ 'treasury_team_admin' ],
    nationbuilder_uid: 'nb_treasury_456',
    category: :test
  },
  {
    email_address: 'chapter@example.com',
    password: 'password123',
    first_name: 'Chapter',
    last_name: 'Leader',
    roles: [ 'country_chapter_admin' ],
    nationbuilder_uid: 'nb_chapter_789',
    category: :test
  },
  {
    email_address: 'user1@example.com',
    password: 'password123',
    first_name: 'Alice',
    last_name: 'Johnson',
    roles: [ 'submitter' ],
    nationbuilder_uid: 'nb_user1_001',
    category: :test
  },
  {
    email_address: 'user2@example.com',
    password: 'password123',
    first_name: 'Bob',
    last_name: 'Smith',
    roles: [ 'submitter' ],
    category: :test
  },
  {
    email_address: 'viewer@example.com',
    password: 'password123',
    first_name: 'Carol',
    last_name: 'Williams',
    roles: [ 'viewer' ],
    category: :test
  },
  {
    email_address: 'multi@example.com',
    password: 'password123',
    first_name: 'David',
    last_name: 'Brown',
    roles: [ 'submitter', 'viewer' ],
    nationbuilder_uid: 'nb_multi_002',
    category: :test
  },
  {
    email_address: 'qa@example.com',
    password: 'password123',
    first_name: 'QA',
    last_name: 'Tester',
    roles: [ 'submitter', 'viewer' ],
    category: :test
  },
  {
    email_address: 'guest@example.com',
    password: 'password123',
    first_name: 'Guest',
    last_name: 'User',
    roles: [],
    category: :test
  }
]

edge_case_users = [
  {
    email_address: 'long.email.address.for.testing@verylongdomainname.example.com',
    password: 'password123',
    first_name: 'Very',
    last_name: 'LongEmailUser',
    roles: [ 'submitter' ],
    category: :edge_case
  },
  {
    email_address: 'unicode.test@example.com',
    password: 'password123',
    first_name: 'Ünicöde',
    last_name: 'Tëst',
    roles: [ 'viewer' ],
    category: :edge_case
  },
  {
    email_address: 'minimal@ex.co',
    password: 'password123',
    first_name: 'Min',
    last_name: 'User',
    roles: [ 'submitter' ],
    category: :edge_case
  }
]

# Build users array based on environment configuration
users_data = []
users_data.concat(admin_users) if current_config[:create_admin_users]
users_data.concat(test_users) if current_config[:create_test_users]
users_data.concat(edge_case_users) if current_config[:create_edge_case_users]

users_data.each do |user_attrs|
  user = User.find_or_create_by!(email_address: user_attrs[:email_address]) do |u|
    u.password = user_attrs[:password]
    u.first_name = user_attrs[:first_name] if user_attrs[:first_name]
    u.last_name = user_attrs[:last_name] if user_attrs[:last_name]
    u.nationbuilder_uid = user_attrs[:nationbuilder_uid] if user_attrs[:nationbuilder_uid]
  end

  # Assign roles (idempotent - won't duplicate)
  user_attrs[:roles]&.each do |role_name|
    user.add_role(role_name)
  end
end

# Output summary for developers (environment-aware)
if current_config[:verbose_output]
  puts "🌱 Seeding completed successfully!"
  puts "Environment: #{Rails.env}"
  puts "Created/verified #{Role.count} roles: #{Role.pluck(:name).join(', ')}"
  puts "Created/verified #{User.count} users with the following distribution:"
  Role.all.each do |role|
    count = role.users.count
    puts "  - #{role.name}: #{count} user#{'s' unless count == 1}"
  end
  puts "Users without roles: #{User.left_joins(:roles).where(roles: { id: nil }).count}"
  puts "\n💡 Test credentials: [email] / password123"

  if current_config[:create_edge_case_users]
    puts "🧪 Edge case users included for testing"
  end
else
  puts "Seeding completed for #{Rails.env} environment"
end
