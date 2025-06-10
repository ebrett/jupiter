namespace :seed do
  desc "Create test users for development and QA"
  task users: :environment do
    puts "🌱 Creating test users..."

    # Load and run the main seed file
    load Rails.root.join("db", "seeds.rb")

    puts "\n✅ User seeding completed!"
  end

  desc "Reset and reseed all test users"
  task reset_users: :environment do
    puts "🗑️  Removing existing test users..."

    # Remove existing test users (keeping any real users)
    test_emails = [
      "admin@example.com",
      "treasury@example.com",
      "chapter@example.com",
      "user1@example.com",
      "user2@example.com",
      "viewer@example.com",
      "multi@example.com",
      "qa@example.com",
      "guest@example.com",
      "long.email.address.for.testing@verylongdomainname.example.com",
      "unicode.test@exämple.com",
      "minimal@ex.co"
    ]

    User.where(email_address: test_emails).destroy_all

    puts "✅ Test users removed"
    puts "🌱 Creating fresh test users..."

    # Run the seeding
    Rake::Task["seed:users"].invoke
  end

  desc "Show current user statistics"
  task stats: :environment do
    puts "\n📊 Current User Statistics:"
    puts "=" * 50
    puts "Total users: #{User.count}"
    puts "Total roles: #{Role.count}"
    puts "Total role assignments: #{UserRole.count}"

    puts "\n🎭 Role Distribution:"
    Role.all.each do |role|
      count = role.users.count
      puts "  #{role.name.ljust(25)} #{count} user#{'s' unless count == 1}"
    end

    users_without_roles = User.left_joins(:roles).where(roles: { id: nil }).count
    puts "  #{'(no roles)'.ljust(25)} #{users_without_roles} user#{'s' unless users_without_roles == 1}"

    puts "\n👥 Test Users:"
    test_emails = [
      "admin@example.com",
      "treasury@example.com",
      "chapter@example.com",
      "user1@example.com",
      "user2@example.com",
      "viewer@example.com",
      "multi@example.com",
      "qa@example.com",
      "guest@example.com"
    ]

    test_emails.each do |email|
      user = User.find_by(email_address: email)
      if user
        roles = user.role_names.join(", ")
        roles = "(no roles)" if roles.empty?
        puts "  #{email.ljust(25)} #{roles}"
      else
        puts "  #{email.ljust(25)} ❌ Not found"
      end
    end

    puts "\n💡 Login with any email above using password: password123"
  end

  desc "Validate seed data integrity"
  task validate: :environment do
    puts "🔍 Validating seed data integrity..."

    errors = []

    # Check all users have valid emails
    User.all.each do |user|
      unless user.email_address.match?(/\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i)
        errors << "Invalid email format: #{user.email_address}"
      end
    end

    # Check all roles exist and are properly assigned
    required_roles = %w[submitter country_chapter_admin treasury_team_admin system_administrator viewer]
    required_roles.each do |role_name|
      unless Role.exists?(name: role_name)
        errors << "Missing required role: #{role_name}"
      end
    end

    # Check admin users exist
    unless User.joins(:roles).where(roles: { name: "system_administrator" }).exists?
      errors << "No system administrator user found"
    end

    if errors.empty?
      puts "✅ All validations passed!"
      puts "  - #{User.count} users validated"
      puts "  - #{Role.count} roles validated"
      puts "  - #{UserRole.count} role assignments validated"
    else
      puts "❌ Validation errors found:"
      errors.each { |error| puts "  - #{error}" }
      exit 1
    end
  end
end

# Convenience aliases
desc "Alias for seed:users"
task seed_users: "seed:users"

desc "Alias for seed:stats"
task user_stats: "seed:stats"
