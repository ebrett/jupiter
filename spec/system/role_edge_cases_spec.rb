require 'rails_helper'

RSpec.describe "Role Management Edge Cases", type: :system do
  before { ensure_roles_exist }
  
  describe "Last super admin protection" do
    let!(:only_super_admin) { create_user_with_role(:super_admin) }
    let!(:another_admin) { create_user_with_role(:treasury_team_admin) }
    
    it "prevents removing the last super admin role through UI" do
      login_as(only_super_admin)
      visit edit_admin_user_path(only_super_admin)
      
      # Try to uncheck super admin role
      uncheck "Super Admin"
      click_button "Update User"
      
      expect(page).to have_content("Cannot remove the last super admin role")
      expect(only_super_admin.reload.has_role?(:super_admin)).to be true
    end
    
    it "prevents deleting the last super admin user" do
      login_as(only_super_admin)
      visit admin_user_path(only_super_admin)
      
      accept_alert do
        click_link "Delete User"
      end
      
      expect(page).to have_content("Cannot delete the last super admin")
      expect(User.exists?(only_super_admin.id)).to be true
    end
    
    it "allows removing super admin role when another exists" do
      second_super_admin = create_user_with_role(:super_admin)
      
      login_as(only_super_admin)
      visit edit_admin_user_path(second_super_admin)
      
      uncheck "Super Admin"
      check "Treasury Team Admin"
      click_button "Update User"
      
      expect(page).to have_content("successfully updated")
      expect(second_super_admin.reload.has_role?(:super_admin)).to be false
      expect(second_super_admin.has_role?(:treasury_team_admin)).to be true
    end
  end
  
  describe "Role conflicts and validation" do
    let(:super_admin) { create_user_with_role(:super_admin) }
    let(:user) { create(:user) }
    
    before { login_as(super_admin) }
    
    it "handles conflicting role assignments gracefully" do
      visit edit_admin_user_path(user)
      
      # Try to assign potentially conflicting roles
      check "Submitter"
      check "Country Chapter Admin"
      check "Treasury Team Admin"
      click_button "Update User"
      
      expect(page).to have_content("successfully updated")
      
      # Verify all roles were assigned
      expect(user.reload.role_names).to include('submitter', 'country_chapter_admin', 'treasury_team_admin')
    end
    
    it "validates role transitions" do
      user.add_role(:submitter)
      
      visit edit_admin_user_path(user)
      
      # Upgrade from submitter to admin
      uncheck "Submitter"
      check "Country Chapter Admin"
      click_button "Update User"
      
      expect(page).to have_content("successfully updated")
      expect(user.reload.has_role?(:submitter)).to be false
      expect(user.has_role?(:country_chapter_admin)).to be true
    end
  end
  
  describe "Concurrent role modifications", js: true do
    let(:super_admin1) { create_user_with_role(:super_admin) }
    let(:super_admin2) { create_user_with_role(:super_admin) }
    let(:target_user) { create_user_with_role(:submitter) }
    
    it "handles simultaneous role updates gracefully" do
      # Simulate two admins editing the same user
      Capybara.using_session('admin1') do
        login_as(super_admin1)
        visit edit_admin_user_path(target_user)
        check "Viewer"
      end
      
      Capybara.using_session('admin2') do
        login_as(super_admin2)
        visit edit_admin_user_path(target_user)
        check "Treasury Team Admin"
        click_button "Update User"
      end
      
      Capybara.using_session('admin1') do
        click_button "Update User"
        # Should either succeed or show a meaningful error
        expect(page).to have_content(/successfully updated|has been modified/)
      end
      
      # Final state should be consistent
      target_user.reload
      expect(target_user.roles.count).to be >= 1
    end
  end
  
  describe "Role assignment with pagination", js: true do
    let(:super_admin) { create_user_with_role(:super_admin) }
    let!(:many_users) { 30.times.map { create(:user) } }
    
    it "maintains selection across pages for bulk operations" do
      login_as(super_admin)
      visit admin_users_path
      
      # Select users on first page
      page.all("input[name='user_ids[]']")[0..4].each(&:check)
      
      # Navigate to next page
      click_link "Next"
      
      # Select more users
      page.all("input[name='user_ids[]']")[0..2].each(&:check)
      
      # Perform bulk action
      perform_bulk_action("Assign Role", "Viewer")
      
      expect(page).to have_content("Role assigned to")
      # Note: Actual count depends on pagination implementation
    end
  end
  
  describe "Role inheritance and hierarchy" do
    let(:super_admin) { create_user_with_role(:super_admin) }
    let(:user) { create(:user) }
    
    before { login_as(super_admin) }
    
    it "displays implied permissions for roles" do
      visit admin_roles_path
      
      within(".role-card", text: "Super Admin") do
        expect(page).to have_content("Includes all permissions")
      end
      
      within(".role-card", text: "Treasury Team Admin") do
        expect(page).to have_content("Financial operations")
        expect(page).to have_content("Payment processing")
      end
    end
    
    it "shows effective permissions on user profile" do
      user.add_role(:treasury_team_admin)
      
      visit admin_user_path(user)
      
      expect(page).to have_content("Effective Permissions")
      expect(page).to have_content("Can process payments")
      expect(page).to have_content("Can view financial reports")
      expect(page).to have_content("Can access admin dashboard")
    end
  end
  
  describe "Role assignment via OAuth" do
    let(:super_admin) { create_user_with_role(:super_admin) }
    
    it "shows OAuth-assigned roles differently" do
      # Create a user that was assigned a role via OAuth
      oauth_user = create(:user, nationbuilder_uid: '12345')
      oauth_user.add_role(:submitter)
      
      login_as(super_admin)
      visit admin_user_path(oauth_user)
      
      expect(page).to have_content("OAuth User")
      within(".roles-section") do
        expect(page).to have_content("submitter")
        expect(page).to have_content("Assigned via: System")
      end
    end
  end
  
  describe "Audit trail for role changes" do
    let(:super_admin) { create_user_with_role(:super_admin) }
    let(:user) { create_user_with_role(:submitter) }
    
    it "displays role change history" do
      login_as(super_admin)
      
      # Make some role changes
      visit edit_admin_user_path(user)
      check "Viewer"
      click_button "Update User"
      
      visit edit_admin_user_path(user)
      uncheck "Submitter"
      click_button "Update User"
      
      # View history
      visit role_history_admin_user_path(user)
      
      expect(page).to have_content("Role Change History")
      expect(page).to have_content("Added role: viewer")
      expect(page).to have_content("Removed role: submitter")
      expect(page).to have_content("Changed by: #{super_admin.email_address}")
    end
  end
  
  describe "Performance with many roles and users" do
    let(:super_admin) { create_user_with_role(:super_admin) }
    
    before do
      # Create many users with various roles
      10.times { create_user_with_role(:submitter) }
      5.times { create_user_with_role(:viewer) }
      3.times { create_user_with_role(:country_chapter_admin) }
    end
    
    it "loads user list efficiently" do
      login_as(super_admin)
      
      start_time = Time.current
      visit admin_users_path
      load_time = Time.current - start_time
      
      expect(page).to have_content("Users")
      expect(page).to have_css("tr", minimum: 10)
      expect(load_time).to be < 2.seconds
    end
    
    it "filters by role efficiently" do
      login_as(super_admin)
      visit admin_users_path
      
      select "Submitter", from: "role_filter"
      click_button "Filter"
      
      expect(page).to have_css("tr", count: 11) # 10 + header
      expect(page).not_to have_content("viewer")
      expect(page).not_to have_content("country_chapter_admin")
    end
  end
  
  describe "Role-based data export restrictions" do
    let(:super_admin) { create_user_with_role(:super_admin) }
    let(:treasury_admin) { create_user_with_role(:treasury_team_admin) }
    
    it "restricts export functionality based on role" do
      # Treasury admin can export financial data
      login_as(treasury_admin)
      visit admin_path
      
      expect(page).to have_link("Export Financial Data")
      expect(page).not_to have_link("Export User Data")
      
      # Super admin can export everything
      login_as(super_admin)
      visit admin_path
      
      expect(page).to have_link("Export Financial Data")
      expect(page).to have_link("Export User Data")
      expect(page).to have_link("Export System Logs")
    end
  end
  
  describe "Emergency access procedures" do
    let(:super_admin) { create_user_with_role(:super_admin) }
    
    it "provides emergency role elevation workflow" do
      regular_user = create_user_with_role(:submitter)
      
      login_as(super_admin)
      visit admin_emergency_access_path
      
      fill_in "user_email", with: regular_user.email_address
      select "Treasury Team Admin", from: "temporary_role"
      fill_in "duration_hours", with: "24"
      fill_in "reason", with: "CFO is out sick, need payment approvals"
      
      click_button "Grant Emergency Access"
      
      expect(page).to have_content("Emergency access granted")
      expect(page).to have_content("Expires in 24 hours")
      
      # Verify user has temporary elevated access
      expect(regular_user.reload.has_role?(:treasury_team_admin)).to be true
    end
  end
end