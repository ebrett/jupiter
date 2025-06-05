require 'rails_helper'

RSpec.describe "Role Management API", type: :request do
  let(:super_admin) { create(:user) }
  let(:treasury_admin) { create(:user) }
  let(:regular_user) { create(:user) }
  let(:target_user) { create(:user) }
  
  before do
    # Ensure roles exist
    Role.initialize_all
    
    # Assign roles
    super_admin.add_role(:super_admin)
    treasury_admin.add_role(:treasury_team_admin)
    regular_user.add_role(:submitter)
  end
  
  def sign_in(user)
    post session_path, params: { 
      email_address: user.email_address, 
      password: user.password 
    }
  end
  
  describe "POST /admin/users/:id/roles" do
    context "as super admin" do
      before { sign_in(super_admin) }
      
      it "assigns a role to a user" do
        expect {
          post admin_user_roles_path(target_user), params: {
            role: { name: 'viewer' }
          }
        }.to change { target_user.roles.count }.by(1)
        
        expect(response).to have_http_status(:redirect)
        expect(target_user.reload.has_role?(:viewer)).to be true
        expect(flash[:notice]).to eq("Role successfully assigned")
      end
      
      it "returns error for invalid role" do
        post admin_user_roles_path(target_user), params: {
          role: { name: 'invalid_role' }
        }
        
        expect(response).to have_http_status(:unprocessable_entity)
        expect(flash[:alert]).to include("Invalid role")
      end
      
      it "prevents duplicate role assignment" do
        target_user.add_role(:viewer)
        
        expect {
          post admin_user_roles_path(target_user), params: {
            role: { name: 'viewer' }
          }
        }.not_to change { target_user.roles.count }
        
        expect(flash[:alert]).to eq("User already has this role")
      end
    end
    
    context "as non-super admin" do
      before { sign_in(treasury_admin) }
      
      it "denies access" do
        post admin_user_roles_path(target_user), params: {
          role: { name: 'viewer' }
        }
        
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to include("not authorized")
      end
    end
  end
  
  describe "DELETE /admin/users/:id/roles/:role_id" do
    let(:role) { Role.find_by(name: 'viewer') }
    
    before { target_user.add_role(:viewer) }
    
    context "as super admin" do
      before { sign_in(super_admin) }
      
      it "removes a role from a user" do
        expect {
          delete admin_user_role_path(target_user, role)
        }.to change { target_user.roles.count }.by(-1)
        
        expect(response).to have_http_status(:redirect)
        expect(target_user.reload.has_role?(:viewer)).to be false
        expect(flash[:notice]).to eq("Role successfully removed")
      end
      
      it "prevents removing the last super admin role" do
        # Make target_user the only super admin
        super_admin.remove_role(:super_admin)
        target_user.add_role(:super_admin)
        
        delete admin_user_role_path(target_user, Role.find_by(name: 'super_admin'))
        
        expect(response).to have_http_status(:unprocessable_entity)
        expect(flash[:alert]).to include("Cannot remove the last super admin")
        expect(target_user.reload.has_role?(:super_admin)).to be true
      end
    end
    
    context "as non-super admin" do
      before { sign_in(treasury_admin) }
      
      it "denies access" do
        delete admin_user_role_path(target_user, role)
        
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to include("not authorized")
      end
    end
  end
  
  describe "POST /admin/users/bulk_assign_roles" do
    let(:users) { create_list(:user, 3) }
    
    context "as super admin" do
      before { sign_in(super_admin) }
      
      it "assigns roles to multiple users" do
        user_ids = users.map(&:id)
        
        post bulk_assign_roles_admin_users_path, params: {
          user_ids: user_ids,
          role: 'viewer'
        }
        
        expect(response).to have_http_status(:redirect)
        expect(flash[:notice]).to include("Role assigned to 3 users")
        
        users.each do |user|
          expect(user.reload.has_role?(:viewer)).to be true
        end
      end
      
      it "skips users who already have the role" do
        users.first.add_role(:viewer)
        
        post bulk_assign_roles_admin_users_path, params: {
          user_ids: users.map(&:id),
          role: 'viewer'
        }
        
        expect(flash[:notice]).to include("Role assigned to 2 users")
        expect(flash[:notice]).to include("1 user already had the role")
      end
      
      it "validates role name" do
        post bulk_assign_roles_admin_users_path, params: {
          user_ids: users.map(&:id),
          role: 'invalid_role'
        }
        
        expect(response).to have_http_status(:unprocessable_entity)
        expect(flash[:alert]).to include("Invalid role")
      end
    end
  end
  
  describe "POST /admin/users/bulk_remove_roles" do
    let(:users) { create_list(:user, 3) }
    
    before do
      users.each { |u| u.add_role(:viewer) }
    end
    
    context "as super admin" do
      before { sign_in(super_admin) }
      
      it "removes roles from multiple users" do
        post bulk_remove_roles_admin_users_path, params: {
          user_ids: users.map(&:id),
          role: 'viewer'
        }
        
        expect(response).to have_http_status(:redirect)
        expect(flash[:notice]).to include("Role removed from 3 users")
        
        users.each do |user|
          expect(user.reload.has_role?(:viewer)).to be false
        end
      end
      
      it "prevents removing critical roles" do
        # Make one user a super admin
        users.first.add_role(:super_admin)
        
        post bulk_remove_roles_admin_users_path, params: {
          user_ids: [ users.first.id ],
          role: 'super_admin'
        }
        
        expect(response).to have_http_status(:unprocessable_entity)
        expect(flash[:alert]).to include("Cannot perform this operation")
      end
    end
  end
  
  describe "GET /admin/roles" do
    context "as super admin" do
      before { sign_in(super_admin) }
      
      it "displays all roles with user counts" do
        get admin_roles_path
        
        expect(response).to have_http_status(:success)
        expect(response.body).to include("Role Management")
        
        Role::ROLES.each do |role_name|
          expect(response.body).to include(role_name)
        end
      end
      
      it "returns JSON when requested" do
        get admin_roles_path, headers: { 'Accept' => 'application/json' }
        
        expect(response).to have_http_status(:success)
        
        json = JSON.parse(response.body)
        expect(json['roles']).to be_an(Array)
        expect(json['roles'].length).to eq(Role::ROLES.length)
        
        # Check role structure
        role_data = json['roles'].first
        expect(role_data).to have_key('name')
        expect(role_data).to have_key('description')
        expect(role_data).to have_key('user_count')
      end
    end
    
    context "as non-super admin" do
      before { sign_in(treasury_admin) }
      
      it "denies access" do
        get admin_roles_path
        
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to include("not authorized")
      end
    end
  end
  
  describe "GET /admin/users/:id/role_history" do
    before do
      # Create role change history
      target_user.add_role(:submitter)
      target_user.add_role(:viewer)
      target_user.remove_role(:submitter)
    end
    
    context "as admin" do
      before { sign_in(super_admin) }
      
      it "shows role change history for a user" do
        get role_history_admin_user_path(target_user)
        
        expect(response).to have_http_status(:success)
        expect(response.body).to include("Role History")
        expect(response.body).to include("submitter")
        expect(response.body).to include("viewer")
      end
    end
  end
  
  describe "Role validation in user updates" do
    context "when updating user through admin panel" do
      before { sign_in(super_admin) }
      
      it "validates role assignments during user update" do
        patch admin_user_path(target_user), params: {
          user: {
            email_address: target_user.email_address,
            role_ids: [ Role.find_by(name: 'viewer').id, Role.find_by(name: 'submitter').id ]
          }
        }
        
        expect(response).to have_http_status(:redirect)
        expect(target_user.reload.role_names).to contain_exactly('viewer', 'submitter')
      end
      
      it "prevents invalid role assignments" do
        patch admin_user_path(target_user), params: {
          user: {
            role_ids: [ 999999 ] # Non-existent role ID
          }
        }
        
        expect(response).to have_http_status(:unprocessable_entity)
        expect(flash[:alert]).to include("Invalid role")
      end
    end
  end
  
  describe "Role-based filtering" do
    let!(:viewers) { create_list(:user, 2).each { |u| u.add_role(:viewer) } }
    let!(:submitters) { create_list(:user, 3).each { |u| u.add_role(:submitter) } }
    
    context "as admin" do
      before { sign_in(super_admin) }
      
      it "filters users by role" do
        get admin_users_path, params: { role: 'viewer' }
        
        expect(response).to have_http_status(:success)
        
        viewers.each do |user|
          expect(response.body).to include(user.email_address)
        end
        
        submitters.each do |user|
          expect(response.body).not_to include(user.email_address)
        end
      end
      
      it "returns filtered results as JSON" do
        get admin_users_path, params: { role: 'viewer' }, 
            headers: { 'Accept' => 'application/json' }
        
        json = JSON.parse(response.body)
        expect(json['users'].length).to eq(2)
      end
    end
  end
  
  describe "Role permissions check endpoint" do
    context "checking user permissions" do
      before { sign_in(regular_user) }
      
      it "returns current user's permissions" do
        get permissions_api_user_path(regular_user)
        
        expect(response).to have_http_status(:success)
        
        json = JSON.parse(response.body)
        expect(json['roles']).to include('submitter')
        expect(json['permissions']).to include('create_request')
        expect(json['permissions']).not_to include('manage_users')
      end
    end
  end
end