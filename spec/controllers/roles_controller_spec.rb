require 'rails_helper'

RSpec.describe RolesController, type: :controller do
  let(:system_administrator) { create(:user, :with_system_administrator_role) }

  before do
    # Set up authentication
    session = system_administrator.sessions.create!(user_agent: 'test', ip_address: '127.0.0.1')
    cookies.signed[:session_id] = session.id
  end

  describe "GET #index" do
    let!(:admin_role) { create(:role, name: 'system_administrator', description: 'System Administrator role') }
    let!(:submitter_role) { create(:role, name: 'submitter', description: 'Submitter role') }
    let!(:admin_user) { create(:user) }
    let!(:regular_user) { create(:user) }

    before do
      admin_user.user_roles.create!(role: admin_role)
      regular_user.user_roles.create!(role: submitter_role)
    end

    it "returns successful response" do
      get :index
      expect(response).to have_http_status(:success)
    end

    it "assigns roles and role statistics" do
      get :index
      expect(assigns(:roles)).to be_present
      expect(assigns(:role_stats)).to be_a(Hash)
    end

    it "calculates correct role statistics" do
      get :index
      role_stats = assigns(:role_stats)

      # Should have stats for each role
      expect(role_stats[admin_role.name]).to be_present
      expect(role_stats[submitter_role.name]).to be_present

      # Check that statistics are calculated
      total_users = User.count
      admin_user_count = admin_role.users.count
      submitter_user_count = submitter_role.users.count

      expected_admin_percentage = (admin_user_count.to_f / total_users * 100).round(1)
      expected_submitter_percentage = (submitter_user_count.to_f / total_users * 100).round(1)

      expect(role_stats[admin_role.name][:user_count]).to eq(admin_user_count)
      expect(role_stats[admin_role.name][:percentage]).to eq(expected_admin_percentage)

      expect(role_stats[submitter_role.name][:user_count]).to eq(submitter_user_count)
      expect(role_stats[submitter_role.name][:percentage]).to eq(expected_submitter_percentage)
    end

    it "handles zero users gracefully" do
      # Create a role with no users
      empty_role = create(:role, name: 'viewer', description: 'Viewer role')

      get :index
      role_stats = assigns(:role_stats)

      expect(role_stats[empty_role.name][:user_count]).to eq(0)
      expect(role_stats[empty_role.name][:percentage]).to eq(0.0)
    end

    it "renders the correct template" do
      get :index
      expect(response).to render_template("roles/index")
    end
  end
end
