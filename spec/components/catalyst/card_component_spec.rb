# frozen_string_literal: true

require "rails_helper"

RSpec.describe Catalyst::CardComponent, type: :component do
  subject(:component) { described_class.new(**options) }

  let(:options) { {} }
  let(:content) { "Card content" }
  let(:doc) { render_component(component.with_content(content)) }

  describe "basic rendering" do
    it "renders a card div" do
      expect(doc).to have_css("div[data-test='card']")
    end

    it "renders card body" do
      expect(doc).to have_css("div[data-test='card-body']", text: "Card content")
    end

    it "applies default styling" do
      card = doc.find("div[data-test='card']")
      expect(card[:class]).to include("bg-white", "rounded-lg", "border", "border-gray-200", "shadow", "p-6")
    end
  end

  describe "variants" do
    context "default variant" do
      let(:options) { { variant: :default } }

      it "applies default border styling" do
        card = doc.find("div[data-test='card']")
        expect(card[:class]).to include("border", "border-gray-200")
      end
    end

    context "outlined variant" do
      let(:options) { { variant: :outlined } }

      it "applies outlined styling" do
        card = doc.find("div[data-test='card']")
        expect(card[:class]).to include("border", "border-gray-200")
      end
    end

    context "elevated variant" do
      let(:options) { { variant: :elevated } }

      it "applies elevated styling without border" do
        card = doc.find("div[data-test='card']")
        expect(card[:class]).to include("border-0")
        expect(card[:class]).not_to include("border-gray-200")
      end
    end

    context "ghost variant" do
      let(:options) { { variant: :ghost } }

      it "applies ghost styling" do
        card = doc.find("div[data-test='card']")
        expect(card[:class]).to include("bg-transparent", "shadow-none", "border-0")
      end
    end
  end

  describe "padding options" do
    context "none padding" do
      let(:options) { { padding: :none } }

      it "applies no padding to card" do
        card = doc.find("div[data-test='card']")
        expect(card[:class]).to include("p-0")
      end
    end

    context "small padding" do
      let(:options) { { padding: :sm } }

      it "applies small padding" do
        card = doc.find("div[data-test='card']")
        expect(card[:class]).to include("p-4")
      end
    end

    context "large padding" do
      let(:options) { { padding: :lg } }

      it "applies large padding" do
        card = doc.find("div[data-test='card']")
        expect(card[:class]).to include("p-8")
      end
    end

    context "extra large padding" do
      let(:options) { { padding: :xl } }

      it "applies extra large padding" do
        card = doc.find("div[data-test='card']")
        expect(card[:class]).to include("p-12")
      end
    end

    context "default padding" do
      let(:options) { { padding: :default } }

      it "applies default padding" do
        card = doc.find("div[data-test='card']")
        expect(card[:class]).to include("p-6")
      end
    end
  end

  describe "shadow options" do
    context "no shadow" do
      let(:options) { { shadow: :none } }

      it "applies no shadow" do
        card = doc.find("div[data-test='card']")
        expect(card[:class]).to include("shadow-none")
      end
    end

    context "small shadow" do
      let(:options) { { shadow: :sm } }

      it "applies small shadow" do
        card = doc.find("div[data-test='card']")
        expect(card[:class]).to include("shadow-sm")
      end
    end

    context "large shadow" do
      let(:options) { { shadow: :lg } }

      it "applies large shadow" do
        card = doc.find("div[data-test='card']")
        expect(card[:class]).to include("shadow-lg")
      end
    end

    context "extra large shadow" do
      let(:options) { { shadow: :xl } }

      it "applies extra large shadow" do
        card = doc.find("div[data-test='card']")
        expect(card[:class]).to include("shadow-xl")
      end
    end

    context "default shadow" do
      let(:options) { { shadow: :default } }

      it "applies default shadow" do
        card = doc.find("div[data-test='card']")
        expect(card[:class]).to include("shadow")
      end
    end

    context "ghost variant ignores shadow" do
      let(:options) { { variant: :ghost, shadow: :xl } }

      it "does not apply shadow for ghost variant" do
        card = doc.find("div[data-test='card']")
        expect(card[:class]).to include("shadow-none")
        expect(card[:class]).not_to include("shadow-xl")
      end
    end
  end

  describe "interactive features" do
    context "with hover" do
      let(:options) { { hover: true } }

      it "applies hover classes" do
        card = doc.find("div[data-test='card']")
        expect(card[:class]).to include("transition-shadow", "duration-200", "hover:shadow-lg")
      end
    end

    context "with clickable" do
      let(:options) { { clickable: true } }

      it "applies clickable classes" do
        card = doc.find("div[data-test='card']")
        expect(card[:class]).to include("cursor-pointer", "hover:shadow-lg", "transition-all", "duration-200")
      end

      it "adds role and tabindex for accessibility" do
        card = doc.find("div[data-test='card']")
        expect(card[:role]).to eq("button")
        expect(card[:tabindex]).to eq("0")
      end
    end

    context "with href" do
      let(:options) { { href: "/path/to/page" } }

      it "renders as link" do
        expect(doc).to have_css("a[data-test='card'][href='/path/to/page']")
      end

      it "applies clickable styling" do
        card = doc.find("a[data-test='card']")
        expect(card[:class]).to include("cursor-pointer", "hover:shadow-lg")
      end

      it "does not add role and tabindex (native link behavior)" do
        card = doc.find("a[data-test='card']")
        expect(card[:role]).to be_nil
        expect(card[:tabindex]).to be_nil
      end
    end
  end

  describe "header section" do
    let(:component_with_header) do
      component.tap do |c|
        c.with_header { "Card Header" }
      end.with_content("Card content")
    end
    let(:doc) { render_component(component_with_header) }

    it "renders header section" do
      expect(doc).to have_css("div[data-test='card-header']", text: "Card Header")
    end

    it "applies header styling" do
      header = doc.find("div[data-test='card-header']")
      expect(header[:class]).to include("px-6", "py-4", "border-b", "border-gray-200")
    end

    it "adjusts body padding when header is present" do
      body = doc.find("div[data-test='card-body']")
      expect(body[:class]).to include("p-6")
    end

    context "with different padding sizes" do
      let(:options) { { padding: :sm } }

      it "adjusts header padding accordingly" do
        header = doc.find("div[data-test='card-header']")
        expect(header[:class]).to include("px-4", "py-3")
      end
    end
  end

  describe "footer section" do
    let(:component_with_footer) do
      component.tap do |c|
        c.with_footer { "Card Footer" }
      end.with_content("Card content")
    end
    let(:doc) { render_component(component_with_footer) }

    it "renders footer section" do
      expect(doc).to have_css("div[data-test='card-footer']", text: "Card Footer")
    end

    it "applies footer styling" do
      footer = doc.find("div[data-test='card-footer']")
      expect(footer[:class]).to include("px-6", "py-4", "border-t", "border-gray-200", "bg-gray-50")
    end

    it "adjusts body padding when footer is present" do
      body = doc.find("div[data-test='card-body']")
      expect(body[:class]).to include("p-6")
    end

    context "with different padding sizes" do
      let(:options) { { padding: :lg } }

      it "adjusts footer padding accordingly" do
        footer = doc.find("div[data-test='card-footer']")
        expect(footer[:class]).to include("px-8", "py-6")
      end
    end
  end

  describe "header and footer together" do
    let(:component_with_both) do
      component.tap do |c|
        c.with_header { "Card Header" }
        c.with_footer { "Card Footer" }
      end.with_content("Card content")
    end
    let(:doc) { render_component(component_with_both) }

    it "renders both header and footer" do
      expect(doc).to have_css("div[data-test='card-header']", text: "Card Header")
      expect(doc).to have_css("div[data-test='card-footer']", text: "Card Footer")
    end

    it "applies body padding when both are present" do
      body = doc.find("div[data-test='card-body']")
      expect(body[:class]).to include("p-6")
    end
  end

  describe "accessibility" do
    context "clickable card" do
      let(:options) { { clickable: true } }

      it "includes proper accessibility attributes" do
        card = doc.find("div[data-test='card']")
        expect(card[:role]).to eq("button")
        expect(card[:tabindex]).to eq("0")
      end
    end

    context "link card" do
      let(:options) { { href: "/example" } }

      it "uses semantic link element" do
        expect(doc).to have_css("a[data-test='card']")
      end
    end

    context "non-interactive card" do
      it "does not include interactive attributes" do
        card = doc.find("div[data-test='card']")
        expect(card[:role]).to be_nil
        expect(card[:tabindex]).to be_nil
      end
    end
  end

  describe "custom attributes" do
    it "passes through custom attributes" do
      custom_options = {
        id: "custom-card",
        class: "custom-class",
        data: { custom: "value" }
      }
      custom_component = described_class.new(**custom_options)
      custom_doc = render_component(custom_component.with_content("Card content"))

      card = custom_doc.find("div[data-test='card']")
      expect(card[:id]).to eq("custom-card")
      expect(card[:class]).to include("custom-class")
      expect(card[:class]).to include("bg-white") # Also includes default classes
      expect(card[:"data-custom"]).to eq("value")
    end
  end

  describe "content rendering" do
    it "renders simple text content" do
      expect(doc).to have_css("div[data-test='card-body']", text: "Card content")
    end

    context "with complex content" do
      let(:doc) do
        render_component(component.with_content("<p>HTML content</p><div>More content</div>".html_safe))
      end

      it "renders HTML content" do
        expect(doc).to have_css("div[data-test='card-body'] p", text: "HTML content")
        expect(doc).to have_css("div[data-test='card-body'] div", text: "More content")
      end
    end
  end

  describe "edge cases" do
    context "with no content" do
      let(:doc) { render_component(component.with_content("")) }

      it "renders empty card body" do
        expect(doc).to have_css("div[data-test='card-body']")
        body = doc.find("div[data-test='card-body']")
        expect(body.text.strip).to be_empty
      end
    end

    context "with empty header" do
      let(:component_with_empty_header) do
        component.tap do |c|
          c.with_header { "" }
        end.with_content("Card content")
      end
      let(:doc) { render_component(component_with_empty_header) }

      it "still renders header container" do
        expect(doc).to have_css("div[data-test='card-header']")
      end
    end

    context "with empty footer" do
      let(:component_with_empty_footer) do
        component.tap do |c|
          c.with_footer { "" }
        end.with_content("Card content")
      end
      let(:doc) { render_component(component_with_empty_footer) }

      it "still renders footer container" do
        expect(doc).to have_css("div[data-test='card-footer']")
      end
    end
  end

  describe "card without sections" do
    context "no header or footer" do
      it "does not apply body padding classes when no sections" do
        body = doc.find("div[data-test='card-body']")
        expect(body[:class]).to be_empty
      end
    end
  end
end
