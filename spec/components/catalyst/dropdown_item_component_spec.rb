# frozen_string_literal: true

require "rails_helper"

RSpec.describe Catalyst::DropdownItemComponent, type: :component do
  subject(:component) { described_class.new(**options) }

  let(:options) { {} }
  let(:content) { "Menu Item" }
  let(:doc) { render_component(component.with_content(content)) }

  describe "when rendered as a button" do
    it "renders a button element" do
      expect(doc).to have_css("button[type='button']")
      expect(doc).to have_css("button[data-action='dropdown#selectItem']")
      expect(doc).to have_text("Menu Item")
    end

    context "with disabled state" do
      let(:options) { { disabled: true } }

      it "applies disabled state" do
        expect(doc).to have_css("button[disabled]")
        button = doc.find("button")
        expect(button[:class]).to include("opacity-50", "cursor-not-allowed")
      end
    end
  end

  describe "when rendered as a link" do
    let(:options) { { href: "/settings" } }

    it "renders a link element" do
      expect(doc).to have_css("a[href='/settings']")
      expect(doc).to have_css("a[data-action='dropdown#selectItem']")
      expect(doc).to have_text("Menu Item")
    end

    context "with disabled flag" do
      let(:options) { { href: "/settings", disabled: true } }

      it "does not apply disabled attributes to links" do
        expect(doc).to have_css("a[href='/settings']")
        expect(doc).not_to have_css("a[disabled]")
      end
    end
  end

  describe "styling" do
    it "applies base styling classes" do
      button = doc.find("button")
      expect(button[:class]).to include(
        "rounded-lg",
        "px-3.5",
        "py-2.5",
        "hover:bg-blue-500",
        "focus:bg-blue-500"
      )
    end
  end

  describe "customization" do
    context "with custom classes" do
      let(:options) { { class: "custom-item" } }

      it "applies custom classes" do
        expect(doc).to have_css("button.custom-item")
      end
    end

    context "with additional HTML options" do
      let(:options) { { id: "custom-item", "aria-label" => "Custom action" } }

      it "merges additional HTML options" do
        expect(doc).to have_css("button#custom-item")
        expect(doc).to have_css("button[aria-label='Custom action']")
      end
    end
  end
end
