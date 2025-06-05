require 'rails_helper'

RSpec.describe "Comprehensive Role Management Test Plan", type: :system do
  # This spec serves as a comprehensive test plan for role management
  # It covers all critical paths and ensures the system works end-to-end
  
  before { ensure_roles_exist }
  
  describe "Complete Role Management Workflow" do
    let!(:super_admin) { create_user_with_role(:super_admin, email_address: 'super@example.com') }
    let!(:new_user) { create(:user, email_address: 'newuser@example.com') }
    
    it "executes a complete role management workflow" do
      # Step 1: Login as super admin
      login_as(super_admin)
      expect(page).to have_content("Welcome")
      
      # Step 2: Navigate to admin dashboard
      visit admin_path
      expect_authorized_access
      expect(page).to have_content("Admin Dashboard")
      
      # Step 3: Access user management
      click_link "Manage Users"
      expect(current_path).to eq(admin_users_path)
      expect(page).to have_content(new_user.email_address)
      
      # Step 4: Assign initial role to user
      within_user_row(new_user) do
        click_link "Edit"
      end
      
      check "Submitter"
      click_button "Update User"
      expect(page).to have_content("User was successfully updated")
      
      # Step 5: Verify role assignment
      visit admin_user_path(new_user)
      expect(page).to have_content("submitter")
      
      # Step 6: Test role upgrade
      click_link "Edit"
      check "Country Chapter Admin"
      click_button "Update User"
      
      expect(new_user.reload.role_names).to include('submitter', 'country_chapter_admin')
      
      # Step 7: Test role-based access
      logout
      login_as(new_user)
      
      visit admin_path
      expect_authorized_access # Should have access as chapter admin
      expect(page).not_to have_link("Manage Users") # But limited permissions
      
      # Step 8: Test bulk operations
      logout
      login_as(super_admin)
      
      # Create multiple users for bulk operations
      bulk_users = 3.times.map { create(:user) }
      
      visit admin_users_path
      select_users_for_bulk_action(*bulk_users)
      perform_bulk_action("Assign Role", "Viewer")
      
      expect(page).to have_content("Role assigned to 3 users")
      
      # Step 9: Test filtering
      select "Viewer", from: "role_filter"
      click_button "Filter"
      
      bulk_users.each do |user|
        expect(page).to have_content(user.email_address)
      end
      
      # Step 10: Verify audit trail
      visit role_history_admin_user_path(new_user)
      expect(page).to have_content("Role Change History")
      expect(page).to have_content("Added role: country_chapter_admin")
    end
  end
  
  describe "Critical Path Testing" do
    context "Authentication and Authorization" do
      it "enforces role-based access at all levels" do
        users = {
          super_admin: create_user_with_role(:super_admin),
          treasury_admin: create_user_with_role(:treasury_team_admin),
          chapter_admin: create_user_with_role(:country_chapter_admin),
          submitter: create_user_with_role(:submitter),
          viewer: create_user_with_role(:viewer)
        }
        
        # Test matrix of access permissions
        access_matrix = {
          admin_path: [:super_admin, :treasury_admin, :chapter_admin],
          admin_users_path: [:super_admin],
          admin_roles_path: [:super_admin],
          admin_system_health_path: [:super_admin, :treasury_admin],
          admin_oauth_status_path: [:super_admin, :treasury_admin, :chapter_admin]
        }
        
        access_matrix.each do |path, allowed_roles|
          users.each do |role, user|
            login_as(user)
            visit send(path)
            
            if allowed_roles.include?(role)
              expect_authorized_access
            else
              expect_unauthorized_access
            end
            
            logout
          end
        end
      end
    end
    
    context "Data Integrity" do
      let(:super_admin) { create_user_with_role(:super_admin) }
      
      it "maintains data consistency across operations" do
        login_as(super_admin)
        
        # Create test user
        user = create(:user)
        
        # Assign multiple roles
        visit edit_admin_user_path(user)
        check "Submitter"
        check "Viewer"
        click_button "Update User"
        
        # Verify database state
        user.reload
        expect(user.roles.count).to eq(2)
        expect(user.role_names).to contain_exactly('submitter', 'viewer')
        
        # Remove one role
        visit edit_admin_user_path(user)
        uncheck "Submitter"
        click_button "Update User"
        
        # Verify consistency
        user.reload
        expect(user.roles.count).to eq(1)
        expect(user.role_names).to contain_exactly('viewer')
        
        # Test cascading deletes
        user_id = user.id
        user_role_count = UserRole.where(user_id: user_id).count
        
        user.destroy
        
        expect(User.exists?(user_id)).to be false
        expect(UserRole.where(user_id: user_id).count).to eq(0)
      end
    end
    
    context "Security" do
      it "prevents privilege escalation attempts" do
        regular_user = create_user_with_role(:submitter)
        super_admin = create_user_with_role(:super_admin)
        
        login_as(regular_user)
        
        # Attempt direct access to role assignment
        page.driver.submit :post, admin_user_roles_path(regular_user), {
          role: { name: 'super_admin' }
        }
        
        expect(regular_user.reload.has_role?(:super_admin)).to be false
        
        # Attempt to modify another user's roles
        page.driver.submit :post, admin_user_roles_path(super_admin), {
          role: { name: 'submitter' }
        }
        
        expect(super_admin.reload.role_names).not_to include('submitter')
      end
    end
  end
  
  describe "Performance and Scalability" do
    it "handles large numbers of users and roles efficiently" do
      super_admin = create_user_with_role(:super_admin)
      
      # Create many users
      100.times do |i|
        user = create(:user, email_address: "user#{i}@example.com")
        role = Role::ROLES.sample
        user.add_role(role)
      end
      
      login_as(super_admin)
      
      # Measure page load time
      start_time = Time.current
      visit admin_users_path
      load_time = Time.current - start_time
      
      expect(page).to have_content("Users")
      expect(load_time).to be < 3.seconds
      
      # Test search performance
      fill_in "search", with: "user50@example.com"
      click_button "Search"
      
      expect(page).to have_content("user50@example.com")
      expect(page).to have_css("tr", count: 2) # Header + 1 result
    end
  end
  
  describe "Error Handling and Recovery" do
    let(:super_admin) { create_user_with_role(:super_admin) }
    
    it "handles errors gracefully" do
      login_as(super_admin)
      
      # Test invalid user ID
      visit admin_user_path(999999)
      expect(page).to have_content("User not found")
      expect(current_path).to eq(admin_users_path)
      
      # Test concurrent modifications
      user = create_user_with_role(:submitter)
      
      # Simulate user being deleted while editing
      visit edit_admin_user_path(user)
      user.destroy
      
      check "Viewer"
      click_button "Update User"
      
      expect(page).to have_content("User not found")
      expect(current_path).to eq(admin_users_path)
    end
  end
  
  describe "Integration with Other Systems" do
    it "integrates properly with authentication system" do
      user = create(:user)
      
      # Test that roles persist across sessions
      user.add_role(:treasury_team_admin)
      
      login_as(user)
      visit admin_path
      expect_authorized_access
      
      logout
      
      # Login again and verify role persists
      login_as(user)
      visit admin_path
      expect_authorized_access
      expect(page).to have_content("Admin Dashboard")
    end
    
    it "works with OAuth-authenticated users" do
      # Create OAuth user
      oauth_user = create(:user, nationbuilder_uid: '12345')
      oauth_user.add_role(:submitter)
      
      super_admin = create_user_with_role(:super_admin)
      login_as(super_admin)
      
      visit admin_user_path(oauth_user)
      expect(page).to have_content("OAuth User")
      expect(page).to have_content("submitter")
      
      # Verify can modify OAuth user's roles
      click_link "Edit"
      check "Viewer"
      click_button "Update User"
      
      expect(oauth_user.reload.role_names).to include('submitter', 'viewer')
    end
  end
  
  describe "Compliance and Audit Requirements" do
    let(:super_admin) { create_user_with_role(:super_admin) }
    
    it "maintains complete audit trail" do
      login_as(super_admin)
      
      user = create(:user)
      
      # Perform various role operations
      visit edit_admin_user_path(user)
      check "Submitter"
      click_button "Update User"
      
      visit edit_admin_user_path(user)
      check "Viewer"
      click_button "Update User"
      
      visit edit_admin_user_path(user)
      uncheck "Submitter"
      click_button "Update User"
      
      # Check audit trail
      visit role_history_admin_user_path(user)
      
      expect(page).to have_content("Role Change History")
      expect(page).to have_content("Added role: submitter")
      expect(page).to have_content("Added role: viewer")
      expect(page).to have_content("Removed role: submitter")
      expect(page).to have_content("Changed by: #{super_admin.email_address}")
      
      # Each change should have timestamp
      expect(page).to have_css(".timestamp", minimum: 3)
    end
  end
end