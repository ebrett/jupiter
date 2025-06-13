# frozen_string_literal: true

require "rails_helper"

RSpec.describe Catalyst::DropdownComponent, type: :component do
  subject(:component) { described_class.new(**options) }

  let(:options) { {} }
  let(:content) { "Dropdown content" }
  let(:doc) { render_component(component.with_content(content)) }

  describe "basic rendering" do
    it "renders a dropdown container with correct attributes" do
      expect(doc).to have_css("div[data-controller='dropdown']")
      expect(doc).to have_css("div.relative.inline-block")
      expect(doc).to have_text("Dropdown content")
    end

    it "includes correct data actions for Stimulus" do
      container = doc.find("div[data-controller='dropdown']")
      expect(container["data-action"]).to include("click@window->dropdown#closeOnClickOutside")
      expect(container["data-action"]).to include("keydown@window->dropdown#keydown")
    end
  end

  describe "customization" do
    context "with custom classes" do
      let(:options) { { class: "custom-class" } }

      it "applies custom classes" do
        expect(doc).to have_css("div.relative.inline-block.custom-class")
      end
    end

    context "with additional HTML options" do
      let(:options) { { id: "custom-dropdown" } }

      it "merges additional HTML options" do
        expect(doc).to have_css("div#custom-dropdown")
      end
    end
  end
end
