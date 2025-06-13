# frozen_string_literal: true

require "rails_helper"

RSpec.describe Catalyst::DropdownButtonComponent, type: :component do
  subject(:component) { described_class.new(**options) }

  let(:options) { {} }
  let(:content) { "Open Menu" }
  let(:doc) { render_component(component.with_content(content)) }

  describe "basic rendering" do
    it "renders a button with dropdown functionality" do
      expect(doc).to have_css("button[type='button']")
      expect(doc).to have_css("button[data-action='dropdown#toggle']")
      expect(doc).to have_css("button[data-dropdown-target='button']")
      expect(doc).to have_text("Open Menu")
    end

    it "includes chevron icon" do
      expect(doc).to have_css("svg")
    end
  end

  describe "variants" do
    context "with primary variant (default)" do
      it "applies primary variant classes" do
        button = doc.find("button")
        expect(button[:class]).to include("bg-zinc-950")
      end
    end

    context "with secondary variant" do
      let(:options) { { variant: :secondary } }

      it "applies secondary variant classes" do
        button = doc.find("button")
        expect(button[:class]).to include("border-zinc-950/10")
      end
    end

    context "with outline variant" do
      let(:options) { { variant: :outline } }

      it "applies outline variant classes" do
        button = doc.find("button")
        expect(button[:class]).to include("border-zinc-950/20")
      end
    end

    context "with ghost variant" do
      let(:options) { { variant: :ghost } }

      it "applies ghost variant classes" do
        button = doc.find("button")
        expect(button[:class]).to include("border-transparent")
      end
    end
  end

  describe "sizes" do
    context "with extra small size" do
      let(:options) { { size: :xs } }

      it "applies xs size classes" do
        button = doc.find("button")
        expect(button[:class]).to include("px-2")
      end
    end

    context "with small size" do
      let(:options) { { size: :sm } }

      it "applies sm size classes" do
        button = doc.find("button")
        expect(button[:class]).to include("px-2.5")
      end
    end

    context "with large size" do
      let(:options) { { size: :lg } }

      it "applies lg size classes" do
        button = doc.find("button")
        expect(button[:class]).to include("px-4")
      end
    end

    context "with extra large size" do
      let(:options) { { size: :xl } }

      it "applies xl size classes" do
        button = doc.find("button")
        expect(button[:class]).to include("px-5")
      end
    end
  end

  describe "customization" do
    context "with custom classes" do
      let(:options) { { class: "custom-button" } }

      it "applies custom classes" do
        expect(doc).to have_css("button.custom-button")
      end
    end

    context "with additional HTML options" do
      let(:options) { { id: "custom-id", "aria-label" => "Open options" } }

      it "merges additional HTML options" do
        expect(doc).to have_css("button#custom-id")
        expect(doc).to have_css("button[aria-label='Open options']")
      end
    end
  end
end
