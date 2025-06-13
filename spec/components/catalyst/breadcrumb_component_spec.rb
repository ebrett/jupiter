# frozen_string_literal: true

require "rails_helper"

RSpec.describe Catalyst::BreadcrumbComponent, type: :component do
  subject(:component) { described_class.new(**options) }

  let(:options) { {} }

  describe "basic rendering" do
    let(:component_with_items) do
      component.tap do |c|
        c.with_item(label: "Home", href: "/")
        c.with_item(label: "Users", href: "/users")
        c.with_item(label: "John Doe", current: true)
      end
    end
    let(:doc) { render_component(component_with_items) }

    it "renders breadcrumb navigation" do
      expect(doc).to have_css("nav[data-test='breadcrumb']")
    end

    it "includes proper ARIA attributes" do
      nav = doc.find("nav[data-test='breadcrumb']")
      expect(nav[:"aria-label"]).to eq("Breadcrumb")
    end

    it "renders breadcrumb items" do
      expect(doc).to have_css("li[data-test='breadcrumb-item']", count: 3)
    end

    it "renders breadcrumb links" do
      expect(doc).to have_css("a[data-test='breadcrumb-link']", count: 2)
      expect(doc).to have_link("Home", href: "/")
      expect(doc).to have_link("Users", href: "/users")
    end

    it "renders current item without link" do
      expect(doc).to have_css("span[data-test='breadcrumb-current']", text: "John Doe")
      current = doc.find("span[data-test='breadcrumb-current']")
      expect(current[:"aria-current"]).to eq("page")
    end

    it "renders separators between items" do
      expect(doc).to have_css("span[data-test='breadcrumb-separator']", count: 2)
    end
  end

  describe "separator options" do
    let(:component_with_items) do
      component.tap do |c|
        c.with_item(label: "Home", href: "/")
        c.with_item(label: "Current", current: true)
      end
    end

    context "with default chevron separator" do
      let(:options) { { separator: :chevron } }
      let(:doc) { render_component(component_with_items) }

      it "renders chevron SVG separator" do
        expect(doc).to have_css("span[data-test='breadcrumb-separator'] svg")
      end
    end

    context "with slash separator" do
      let(:options) { { separator: :slash } }
      let(:doc) { render_component(component_with_items) }

      it "renders slash separator" do
        separator = doc.find("span[data-test='breadcrumb-separator']")
        expect(separator.text).to eq("/")
      end
    end

    context "with arrow separator" do
      let(:options) { { separator: :arrow } }
      let(:doc) { render_component(component_with_items) }

      it "renders arrow SVG separator" do
        expect(doc).to have_css("span[data-test='breadcrumb-separator'] svg")
      end
    end

    context "with dot separator" do
      let(:options) { { separator: :dot } }
      let(:doc) { render_component(component_with_items) }

      it "renders dot separator" do
        separator = doc.find("span[data-test='breadcrumb-separator']")
        expect(separator.text).to eq("•")
      end
    end

    context "with pipe separator" do
      let(:options) { { separator: :pipe } }
      let(:doc) { render_component(component_with_items) }

      it "renders pipe separator" do
        separator = doc.find("span[data-test='breadcrumb-separator']")
        expect(separator.text).to eq("|")
      end
    end

    context "with custom separator" do
      let(:options) { { separator: ">" } }
      let(:doc) { render_component(component_with_items) }

      it "renders custom separator" do
        separator = doc.find("span[data-test='breadcrumb-separator']")
        expect(separator.text).to eq(">")
      end
    end
  end

  describe "size options" do
    let(:component_with_items) do
      component.tap do |c|
        c.with_item(label: "Home", href: "/")
      end
    end

    context "with small size" do
      let(:options) { { size: :sm } }
      let(:doc) { render_component(component_with_items) }

      it "applies small text size" do
        nav = doc.find("nav[data-test='breadcrumb']")
        expect(nav[:class]).to include("text-sm")
      end
    end

    context "with default size" do
      let(:options) { { size: :default } }
      let(:doc) { render_component(component_with_items) }

      it "applies default text size" do
        nav = doc.find("nav[data-test='breadcrumb']")
        expect(nav[:class]).to include("text-base")
      end
    end

    context "with large size" do
      let(:options) { { size: :lg } }
      let(:doc) { render_component(component_with_items) }

      it "applies large text size" do
        nav = doc.find("nav[data-test='breadcrumb']")
        expect(nav[:class]).to include("text-lg")
      end
    end
  end

  describe "breadcrumb items with icons" do
    let(:component_with_icons) do
      component.tap do |c|
        c.with_item(label: "Home", href: "/", icon: :home)
        c.with_item(label: "Documents", href: "/documents", icon: :folder)
        c.with_item(label: "Report.pdf", current: true, icon: :document)
      end
    end
    let(:doc) { render_component(component_with_icons) }

    it "renders icons in breadcrumb items" do
      expect(doc).to have_css("svg", count: 5) # 3 icons + 2 separators
    end

    it "renders home icon" do
      home_link = doc.find("a", text: "Home")
      expect(home_link).to have_css("svg")
    end

    it "renders folder icon" do
      documents_link = doc.find("a", text: "Documents")
      expect(documents_link).to have_css("svg")
    end

    it "renders document icon" do
      current_item = doc.find("span[data-test='breadcrumb-current']")
      expect(current_item).to have_css("svg")
    end
  end

  describe "breadcrumb items without links" do
    let(:component_with_text) do
      component.tap do |c|
        c.with_item(label: "Home", href: "/")
        c.with_item(label: "Text Only")
        c.with_item(label: "Current", current: true)
      end
    end
    let(:doc) { render_component(component_with_text) }

    it "renders text-only items as spans" do
      expect(doc).to have_css("span[data-test='breadcrumb-text']", text: "Text Only")
    end

    it "does not render text-only items as links" do
      expect(doc).not_to have_link("Text Only")
    end
  end

  describe "single item breadcrumb" do
    let(:component_with_single) do
      component.tap do |c|
        c.with_item(label: "Current Page", current: true)
      end
    end
    let(:doc) { render_component(component_with_single) }

    it "renders single item without separator" do
      expect(doc).to have_css("li[data-test='breadcrumb-item']", count: 1)
      expect(doc).not_to have_css("span[data-test='breadcrumb-separator']")
    end

    it "marks single item as current" do
      expect(doc).to have_css("span[data-test='breadcrumb-current']", text: "Current Page")
    end
  end

  describe "empty breadcrumb" do
    let(:doc) { render_component(component) }

    it "renders empty breadcrumb navigation" do
      expect(doc).to have_css("nav[data-test='breadcrumb']")
      expect(doc).not_to have_css("li[data-test='breadcrumb-item']")
    end
  end

  describe "accessibility" do
    let(:component_with_items) do
      component.tap do |c|
        c.with_item(label: "Home", href: "/")
        c.with_item(label: "Current", current: true)
      end
    end
    let(:doc) { render_component(component_with_items) }

    it "uses semantic nav element" do
      expect(doc).to have_css("nav[aria-label='Breadcrumb']")
    end

    it "uses ordered list structure" do
      expect(doc).to have_css("nav ol")
    end

    it "marks current page with aria-current" do
      current = doc.find("span[data-test='breadcrumb-current']")
      expect(current[:"aria-current"]).to eq("page")
    end

    it "hides separators from screen readers" do
      separator = doc.find("span[data-test='breadcrumb-separator']")
      expect(separator[:"aria-hidden"]).to eq("true")
    end
  end

  describe "custom attributes" do
    let(:options) do
      {
        class: "custom-breadcrumb",
        id: "my-breadcrumb",
        data: { custom: "value" }
      }
    end
    let(:component_with_items) do
      component.tap do |c|
        c.with_item(label: "Home", href: "/")
      end
    end
    let(:doc) { render_component(component_with_items) }

    it "passes through custom attributes" do
      nav = doc.find("nav[data-test='breadcrumb']")
      expect(nav[:class]).to include("custom-breadcrumb")
      expect(nav[:id]).to eq("my-breadcrumb")
      expect(nav[:"data-custom"]).to eq("value")
    end
  end

  describe "breadcrumb item styling" do
    let(:component_with_items) do
      component.tap do |c|
        c.with_item(label: "Home", href: "/")
        c.with_item(label: "Users", href: "/users")
        c.with_item(label: "Current", current: true)
      end
    end
    let(:doc) { render_component(component_with_items) }

    it "applies link styling to non-current items" do
      link = doc.find("a[data-test='breadcrumb-link']", text: "Home")
      expect(link[:class]).to include("text-gray-700", "hover:text-gray-900")
    end

    it "applies current styling to current item" do
      current = doc.find("span[data-test='breadcrumb-current']")
      expect(current[:class]).to include("text-gray-500", "font-medium", "cursor-default")
    end
  end

  describe "complex breadcrumb" do
    let(:complex_component) do
      component.tap do |c|
        c.with_item(label: "Dashboard", href: "/", icon: :home)
        c.with_item(label: "Users", href: "/users")
        c.with_item(label: "Administrators", href: "/users?role=admin")
        c.with_item(label: "Profile Settings", href: "/users/123/settings")
        c.with_item(label: "Security", current: true, icon: :document)
      end
    end
    let(:doc) { render_component(complex_component) }

    it "renders all items correctly" do
      expect(doc).to have_css("li[data-test='breadcrumb-item']", count: 5)
      expect(doc).to have_css("a[data-test='breadcrumb-link']", count: 4)
      expect(doc).to have_css("span[data-test='breadcrumb-current']", count: 1)
      expect(doc).to have_css("span[data-test='breadcrumb-separator']", count: 4)
    end

    it "preserves order of items" do
      links = doc.all("a[data-test='breadcrumb-link']")
      expect(links[0].text.strip).to eq("Dashboard")
      expect(links[1].text.strip).to eq("Users")
      expect(links[2].text.strip).to eq("Administrators")
      expect(links[3].text.strip).to eq("Profile Settings")

      current = doc.find("span[data-test='breadcrumb-current']")
      expect(current.text.strip).to eq("Security")
    end
  end
end
