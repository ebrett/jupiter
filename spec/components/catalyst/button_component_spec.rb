# frozen_string_literal: true

require "rails_helper"

RSpec.describe Catalyst::ButtonComponent, type: :component do
  subject(:component) { described_class.new(**options) }

  let(:options) { {} }
  let(:content) { "Click me" }
  let(:doc) { render_component(component.with_content(content)) }

  describe "basic rendering" do
    it "renders a button element by default" do
      expect(doc).to have_css("button", text: content)
    end

    it "renders with default type attribute" do
      expect(doc).to have_css("button[type='button']")
    end

    it "includes base classes" do
      button = doc.find("button")
      expect(button[:class]).to include(
        "relative",
        "inline-flex",
        "items-center",
        "justify-center",
        "font-medium",
        "rounded-md"
      )
    end

    it "includes test selector" do
      expect(doc).to have_css("button[data-test='button-primary']")
    end
  end

  describe "variants" do
    context "with primary variant (default)" do
      it "applies primary solid classes" do
        button = doc.find("button")
        expect(button[:class]).to include("bg-indigo-600", "text-white")
      end
    end

    context "with secondary variant" do
      let(:options) { { variant: :secondary } }

      it "applies secondary solid classes" do
        button = doc.find("button")
        expect(button[:class]).to include("bg-gray-200", "text-gray-900")
      end

      it "includes correct test selector" do
        expect(doc).to have_css("button[data-test='button-secondary']")
      end
    end

    context "with danger variant" do
      let(:options) { { variant: :danger } }

      it "applies danger solid classes" do
        button = doc.find("button")
        expect(button[:class]).to include("bg-red-600", "text-white")
      end
    end

    context "with ghost variant" do
      let(:options) { { variant: :ghost } }

      it "applies ghost solid classes" do
        button = doc.find("button")
        expect(button[:class]).to include("bg-transparent", "text-gray-700")
      end
    end

    context "with invalid variant" do
      it "raises an error" do
        expect { described_class.new(variant: :invalid) }
          .to raise_error(ArgumentError, /Invalid variant/)
      end
    end
  end

  describe "outline style" do
    let(:options) { { outline: true } }

    it "applies outline classes for primary variant" do
      button = doc.find("button")
      expect(button[:class]).to include("border", "border-indigo-600", "text-indigo-600")
      expect(button[:class]).not_to include("bg-indigo-600")
    end

    context "with secondary variant" do
      let(:options) { { variant: :secondary, outline: true } }

      it "applies outline classes for secondary variant" do
        button = doc.find("button")
        expect(button[:class]).to include("border", "border-gray-300", "text-gray-700")
      end
    end
  end

  describe "plain style" do
    let(:options) { { plain: true } }

    it "applies plain classes for primary variant" do
      button = doc.find("button")
      expect(button[:class]).to include("text-indigo-600")
      expect(button[:class]).not_to include("bg-indigo-600", "border")
    end

    context "with danger variant" do
      let(:options) { { variant: :danger, plain: true } }

      it "applies plain classes for danger variant" do
        button = doc.find("button")
        expect(button[:class]).to include("text-red-600")
        expect(button[:class]).not_to include("bg-red-600")
      end
    end
  end

  describe "sizes" do
    context "with small size" do
      let(:options) { { size: :sm } }

      it "applies small size classes" do
        button = doc.find("button")
        expect(button[:class]).to include("px-3", "py-1.5", "text-sm")
      end
    end

    context "with medium size (default)" do
      it "applies medium size classes" do
        button = doc.find("button")
        expect(button[:class]).to include("px-4", "py-2", "text-base")
      end
    end

    context "with large size" do
      let(:options) { { size: :lg } }

      it "applies large size classes" do
        button = doc.find("button")
        expect(button[:class]).to include("px-6", "py-3", "text-lg")
      end
    end

    context "with invalid size" do
      it "raises an error" do
        expect { described_class.new(size: :invalid) }
          .to raise_error(ArgumentError, /Invalid size/)
      end
    end
  end

  describe "states" do
    context "when disabled" do
      let(:options) { { disabled: true } }

      it "adds disabled attribute" do
        expect(doc).to have_css("button[disabled]")
      end

      it "adds disabled classes" do
        button = doc.find("button")
        expect(button[:class]).to include("disabled:opacity-50", "disabled:cursor-not-allowed")
      end

      it "adds aria-disabled attribute" do
        expect(doc).to have_css("button[aria-disabled='true']")
      end
    end

    context "when loading" do
      let(:options) { { loading: true } }

      it "shows loading spinner" do
        expect(doc).to have_css("svg.animate-spin")
      end

      it "adds loading data attribute" do
        expect(doc).to have_css("button[data-loading='true']")
      end

      it "is implicitly disabled" do
        expect(doc).to have_css("button[disabled]")
      end

      it "applies loading cursor" do
        button = doc.find("button")
        expect(button[:class]).to include("cursor-wait")
      end
    end
  end

  describe "button types" do
    context "with submit type" do
      let(:options) { { type: "submit" } }

      it "renders submit button" do
        expect(doc).to have_css("button[type='submit']")
      end
    end

    context "with reset type" do
      let(:options) { { type: "reset" } }

      it "renders reset button" do
        expect(doc).to have_css("button[type='reset']")
      end
    end

    context "with invalid type" do
      it "raises an error" do
        expect { described_class.new(type: "invalid") }
          .to raise_error(ArgumentError, /Invalid type/)
      end
    end
  end

  describe "link rendering" do
    let(:options) { { href: "/test-path" } }

    it "renders as a link instead of button" do
      expect(doc).to have_link(content, href: "/test-path")
      expect(doc).not_to have_css("button")
    end

    it "applies button styling to link" do
      link = doc.find("a")
      expect(link[:class]).to include("bg-indigo-600", "text-white", "rounded-md")
    end

    it "includes link test selector" do
      expect(doc).to have_css("a[data-test='button-link-primary']")
    end

    it "does not include type attribute" do
      link = doc.find("a")
      expect(link[:type]).to be_nil
    end
  end

  describe "custom attributes" do
    let(:options) do
      {
        id: "custom-button",
        data: { turbo_method: "delete", turbo_confirm: "Are you sure?" },
        aria_label: "Delete item"
      }
    end

    it "passes through custom attributes" do
      button = doc.find("button")
      expect(button[:id]).to eq("custom-button")
      expect(button[:"data-turbo-method"]).to eq("delete")
      expect(button[:"data-turbo-confirm"]).to eq("Are you sure?")
      expect(button[:"aria-label"]).to eq("Delete item")
    end
  end

  describe "custom classes" do
    let(:options) { { class: "custom-class mt-4" } }

    it "merges custom classes with component classes" do
      button = doc.find("button")
      expect(button[:class]).to include("custom-class", "mt-4")
      expect(button[:class]).to include("bg-indigo-600") # Still has default classes
    end
  end

  describe "content wrapper" do
    it "wraps content in a flex container" do
      expect(doc).to have_css("button > span.flex.items-center.justify-center.gap-2", text: content)
    end

    context "with loading state" do
      let(:options) { { loading: true } }

      it "includes both spinner and content" do
        wrapper = doc.find("button > span")
        expect(wrapper).to have_css("svg.animate-spin")
        expect(wrapper).to have_text(content)
      end
    end
  end

  describe "accessibility" do
    it "has proper focus classes" do
      button = doc.find("button")
      expect(button[:class]).to include("focus:outline-none", "focus:ring-2", "focus:ring-offset-2")
    end

    it "includes transition for smooth interactions" do
      button = doc.find("button")
      expect(button[:class]).to include("transition-colors", "duration-200")
    end

    context "with aria attributes" do
      let(:options) { { aria_label: "Custom action", disabled: true } }

      it "applies aria attributes correctly" do
        button = doc.find("button")
        expect(button[:"aria-label"]).to eq("Custom action")
        expect(button[:"aria-disabled"]).to eq("true")
      end
    end
  end
end
