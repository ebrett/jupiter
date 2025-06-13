require 'rails_helper'

RSpec.describe NationbuilderTagsComponent, type: :component do
  let(:user) { build(:user) }

  describe "#render?" do
    context "when user is not a NationBuilder user" do
      before { allow(user).to receive(:nationbuilder_user?).and_return(false) }

      it "returns false" do
        component = described_class.new(user: user)
        expect(component.render?).to be false
      end
    end

    context "when user is a NationBuilder user but has no tags" do
      before do
        allow(user).to receive_messages(nationbuilder_user?: true, nationbuilder_tags: [])
      end

      it "returns false" do
        component = described_class.new(user: user)
        expect(component.render?).to be false
      end
    end

    context "when user is a NationBuilder user with tags" do
      before do
        allow(user).to receive_messages(nationbuilder_user?: true, nationbuilder_tags: [ "member", "volunteer" ])
      end

      it "returns true" do
        component = described_class.new(user: user)
        expect(component.render?).to be true
      end
    end
  end

  describe "#tag_color" do
    let(:component) { described_class.new(user: user) }

    it "returns green for member tags" do
      expect(component.send(:tag_color, "member")).to eq(:green)
      expect(component.send(:tag_color, "supporter")).to eq(:green)
    end

    it "returns blue for volunteer tags" do
      expect(component.send(:tag_color, "volunteer")).to eq(:blue)
      expect(component.send(:tag_color, "activist")).to eq(:blue)
    end

    it "returns purple for donor tags" do
      expect(component.send(:tag_color, "donor")).to eq(:purple)
      expect(component.send(:tag_color, "contributor")).to eq(:purple)
    end

    it "returns yellow for leader tags" do
      expect(component.send(:tag_color, "leader")).to eq(:yellow)
      expect(component.send(:tag_color, "admin")).to eq(:yellow)
    end

    it "returns gray for inactive tags" do
      expect(component.send(:tag_color, "inactive")).to eq(:gray)
      expect(component.send(:tag_color, "former")).to eq(:gray)
    end

    it "returns blue for unknown tags" do
      expect(component.send(:tag_color, "unknown_tag")).to eq(:blue)
    end
  end

  describe "#visible_tags and #hidden_tags_count" do
    let(:component) { described_class.new(user: user) }

    context "with few tags" do
      before do
        allow(user).to receive(:nationbuilder_tags).and_return([ "member", "volunteer", "donor" ])
      end

      it "shows all tags" do
        expect(component.send(:visible_tags)).to eq([ "donor", "member", "volunteer" ])
        expect(component.send(:hidden_tags_count)).to eq(0)
        expect(component.send(:show_all_tags?)).to be true
      end
    end

    context "with many tags" do
      before do
        tags = (1..15).map { |i| "tag#{i}" }
        allow(user).to receive(:nationbuilder_tags).and_return(tags)
      end

      it "limits visible tags and shows hidden count" do
        visible = component.send(:visible_tags)
        expect(visible.length).to eq(10)
        expect(component.send(:hidden_tags_count)).to eq(5)
        expect(component.send(:show_all_tags?)).to be false
      end
    end
  end

  describe "rendering" do
    before do
      allow(user).to receive(:nationbuilder_user?).and_return(true)
    end

    context "with tags" do
      before do
        allow(user).to receive(:nationbuilder_tags).and_return([ "member", "volunteer", "donor" ])
      end

      it "renders tags with badges" do
        component = described_class.new(user: user)

        render_inline(component)

        expect(page).to have_text("member")
        expect(page).to have_text("volunteer")
        expect(page).to have_text("donor")
      end
    end

    context "with many tags" do
      before do
        tags = (1..15).map { |i| "tag#{i}" }
        allow(user).to receive(:nationbuilder_tags).and_return(tags)
      end

      it "shows overflow indicator" do
        component = described_class.new(user: user)

        render_inline(component)

        expect(page).to have_text("+5 more")
      end
    end

    context "with no tags" do
      before do
        allow(user).to receive(:nationbuilder_tags).and_return([])
      end

      it "does not render" do
        component = described_class.new(user: user)

        render_inline(component)

        expect(page).not_to have_text("member")
      end
    end
  end
end
