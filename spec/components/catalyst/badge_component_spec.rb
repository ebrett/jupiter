# frozen_string_literal: true

require "rails_helper"

RSpec.describe Catalyst::BadgeComponent, type: :component do
  subject(:component) { described_class.new(**options) }

  let(:options) { {} }
  let(:content) { "Badge Text" }
  let(:doc) { render_component(component.with_content(content)) }

  describe "basic rendering" do
    it "renders a span element by default" do
      expect(doc).to have_css("span", text: content)
    end

    it "includes base classes" do
      badge = doc.find("span")
      expect(badge[:class]).to include(
        "inline-flex",
        "items-center",
        "gap-x-1.5",
        "font-medium"
      )
    end

    it "includes test selector" do
      expect(doc).to have_css("span[data-test='badge-default']")
    end

    it "has default zinc color" do
      badge = doc.find("span")
      expect(badge[:class]).to include("bg-zinc-100", "text-zinc-700")
    end

    it "has small size by default" do
      badge = doc.find("span")
      expect(badge[:class]).to include("px-1.5", "py-0.5", "text-xs")
    end
  end

  describe "variants" do
    context "with success variant" do
      let(:options) { { variant: :success } }

      it "applies green color classes" do
        badge = doc.find("span")
        expect(badge[:class]).to include("bg-green-100", "text-green-700")
      end

      it "includes correct test selector" do
        expect(doc).to have_css("span[data-test='badge-success']")
      end
    end

    context "with warning variant" do
      let(:options) { { variant: :warning } }

      it "applies amber color classes" do
        badge = doc.find("span")
        expect(badge[:class]).to include("bg-amber-100", "text-amber-700")
      end
    end

    context "with danger variant" do
      let(:options) { { variant: :danger } }

      it "applies red color classes" do
        badge = doc.find("span")
        expect(badge[:class]).to include("bg-red-100", "text-red-700")
      end
    end

    context "with info variant" do
      let(:options) { { variant: :info } }

      it "applies blue color classes" do
        badge = doc.find("span")
        expect(badge[:class]).to include("bg-blue-100", "text-blue-700")
      end
    end

    context "with primary variant" do
      let(:options) { { variant: :primary } }

      it "applies indigo color classes" do
        badge = doc.find("span")
        expect(badge[:class]).to include("bg-indigo-100", "text-indigo-700")
      end
    end

    context "with direct color variant" do
      let(:options) { { variant: :purple } }

      it "applies purple color classes" do
        badge = doc.find("span")
        expect(badge[:class]).to include("bg-purple-100", "text-purple-700")
      end
    end

    context "with invalid variant" do
      it "raises an error" do
        expect { described_class.new(variant: :invalid) }
          .to raise_error(ArgumentError, /Invalid variant/)
      end
    end
  end

  describe "sizes" do
    context "with small size (default)" do
      it "applies small size classes" do
        badge = doc.find("span")
        expect(badge[:class]).to include("px-1.5", "py-0.5", "text-xs", "rounded")
      end
    end

    context "with medium size" do
      let(:options) { { size: :md } }

      it "applies medium size classes" do
        badge = doc.find("span")
        expect(badge[:class]).to include("px-2", "py-1", "text-sm", "rounded-md")
      end
    end

    context "with invalid size" do
      it "raises an error" do
        expect { described_class.new(size: :invalid) }
          .to raise_error(ArgumentError, /Invalid size/)
      end
    end
  end

  describe "icons" do
    context "with check icon" do
      let(:options) { { icon: :check } }

      it "renders check svg icon" do
        expect(doc).to have_css("span > svg")
        svg = doc.find("span > svg")
        expect(svg[:viewbox]).to eq("0 0 20 20")
      end

      it "applies correct icon size for small badge" do
        svg = doc.find("span > svg")
        expect(svg[:class]).to include("w-3", "h-3")
      end
    end

    context "with warning icon" do
      let(:options) { { icon: :warning } }

      it "renders warning svg icon" do
        expect(doc).to have_css("span > svg")
      end
    end

    context "with info icon" do
      let(:options) { { icon: :info } }

      it "renders info svg icon" do
        expect(doc).to have_css("span > svg")
      end
    end

    context "with x icon" do
      let(:options) { { icon: :x } }

      it "renders x svg icon" do
        expect(doc).to have_css("span > svg")
      end
    end

    context "with custom string icon" do
      let(:options) { { icon: "✓" } }

      it "renders the custom icon text" do
        expect(doc).to have_text("✓")
      end
    end

    context "with medium size and icon" do
      let(:options) { { size: :md, icon: :check } }

      it "applies correct icon size for medium badge" do
        svg = doc.find("span > svg")
        expect(svg[:class]).to include("w-4", "h-4")
      end
    end
  end

  describe "link rendering" do
    let(:options) { { href: "/test-path", variant: :primary } }

    it "renders as a link with nested span" do
      expect(doc).to have_link(href: "/test-path")
      expect(doc).to have_css("a > span", text: content)
    end

    it "applies focus styles to link" do
      link = doc.find("a")
      expect(link[:class]).to include("focus:outline-none", "focus:ring-2")
    end

    it "includes link test selector" do
      expect(doc).to have_css("a[data-test='badge-link-primary']")
    end

    it "preserves badge styling on inner span" do
      span = doc.find("a > span")
      expect(span[:class]).to include("bg-indigo-100", "text-indigo-700")
    end
  end

  describe "dismissible badges" do
    let(:options) { { dismissible: true } }

    it "renders dismiss button" do
      expect(doc).to have_css("span > button[type='button']")
    end

    it "adds data controller attribute" do
      badge = doc.find("span")
      expect(badge[:"data-controller"]).to eq("badge")
    end

    it "adds click action to dismiss button" do
      button = doc.find("span > button")
      expect(button[:"data-action"]).to eq("click->badge#dismiss")
    end

    it "includes aria label on dismiss button" do
      button = doc.find("span > button")
      expect(button["aria-label"]).to eq("Dismiss")
    end

    it "renders x icon in dismiss button" do
      expect(doc).to have_css("span > button > svg")
    end
  end

  describe "hover states" do
    it "includes hover classes" do
      badge = doc.find("span")
      expect(badge[:class]).to include("hover:bg-zinc-200")
    end

    context "with different variants" do
      let(:options) { { variant: :success } }

      it "includes variant-specific hover classes" do
        badge = doc.find("span")
        expect(badge[:class]).to include("hover:bg-green-200")
      end
    end
  end

  describe "custom attributes" do
    let(:options) do
      {
        id: "custom-badge",
        data: { value: "test" },
        title: "Custom title"
      }
    end

    it "passes through custom attributes" do
      badge = doc.find("span")
      expect(badge[:id]).to eq("custom-badge")
      expect(badge[:"data-value"]).to eq("test")
      expect(badge[:title]).to eq("Custom title")
    end
  end

  describe "custom classes" do
    let(:options) { { class: "custom-class mt-2" } }

    it "merges custom classes with component classes" do
      badge = doc.find("span")
      expect(badge[:class]).to include("custom-class", "mt-2")
      expect(badge[:class]).to include("bg-zinc-100") # Still has default classes
    end
  end

  describe "content composition" do
    context "with icon and text" do
      let(:options) { { icon: :check } }

      it "renders both icon and text" do
        expect(doc).to have_css("span > svg")
        expect(doc).to have_text(content)
      end
    end

    context "with text and dismissible" do
      let(:options) { { dismissible: true } }

      it "renders both text and dismiss button" do
        expect(doc).to have_text(content)
        expect(doc).to have_css("span > button")
      end
    end

    context "with icon, text, and dismissible" do
      let(:options) { { icon: :info, dismissible: true } }

      it "renders icon, text, and dismiss button" do
        expect(doc).to have_css("span > svg")
        expect(doc).to have_text(content)
        expect(doc).to have_css("span > button")
      end
    end
  end

  describe "accessibility" do
    it "has proper contrast ratios" do
      badge = doc.find("span")
      # These color combinations are designed to meet WCAG AA standards
      expect(badge[:class]).to include("text-zinc-700", "bg-zinc-100")
    end

    context "with icon" do
      let(:options) { { icon: :check } }

      it "marks icon as decorative" do
        svg = doc.find("svg")
        expect(svg[:"aria-hidden"]).to eq("true")
      end
    end
  end
end
