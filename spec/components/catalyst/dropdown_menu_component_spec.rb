# frozen_string_literal: true

require "rails_helper"

RSpec.describe Catalyst::DropdownMenuComponent, type: :component do
  subject(:component) { described_class.new(**options) }

  let(:options) { {} }
  let(:content) { "Menu items" }
  let(:doc) { render_component(component.with_content(content)) }

  describe "basic rendering" do
    it "renders a dropdown menu with correct base classes" do
      expect(doc).to have_css("div[data-dropdown-target='menu']")
      expect(doc).to have_css("div.absolute.z-50.w-max.rounded-xl.p-1")
      expect(doc).to have_css("div.hidden") # Hidden by default
      expect(doc).to have_text("Menu items")
    end
  end

  describe "anchor positioning" do
    context "with bottom anchor (default)" do
      it "applies bottom positioning classes" do
        menu = doc.find("div[data-dropdown-target='menu']")
        expect(menu[:class]).to include("top-full")
      end
    end

    context "with bottom-start anchor" do
      let(:options) { { anchor: "bottom-start" } }

      it "applies bottom-start positioning classes" do
        menu = doc.find("div[data-dropdown-target='menu']")
        expect(menu[:class]).to include("top-full", "right-0")
      end
    end

    context "with bottom-end anchor" do
      let(:options) { { anchor: "bottom-end" } }

      it "applies bottom-end positioning classes" do
        menu = doc.find("div[data-dropdown-target='menu']")
        expect(menu[:class]).to include("top-full", "left-0")
      end
    end

    context "with top anchor" do
      let(:options) { { anchor: "top" } }

      it "applies top positioning classes" do
        menu = doc.find("div[data-dropdown-target='menu']")
        expect(menu[:class]).to include("bottom-full")
      end
    end

    context "with left anchor" do
      let(:options) { { anchor: "left" } }

      it "applies left positioning classes" do
        menu = doc.find("div[data-dropdown-target='menu']")
        expect(menu[:class]).to include("right-full")
      end
    end

    context "with right anchor" do
      let(:options) { { anchor: "right" } }

      it "applies right positioning classes" do
        menu = doc.find("div[data-dropdown-target='menu']")
        expect(menu[:class]).to include("left-full")
      end
    end
  end

  describe "customization" do
    context "with custom classes" do
      let(:options) { { class: "custom-menu" } }

      it "applies custom classes" do
        expect(doc).to have_css("div.custom-menu")
      end
    end

    context "with additional HTML options" do
      let(:options) { { id: "custom-menu" } }

      it "merges additional HTML options" do
        expect(doc).to have_css("div#custom-menu")
      end
    end
  end
end
