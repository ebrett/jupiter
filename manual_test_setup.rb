# Manual Testing Setup Script

puts "Setting up test data for manual testing..."

# Find or create test users
user = User.find_by(email_address: 'test@example.com') || User.create!(
  email_address: 'test@example.com',
  password: 'password123',
  password_confirmation: 'password123',
  first_name: 'Test',
  last_name: 'User'
)

# Ensure user has submitter role
user.add_role('submitter') unless user.has_role?('submitter')
puts "Found/created user: #{user.email_address} with roles: #{user.role_names.join(', ')}"

# Find or create treasury admin user
admin = User.find_by(email_address: 'admin@example.com') || User.create!(
  email_address: 'admin@example.com',
  password: 'password123',
  password_confirmation: 'password123',
  first_name: 'Admin',
  last_name: 'User'
)

admin.add_role('treasury_team_admin') unless admin.has_role?('treasury_team_admin')
puts "Found/created admin: #{admin.email_address} with roles: #{admin.role_names.join(', ')}"

# Create some test reimbursement requests
requests = [
  {
    title: 'Conference Travel Expenses',
    description: 'Flight and hotel for Democrats Abroad conference in Berlin',
    amount_cents: 75000,
    category: 'travel',
    priority: 'normal'
  },
  {
    title: 'Office Supplies',
    description: 'Printer paper, ink cartridges, and promotional materials',
    amount_cents: 15000,
    category: 'supplies',
    priority: 'low'
  },
  {
    title: 'Urgent Event Costs',
    description: 'Last-minute venue rental for emergency town hall',
    amount_cents: 120000,
    category: 'events',
    priority: 'urgent'
  }
]

created_requests = []
requests.each_with_index do |req_data, index|
  request = ReimbursementRequest.create!(
    user: user,
    title: req_data[:title],
    description: req_data[:description],
    amount_cents: req_data[:amount_cents],
    currency: 'USD',
    expense_date: (index + 1).weeks.ago.to_date,
    category: req_data[:category],
    priority: req_data[:priority]
  )
  created_requests << request
  puts "Created request: #{request.title} (ID: #{request.id}) - Status: #{request.status}"
end

# Submit one of the requests
if created_requests.length > 0
  request_to_submit = created_requests.first
  request_to_submit.submit!(user)
  puts "Submitted request: #{request_to_submit.title} - New status: #{request_to_submit.status}"
end

puts "\n=== Manual Testing Summary ==="
puts "Users created:"
puts "  - test@example.com (password: password123) - Submitter role"
puts "  - admin@example.com (password: password123) - Treasury admin role"
puts "\nReimbursement requests: #{ReimbursementRequest.count} total"
puts "  - #{ReimbursementRequest.where(status: 'draft').count} draft requests"
puts "  - #{ReimbursementRequest.where(status: 'submitted').count} submitted requests"

puts "\n=== Testing Commands ==="
puts "Start server: bin/rails server"
puts "Rails console: bin/rails console"
puts "Run tests: bin/rspec spec/requests/reimbursement_requests_simple_spec.rb"
