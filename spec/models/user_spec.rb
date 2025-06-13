require 'rails_helper'

RSpec.describe User, type: :model do
  subject { described_class.new(email_address: '  TEST@Example.com  ', password: 'password123') }

  it 'is valid with valid attributes' do
    expect(subject).to be_valid
  end

  it 'requires email_address to be present' do
    subject.email_address = nil
    expect(subject).not_to be_valid
  end

  it 'requires email_address to be unique' do
    described_class.create!(email_address: 'test@example.com', password: 'password123')
    user2 = described_class.new(email_address: 'test@example.com', password: 'password123')
    expect(user2).not_to be_valid
  end

  it 'requires password for email/password users' do
    subject.password = nil
    expect(subject).not_to be_valid
  end

  it 'allows NationBuilder users without password' do
    nb_user = described_class.new(
      email_address: 'nb@example.com',
      nationbuilder_uid: 'nb123'
    )
    expect(nb_user).to be_valid
  end

  it 'authenticates with correct password' do
    subject.save!
    expect(subject.authenticate('password123')).to eq(subject)
    expect(subject.authenticate('wrong')).to be_falsey
  end

  it 'has many sessions' do
    assoc = described_class.reflect_on_association(:sessions)
    expect(assoc.macro).to eq :has_many
  end

  it 'normalizes email_address (downcase and strip)' do
    subject.save!
    expect(subject.reload.email_address).to eq('test@example.com')
  end

  describe "role management" do
    let(:user) { create(:user) }
    let(:admin_role) { create(:role, :system_administrator) }
    let(:submitter_role) { create(:role, :submitter) }

    describe "#has_role?" do
      it "returns true if user has the role" do
        user.roles << admin_role
        expect(user.has_role?(:system_administrator)).to be true
        expect(user.has_role?('system_administrator')).to be true
      end

      it "returns false if user doesn't have the role" do
        expect(user.has_role?(:system_administrator)).to be false
      end
    end

    describe "#add_role" do
      it "adds a role to the user" do
        admin_role # ensure role exists
        expect { user.add_role(:system_administrator) }.to change { user.roles.count }.by(1)
        expect(user.has_role?(:system_administrator)).to be true
      end

      it "doesn't add duplicate roles" do
        user.add_role(:system_administrator)
        expect { user.add_role(:system_administrator) }.not_to change { user.roles.count }
      end

      it "returns false for non-existent roles" do
        expect(user.add_role(:non_existent)).to be false
      end
    end

    describe "#remove_role" do
      before { user.roles << admin_role }

      it "removes a role from the user" do
        expect { user.remove_role(:system_administrator) }.to change { user.roles.count }.by(-1)
        expect(user.has_role?(:system_administrator)).to be false
      end

      it "returns false for non-existent roles" do
        expect(user.remove_role(:non_existent)).to be false
      end
    end

    describe "#role_names" do
      it "returns array of role names" do
        user.roles << admin_role << submitter_role
        expect(user.role_names).to contain_exactly('system_administrator', 'submitter')
      end
    end

    describe "#admin?" do
      it "returns true for system_administrator" do
        admin_role # ensure role exists
        user.add_role(:system_administrator)
        expect(user.admin?).to be true
      end

      it "returns true for treasury_team_admin" do
        create(:role, :treasury_team_admin)
        user.add_role(:treasury_team_admin)
        expect(user.admin?).to be true
      end

      it "returns true for country_chapter_admin" do
        create(:role, :country_chapter_admin)
        user.add_role(:country_chapter_admin)
        expect(user.admin?).to be true
      end

      it "returns false for non-admin roles" do
        user.add_role(:submitter)
        expect(user.admin?).to be false
      end
    end

    describe "#can_approve?" do
      it "returns true for approval roles" do
        create(:role, :country_chapter_admin)
        user.add_role(:country_chapter_admin)
        expect(user.can_approve?).to be true
      end

      it "returns false for non-approval roles" do
        user.add_role(:submitter)
        expect(user.can_approve?).to be false
      end
    end

    describe "#can_process_payments?" do
      it "returns true for treasury roles" do
        create(:role, :treasury_team_admin)
        user.add_role(:treasury_team_admin)
        expect(user.can_process_payments?).to be true
      end

      it "returns false for non-treasury roles" do
        user.add_role(:submitter)
        expect(user.can_process_payments?).to be false
      end
    end
  end

  describe "authentication methods" do
    describe "#nationbuilder_user?" do
      it "returns true for users with NationBuilder UID" do
        user = build(:user, :nationbuilder_user)
        expect(user.nationbuilder_user?).to be true
      end

      it "returns false for users without NationBuilder UID" do
        user = build(:user, :email_password_user)
        expect(user.nationbuilder_user?).to be false
      end
    end

    describe "#email_password_user?" do
      it "returns true for users with password_digest" do
        user = create(:user, :email_password_user)
        expect(user.email_password_user?).to be true
      end

      it "returns false for NationBuilder-only users" do
        user = create(:user, :nationbuilder_user)
        expect(user.email_password_user?).to be false
      end
    end

    describe "password validation" do
      it "validates password length for email/password users" do
        user = build(:user, password: "short")
        expect(user).not_to be_valid
        expect(user.errors[:password]).to include("is too short (minimum is 8 characters)")
      end

      it "doesn't validate password for NationBuilder-only users" do
        user = build(:user, :nationbuilder_user)
        expect(user).to be_valid
      end
    end
  end
end
