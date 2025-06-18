require 'rails_helper'

RSpec.describe "NationBuilder Profile Sync", type: :request do
  before do
    # Enable NationBuilder feature flag for tests
    FeatureFlag.find_or_create_by!(name: 'nationbuilder_signin') do |flag|
      flag.description = 'Test flag for NationBuilder OAuth'
      flag.enabled = true
    end
  end

  describe "automatic sync on login" do
    context "when using NationBuilder OAuth login" do
      it "triggers sync job after successful authentication" do
        # Mock OAuth flow
        token_service = instance_double(NationbuilderTokenExchangeService)
        allow(NationbuilderTokenExchangeService).to receive(:new).and_return(token_service)
        allow(token_service).to receive(:exchange_code_for_token).and_return({
          access_token: "test_token",
          refresh_token: "refresh_token",
          expires_in: 3600,
          scope: "default"
        })

        profile_data = {
          id: "12345",
          email: "test@example.com",
          first_name: "Test",
          last_name: "User",
          tags: [ "member" ],
          raw_data: {}
        }

        user_service = instance_double(NationbuilderUserService)
        allow(NationbuilderUserService).to receive(:new).and_return(user_service)
        allow(user_service).to receive_messages(fetch_user_profile: profile_data, find_or_create_user: create(:user, :nationbuilder_user, nationbuilder_uid: "12345"))

        expect(NationbuilderProfileSyncJob).to receive(:perform_later).with(kind_of(Integer))

        # Stub WebMock requests
        stub_request(:post, 'https://testnation.nationbuilder.com/oauth/token')
          .to_return(status: 200, body: { access_token: "test_token", refresh_token: "refresh_token", expires_in: 3600, scope: "default" }.to_json)

        stub_request(:get, 'https://testnation.nationbuilder.com/api/v1/people/me')
          .to_return(status: 200, body: { person: profile_data }.to_json)

        get "/auth/nationbuilder/callback", params: { code: "test_code" }
      end
    end

    context "when using email/password login" do
      let(:user) { create(:user, :email_password_user, password: "password", password_confirmation: "password") }

      it "does not trigger sync for non-NationBuilder users" do
        expect(NationbuilderProfileSyncJob).not_to receive(:perform_later)

        post "/session", params: {
          email_address: user.email_address,
          password: "password"
        }
      end

      it "triggers sync for users with NationBuilder connection" do
        user.update!(nationbuilder_uid: "12345")

        expect(NationbuilderProfileSyncJob).to receive(:perform_later).with(user.id)

        post "/session", params: {
          email_address: user.email_address,
          password: "password"
        }
      end
    end
  end

  describe "manual sync" do
    let(:user) { create(:user, :nationbuilder_user, password: "password", password_confirmation: "password") }

    before do
      # Sign in the user
      post "/session", params: {
        email_address: user.email_address,
        password: "password"
      }
    end

    it "allows users to manually trigger sync" do
      expect(NationbuilderProfileSyncJob).to receive(:perform_later).with(user.id)

      post "/account/nationbuilder_sync"

      expect(response).to redirect_to(user_path(user))
      expect(flash[:notice]).to eq("NationBuilder profile sync has been initiated.")
    end

    it "prevents sync for non-NationBuilder users" do
      user.update!(nationbuilder_uid: nil)

      expect(NationbuilderProfileSyncJob).not_to receive(:perform_later)

      post "/account/nationbuilder_sync"

      expect(response).to redirect_to(user_path(user))
      expect(flash[:alert]).to eq("You don't have a connected NationBuilder account.")
    end
  end
end
