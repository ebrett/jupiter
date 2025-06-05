require 'rails_helper'

RSpec.describe "Role Management", type: :system do
  let(:super_admin) { create(:user, email_address: 'super@admin.com', password: 'password123') }
  let(:treasury_admin) { create(:user, email_address: 'treasury@admin.com', password: 'password123') }
  let(:regular_user) { create(:user, email_address: 'regular@user.com', password: 'password123') }
  
  before do
    # Ensure roles exist
    Role.initialize_all
    
    # Assign roles
    super_admin.add_role(:super_admin)
    treasury_admin.add_role(:treasury_team_admin)
    regular_user.add_role(:submitter)
  end
  
  describe "Role assignment by super admin" do
    before do
      login_as(super_admin)
    end
    
    it "allows super admin to assign roles to users" do
      visit admin_users_path
      expect(page).to have_content("Users")
      
      # Find the regular user row
      within("tr", text: regular_user.email_address) do
        click_link "Edit"
      end
      
      # Verify we're on the edit page
      expect(page).to have_content("Edit User")
      expect(page).to have_content(regular_user.email_address)
      
      # Check the current roles
      expect(page).to have_unchecked_field("Treasury Team Admin")
      expect(page).to have_checked_field("Submitter")
      
      # Assign new role
      check "Treasury Team Admin"
      click_button "Update User"
      
      expect(page).to have_content("User was successfully updated")
      expect(regular_user.reload.has_role?(:treasury_team_admin)).to be true
    end
    
    it "allows super admin to remove roles from users" do
      visit admin_user_path(regular_user)
      
      expect(page).to have_content("Current Roles")
      expect(page).to have_content("submitter")
      
      click_link "Edit"
      
      # Remove the submitter role
      uncheck "Submitter"
      click_button "Update User"
      
      expect(page).to have_content("User was successfully updated")
      expect(regular_user.reload.has_role?(:submitter)).to be false
    end
    
    it "prevents removing all roles from a super admin" do
      other_super_admin = create(:user)
      other_super_admin.add_role(:super_admin)
      
      visit edit_admin_user_path(other_super_admin)
      
      # Try to uncheck super admin role
      uncheck "Super Admin"
      click_button "Update User"
      
      # Should show an error
      expect(page).to have_content("Cannot remove the last super admin role")
      expect(other_super_admin.reload.has_role?(:super_admin)).to be true
    end
  end
  
  describe "Role-based access control" do
    context "as a regular user" do
      before do
        login_as(regular_user)
      end
      
      it "denies access to admin area" do
        visit admin_path
        expect(page).to have_content("You are not authorized to access the admin area")
        expect(current_path).to eq(root_path)
      end
      
      it "denies access to user management" do
        visit admin_users_path
        expect(page).to have_content("You are not authorized to access the admin area")
        expect(current_path).to eq(root_path)
      end
    end
    
    context "as a treasury admin" do
      before do
        login_as(treasury_admin)
      end
      
      it "allows access to admin dashboard" do
        visit admin_path
        expect(page).to have_content("Admin Dashboard")
        expect(page).to have_content("System Health")
      end
      
      it "allows viewing users but not editing roles" do
        visit admin_users_path
        expect(page).to have_content("Users")
        
        # Can view users
        expect(page).to have_content(regular_user.email_address)
        
        # Cannot edit user roles
        within("tr", text: regular_user.email_address) do
          expect(page).not_to have_link("Edit")
        end
      end
      
      it "can access system health monitoring" do
        visit admin_system_health_path
        expect(page).to have_content("System Health")
        expect(page).not_to have_content("not authorized")
      end
    end
    
    context "as a super admin" do
      before do
        login_as(super_admin)
      end
      
      it "has full access to all admin features" do
        visit admin_path
        expect(page).to have_content("Admin Dashboard")
        
        # Can access user management
        click_link "Manage Users"
        expect(current_path).to eq(admin_users_path)
        
        # Can access system configuration
        visit admin_path
        expect(page).to have_link("System Health")
        expect(page).to have_link("OAuth Status")
      end
    end
  end
  
  describe "Bulk role operations" do
    let!(:users_without_roles) do
      3.times.map { create(:user) }
    end
    
    before do
      login_as(super_admin)
    end
    
    it "allows bulk assignment of roles", js: true do
      visit admin_users_path
      
      # Select multiple users
      users_without_roles.each do |user|
        within("tr", text: user.email_address) do
          check "user_ids[]"
        end
      end
      
      # Select bulk action
      select "Assign Role", from: "bulk_action"
      select "Viewer", from: "role_to_assign"
      click_button "Apply to Selected"
      
      expect(page).to have_content("Role assigned to 3 users")
      
      # Verify all users have the role
      users_without_roles.each do |user|
        expect(user.reload.has_role?(:viewer)).to be true
      end
    end
    
    it "allows bulk removal of roles", js: true do
      # Give all users the same role first
      users_without_roles.each { |u| u.add_role(:viewer) }
      
      visit admin_users_path
      
      # Select users
      users_without_roles.each do |user|
        within("tr", text: user.email_address) do
          check "user_ids[]"
        end
      end
      
      # Remove role
      select "Remove Role", from: "bulk_action"
      select "Viewer", from: "role_to_remove"
      click_button "Apply to Selected"
      
      expect(page).to have_content("Role removed from 3 users")
      
      # Verify role removal
      users_without_roles.each do |user|
        expect(user.reload.has_role?(:viewer)).to be false
      end
    end
  end
  
  describe "Role filtering and search" do
    let!(:submitters) { 3.times.map { create(:user).tap { |u| u.add_role(:submitter) } } }
    let!(:viewers) { 2.times.map { create(:user).tap { |u| u.add_role(:viewer) } } }
    
    before do
      login_as(super_admin)
    end
    
    it "filters users by role" do
      visit admin_users_path
      
      # Filter by submitter role
      select "Submitter", from: "role_filter"
      click_button "Filter"
      
      # Should see submitters and the regular_user (who is also a submitter)
      expect(page).to have_content("4 users") # 3 created + regular_user
      submitters.each do |user|
        expect(page).to have_content(user.email_address)
      end
      
      # Should not see viewers
      viewers.each do |user|
        expect(page).not_to have_content(user.email_address)
      end
    end
    
    it "searches users by email and shows their roles" do
      visit admin_users_path
      
      fill_in "search", with: viewers.first.email_address
      click_button "Search"
      
      expect(page).to have_content(viewers.first.email_address)
      expect(page).to have_content("viewer")
      
      # Should not see other users
      expect(page).not_to have_content(submitters.first.email_address)
    end
  end
  
  describe "Role hierarchy display" do
    before do
      login_as(super_admin)
    end
    
    it "displays role hierarchy and permissions" do
      visit admin_roles_path
      
      expect(page).to have_content("Role Management")
      
      # Check role hierarchy is displayed
      expect(page).to have_content("Super Admin")
      expect(page).to have_content("Full system access")
      
      expect(page).to have_content("Treasury Team Admin")
      expect(page).to have_content("Can process payments")
      
      expect(page).to have_content("Country Chapter Admin")
      expect(page).to have_content("Can approve/deny requests")
      
      # Verify permissions are listed
      within(".role-card", text: "Super Admin") do
        expect(page).to have_content("User Management")
        expect(page).to have_content("System Configuration")
        expect(page).to have_content("Role Assignment")
      end
    end
    
    it "shows user count for each role" do
      visit admin_roles_path
      
      within(".role-card", text: "Super Admin") do
        expect(page).to have_content("1 user") # Only our super_admin
      end
      
      within(".role-card", text: "Treasury Team Admin") do
        expect(page).to have_content("1 user") # Only treasury_admin
      end
      
      within(".role-card", text: "Submitter") do
        expect(page).to have_content("1 user") # Only regular_user
      end
    end
  end
  
  private
  
  def login_as(user)
    visit new_session_path
    fill_in "Email", with: user.email_address
    fill_in "Password", with: "password123"
    click_button "Sign in"
  end
end