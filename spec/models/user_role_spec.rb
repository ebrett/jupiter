require 'rails_helper'

RSpec.describe UserRole, type: :model do
  describe "associations" do
    it "belongs to user" do
      expect(described_class.reflect_on_association(:user)).to be_present
    end

    it "belongs to role" do
      expect(described_class.reflect_on_association(:role)).to be_present
    end
  end

  describe "validations" do
    let(:user) { create(:user) }
    let(:role) { create(:role, :submitter) }

    it "creates valid user role association" do
      user_role = described_class.new(user: user, role: role)
      expect(user_role).to be_valid
    end
  end
end
