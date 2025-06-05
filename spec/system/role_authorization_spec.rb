require 'rails_helper'

RSpec.describe "Role Authorization", type: :system do
  let(:super_admin) { create(:user, password: 'password123') }
  let(:treasury_admin) { create(:user, password: 'password123') }
  let(:chapter_admin) { create(:user, password: 'password123') }
  let(:submitter) { create(:user, password: 'password123') }
  let(:viewer) { create(:user, password: 'password123') }
  
  before do
    # Ensure roles exist
    Role.initialize_all
    
    # Assign roles
    super_admin.add_role(:super_admin)
    treasury_admin.add_role(:treasury_team_admin)
    chapter_admin.add_role(:country_chapter_admin)
    submitter.add_role(:submitter)
    viewer.add_role(:viewer)
  end
  
  describe "Admin dashboard access" do
    it "shows different dashboard content based on role" do
      # Super Admin sees everything
      login_as(super_admin)
      visit admin_path
      expect(page).to have_content("Admin Dashboard")
      expect(page).to have_link("Manage Users")
      expect(page).to have_link("System Configuration")
      expect(page).to have_link("Role Management")
      expect(page).to have_link("OAuth Status")
      expect(page).to have_link("System Health")
      
      # Treasury Admin sees financial and system monitoring
      login_as(treasury_admin)
      visit admin_path
      expect(page).to have_content("Admin Dashboard")
      expect(page).to have_link("System Health")
      expect(page).to have_link("OAuth Status")
      expect(page).not_to have_link("Manage Users")
      expect(page).not_to have_link("Role Management")
      
      # Chapter Admin sees limited options
      login_as(chapter_admin)
      visit admin_path
      expect(page).to have_content("Admin Dashboard")
      expect(page).not_to have_link("System Health")
      expect(page).not_to have_link("Manage Users")
      
      # Non-admins cannot access
      login_as(submitter)
      visit admin_path
      expect(page).to have_content("not authorized")
      expect(current_path).to eq(root_path)
    end
  end
  
  describe "User management permissions" do
    before do
      @target_user = create(:user)
      @target_user.add_role(:submitter)
    end
    
    it "super admin can view and edit all users" do
      login_as(super_admin)
      visit admin_users_path
      
      expect(page).to have_content(@target_user.email_address)
      
      # Can edit user
      within("tr", text: @target_user.email_address) do
        click_link "Edit"
      end
      
      fill_in "First name", with: "Updated"
      click_button "Update User"
      
      expect(page).to have_content("successfully updated")
      expect(@target_user.reload.first_name).to eq("Updated")
    end
    
    it "treasury admin can view but not edit users" do
      login_as(treasury_admin)
      visit admin_users_path
      
      expect(page).to have_content(@target_user.email_address)
      
      # Cannot see edit link
      within("tr", text: @target_user.email_address) do
        expect(page).not_to have_link("Edit")
      end
      
      # Direct access to edit is denied
      visit edit_admin_user_path(@target_user)
      expect(page).to have_content("not authorized")
    end
    
    it "submitter cannot access user management at all" do
      login_as(submitter)
      
      visit admin_users_path
      expect(page).to have_content("not authorized")
      expect(current_path).to eq(root_path)
    end
  end
  
  describe "System configuration access" do
    it "only super admin can access system configuration" do
      # Super admin has access
      login_as(super_admin)
      visit admin_system_configuration_path
      expect(page).to have_content("System Configuration")
      
      # Treasury admin denied
      login_as(treasury_admin)
      visit admin_system_configuration_path
      expect(page).to have_content("not authorized")
      
      # Chapter admin denied
      login_as(chapter_admin)
      visit admin_system_configuration_path
      expect(page).to have_content("not authorized")
    end
  end
  
  describe "OAuth status monitoring" do
    it "admins can view OAuth status" do
      # All admin types can view
      [ super_admin, treasury_admin, chapter_admin ].each do |admin|
        login_as(admin)
        visit admin_oauth_status_path
        expect(page).to have_content("OAuth Status")
        expect(page).to have_content("Token Health")
      end
      
      # Non-admins cannot
      login_as(submitter)
      visit admin_oauth_status_path
      expect(page).to have_content("not authorized")
    end
  end
  
  describe "System health monitoring" do
    it "only super admin and treasury admin can view system health" do
      # Super admin can view
      login_as(super_admin)
      visit admin_system_health_path
      expect(page).to have_content("System Health")
      
      # Treasury admin can view
      login_as(treasury_admin)
      visit admin_system_health_path
      expect(page).to have_content("System Health")
      
      # Chapter admin cannot
      login_as(chapter_admin)
      visit admin_system_health_path
      expect(page).to have_content("not authorized")
      
      # Regular users cannot
      login_as(submitter)
      visit admin_system_health_path
      expect(page).to have_content("not authorized")
    end
  end
  
  describe "Role management access" do
    it "only super admin can manage roles" do
      # Super admin can access role management
      login_as(super_admin)
      visit admin_roles_path
      expect(page).to have_content("Role Management")
      expect(page).to have_content("Assign Roles")
      
      # Other admins cannot
      login_as(treasury_admin)
      visit admin_roles_path
      expect(page).to have_content("not authorized")
      
      login_as(chapter_admin)
      visit admin_roles_path
      expect(page).to have_content("not authorized")
    end
  end
  
  describe "Profile access based on roles" do
    it "users can view their own profile regardless of role" do
      [ super_admin, treasury_admin, submitter, viewer ].each do |user|
        login_as(user)
        visit user_path(user)
        
        expect(page).to have_content(user.email_address)
        expect(page).to have_content("Profile")
      end
    end
    
    it "admins can view other users' profiles" do
      login_as(treasury_admin)
      visit user_path(submitter)
      
      expect(page).to have_content(submitter.email_address)
      expect(page).to have_content("submitter") # Should show role
    end
    
    it "non-admins cannot view other users' profiles" do
      login_as(submitter)
      visit user_path(treasury_admin)
      
      expect(page).to have_content("not authorized")
    end
  end
  
  describe "API access with roles", js: true do
    it "enforces role-based access for API endpoints" do
      # Test API access for different roles
      # This would require API endpoints to be implemented
      # Placeholder for API authorization tests
    end
  end
  
  describe "Role-based UI elements" do
    it "shows appropriate navigation based on role" do
      # Super admin sees all navigation
      login_as(super_admin)
      visit root_path
      
      within("nav") do
        expect(page).to have_link("Admin")
        expect(page).to have_link("Users")
      end
      
      # Regular user sees limited navigation
      login_as(submitter)
      visit root_path
      
      within("nav") do
        expect(page).not_to have_link("Admin")
        expect(page).not_to have_link("Users")
      end
    end
    
    it "displays role badges on user profiles" do
      login_as(super_admin)
      visit admin_user_path(treasury_admin)
      
      expect(page).to have_css(".role-badge", text: "Treasury Team Admin")
      expect(page).to have_css(".badge-admin") # Should have admin styling
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