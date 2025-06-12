# frozen_string_literal: true

require "rails_helper"

RSpec.describe Catalyst::LinkComponent, type: :component do
  subject(:component) { described_class.new(**options) }

  let(:options) { { href: "/test" } }
  let(:content) { "Test Link" }
  let(:doc) { render_component(component.with_content(content)) }

  describe "basic rendering" do
    it "renders a link element" do
      expect(doc).to have_css("a[href='/test']")
      expect(doc).to have_text("Test Link")
    end

    it "applies base classes" do
      link = doc.find("a")
      expect(link[:class]).to include("transition-colors", "duration-150", "focus:outline-none")
    end
  end

  describe "variants" do
    context "with default variant" do
      it "applies default variant classes" do
        link = doc.find("a")
        expect(link[:class]).to include("text-blue-600", "hover:text-blue-800", "underline")
      end
    end

    context "with primary variant" do
      let(:options) { { href: "/test", variant: :primary } }

      it "applies primary variant classes" do
        link = doc.find("a")
        expect(link[:class]).to include("text-blue-600", "hover:text-blue-800", "font-medium")
      end
    end

    context "with secondary variant" do
      let(:options) { { href: "/test", variant: :secondary } }

      it "applies secondary variant classes" do
        link = doc.find("a")
        expect(link[:class]).to include("text-gray-600", "hover:text-gray-800")
      end
    end

    context "with muted variant" do
      let(:options) { { href: "/test", variant: :muted } }

      it "applies muted variant classes" do
        link = doc.find("a")
        expect(link[:class]).to include("text-gray-500", "hover:text-gray-700")
      end
    end

    context "with danger variant" do
      let(:options) { { href: "/test", variant: :danger } }

      it "applies danger variant classes" do
        link = doc.find("a")
        expect(link[:class]).to include("text-red-600", "hover:text-red-800")
      end
    end

    context "with plain variant" do
      let(:options) { { href: "/test", variant: :plain } }

      it "applies plain variant classes" do
        link = doc.find("a")
        expect(link[:class]).to include("text-gray-900", "hover:text-gray-700", "no-underline")
      end
    end
  end

  describe "external links" do
    context "with explicit external flag" do
      let(:options) { { href: "/test", external: true } }

      it "applies external link attributes" do
        expect(doc).to have_css("a[target='_blank']")
        expect(doc).to have_css("a[rel='noopener noreferrer']")
      end

      it "includes external link icon" do
        expect(doc).to have_css("svg")
      end
    end

    context "with external URL" do
      let(:options) { { href: "https://example.com" } }

      it "automatically detects external links" do
        expect(doc).to have_css("a[target='_blank']")
        expect(doc).to have_css("a[rel='noopener noreferrer']")
        expect(doc).to have_css("svg")
      end
    end

    context "with internal URLs" do
      it "does not apply external link attributes for internal path" do
        options = { href: "/internal" }
        doc = render_component(described_class.new(**options).with_content("Internal link"))

        expect(doc).not_to have_css("a[target='_blank']")
        expect(doc).not_to have_css("a[rel='noopener noreferrer']")
        expect(doc).not_to have_css("svg")
      end

      it "does not apply external link attributes for anchor link" do
        options = { href: "#anchor" }
        doc = render_component(described_class.new(**options).with_content("Anchor link"))

        expect(doc).not_to have_css("a[target='_blank']")
        expect(doc).not_to have_css("a[rel='noopener noreferrer']")
        expect(doc).not_to have_css("svg")
      end

      it "does not apply external link attributes for mailto link" do
        options = { href: "mailto:test@example.com" }
        doc = render_component(described_class.new(**options).with_content("Email link"))

        expect(doc).not_to have_css("a[target='_blank']")
        expect(doc).not_to have_css("a[rel='noopener noreferrer']")
        expect(doc).not_to have_css("svg")
      end

      it "does not apply external link attributes for tel link" do
        options = { href: "tel:555-1234" }
        doc = render_component(described_class.new(**options).with_content("Phone link"))

        expect(doc).not_to have_css("a[target='_blank']")
        expect(doc).not_to have_css("a[rel='noopener noreferrer']")
        expect(doc).not_to have_css("svg")
      end
    end

    context "with external flag overridden" do
      let(:options) { { href: "https://example.com", external: false } }

      it "respects the explicit external flag" do
        expect(doc).not_to have_css("a[target='_blank']")
        expect(doc).not_to have_css("a[rel='noopener noreferrer']")
        expect(doc).not_to have_css("svg")
      end
    end
  end

  describe "customization" do
    context "with custom classes" do
      let(:options) { { href: "/test", class: "custom-link" } }

      it "applies custom classes" do
        expect(doc).to have_css("a.custom-link")
      end
    end

    context "with additional HTML options" do
      let(:options) { { href: "/test", id: "custom-link", "aria-label" => "Custom link" } }

      it "merges additional HTML options" do
        expect(doc).to have_css("a#custom-link")
        expect(doc).to have_css("a[aria-label='Custom link']")
      end
    end
  end
end
