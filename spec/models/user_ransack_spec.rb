require 'rails_helper'

RSpec.describe User, type: :model do
  describe "Ransack search functionality" do
    let(:user) { create(:user, email_address: "test@example.com", first_name: "John", last_name: "Doe") }

    before do
      user # create the user
    end

    context "when ransackable_attributes is properly defined" do
      it "allows searching by email_address_cont" do
        expect {
          search = described_class.ransack(email_address_cont: "test")
          search.result
        }.not_to raise_error
      end

      it "allows searching by first_name_cont" do
        expect {
          search = described_class.ransack(first_name_cont: "John")
          search.result
        }.not_to raise_error
      end

      it "allows searching by last_name_cont" do
        expect {
          search = described_class.ransack(last_name_cont: "Doe")
          search.result
        }.not_to raise_error
      end

      it "can find users by email search" do
        search = described_class.ransack(email_address_cont: "test")
        results = search.result
        expect(results).to include(user)
      end

      it "can find users by first name search" do
        search = described_class.ransack(first_name_cont: "John")
        results = search.result
        expect(results).to include(user)
      end
    end

    context "when using search in admin users controller" do
      let(:admin_user) { create(:user, :with_super_admin_role) }

      before do
        session = admin_user.sessions.create!(user_agent: 'test', ip_address: '127.0.0.1')
        # Simulate the controller context where ransack would be called
      end

      it "works correctly in the admin users index page context" do
        expect {
          # This mimics the line in Admin::UsersController#index:
          # @q = policy_scope(User).ransack(params[:q])
          search = described_class.ransack(email_address_cont: "test")
          search.result.includes(:roles)
        }.not_to raise_error
      end
    end
  end
end
