require 'rails_helper'

RSpec.describe Role, type: :model do
  describe "validations" do
    it "validates presence of name" do
      role = described_class.new(description: "Test description")
      expect(role).not_to be_valid
      expect(role.errors[:name]).to include("can't be blank")
    end

    it "validates presence of description" do
      role = described_class.new(name: "submitter")
      expect(role).not_to be_valid
      expect(role.errors[:description]).to include("can't be blank")
    end

    it "validates uniqueness of name" do
      create(:role, name: "submitter")
      role = described_class.new(name: "submitter", description: "Test")
      expect(role).not_to be_valid
      expect(role.errors[:name]).to include("has already been taken")
    end

    it "validates inclusion of name in ROLES" do
      role = described_class.new(name: "invalid_role", description: "Test")
      expect(role).not_to be_valid
      expect(role.errors[:name]).to include("is not included in the list")
    end
  end

  describe "associations" do
    let(:role) { create(:role) }

    it "has many user_roles" do
      expect(role).to respond_to(:user_roles)
    end

    it "has many users through user_roles" do
      expect(role).to respond_to(:users)
    end
  end

  describe "constants" do
    it "defines ROLES constant with expected values" do
      expect(Role::ROLES).to contain_exactly(
        'submitter',
        'country_chapter_admin',
        'treasury_team_admin',
        'super_admin',
        'viewer'
      )
    end
  end

  describe "scopes" do
    let!(:submitter) { create(:role, :submitter) }
    let!(:admin) { create(:role, :super_admin) }

    it "orders roles by name with by_hierarchy scope" do
      expect(described_class.by_hierarchy.to_a).to eq([ submitter, admin ])
    end
  end

  describe "factory" do
    it "creates a valid role" do
      role = build(:role)
      expect(role).to be_valid
    end

    it "creates roles with specific traits" do
      admin_role = create(:role, :super_admin)
      expect(admin_role.name).to eq('super_admin')
      expect(admin_role.description).to include('Full system access')
    end
  end
end
