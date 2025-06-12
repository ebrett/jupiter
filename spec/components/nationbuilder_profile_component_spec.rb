require 'rails_helper'

RSpec.describe NationbuilderProfileComponent, type: :component do
  let(:user) { build(:user) }

  describe "#render?" do
    context "when user is not a NationBuilder user" do
      before { allow(user).to receive(:nationbuilder_user?).and_return(false) }

      it "returns false" do
        component = described_class.new(user: user)
        expect(component.render?).to be false
      end
    end

    context "when user is a NationBuilder user but has no profile data" do
      before do
        allow(user).to receive_messages(nationbuilder_user?: true, has_nationbuilder_profile_data?: false)
      end

      it "returns false" do
        component = described_class.new(user: user)
        expect(component.render?).to be false
      end
    end

    context "when user is a NationBuilder user with profile data" do
      before do
        allow(user).to receive_messages(nationbuilder_user?: true, has_nationbuilder_profile_data?: true)
      end

      it "returns true" do
        component = described_class.new(user: user)
        expect(component.render?).to be true
      end
    end
  end

  describe "#profile_sections" do
    before do
      allow(user).to receive_messages(nationbuilder_user?: true, has_nationbuilder_profile_data?: true, nationbuilder_phone: "+1 555-123-4567", nationbuilder_tags: [ "member", "volunteer" ], nationbuilder_uid: "12345", nationbuilder_profile_data: {
        "last_synced_at" => 2.hours.ago.iso8601
      })
    end

    let(:component) { described_class.new(user: user) }

    it "includes contact info section when phone is present" do
      sections = component.send(:profile_sections)
      contact_section = sections.find { |s| s[:title] == "Contact Information" }

      expect(contact_section).to be_present
      expect(contact_section[:items]).to include(
        hash_including(label: "Phone", value: "+1 555-123-4567")
      )
    end

    it "includes tags section when tags are present" do
      sections = component.send(:profile_sections)
      tags_section = sections.find { |s| s[:title] == "Tags" }

      expect(tags_section).to be_present
    end

    it "includes sync info section" do
      sections = component.send(:profile_sections)
      sync_section = sections.find { |s| s[:title] == "Sync Information" }

      expect(sync_section).to be_present
      expect(sync_section[:items]).to include(
        hash_including(label: "NationBuilder ID", value: "12345")
      )
    end
  end

  describe "rendering" do
    before do
      allow(user).to receive_messages(nationbuilder_user?: true, has_nationbuilder_profile_data?: true, nationbuilder_phone: "+1 555-123-4567", nationbuilder_tags: [ "member", "volunteer" ], nationbuilder_uid: "12345", nationbuilder_profile_data: {
        "last_synced_at" => 2.hours.ago.iso8601
      })
    end

    it "renders the component with profile data" do
      component = described_class.new(user: user)

      render_inline(component)

      expect(page).to have_text("NationBuilder Profile")
      expect(page).to have_text("Connected")
      expect(page).to have_text("Contact Information")
      expect(page).to have_text("+1 555-123-4567")
      expect(page).to have_text("NationBuilder ID")
      expect(page).to have_text("12345")
    end

    context "when user has no profile data" do
      before do
        allow(user).to receive(:has_nationbuilder_profile_data?).and_return(false)
      end

      it "does not render" do
        component = described_class.new(user: user)

        render_inline(component)

        expect(page).not_to have_text("NationBuilder Profile")
      end
    end
  end
end
