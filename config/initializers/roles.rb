# frozen_string_literal: true

# Ensure basic roles exist in the database
Rails.application.config.after_initialize do
  # Only run in contexts where ActiveRecord is available
  next unless defined?(ActiveRecord::Base)

  begin
    # Check if database is connected and exists
    next unless ActiveRecord::Base.connected?
    next unless ActiveRecord::Base.connection.data_source_exists?("roles")
  rescue ActiveRecord::NoDatabaseError, ActiveRecord::ConnectionNotEstablished
    # Skip if database doesn't exist or isn't connected
    next
  end

  # Create default roles if they don't exist
  Role::ROLES.each do |role_name|
    role_description = case role_name
    when "submitter"
      "Can create and submit reimbursement requests"
    when "country_chapter_admin"
      "Can approve/deny requests for their region"
    when "treasury_team_admin"
      "Can process payments and manage financial operations"
    when "system_administrator"
      "Full system access and user management"
    when "viewer"
      "Read-only access to view requests and reports"
    else
      "Role: #{role_name}"
    end

    Role.find_or_create_by(name: role_name) do |role|
      role.description = role_description
    end
  end
end
