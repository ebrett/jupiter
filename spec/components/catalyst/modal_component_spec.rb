# frozen_string_literal: true

require "rails_helper"

RSpec.describe Catalyst::ModalComponent, type: :component do
  subject(:component) { described_class.new(**options) }

  let(:options) { {} }
  let(:doc) { render_component(component) }

  # Helper method to find elements that might be hidden
  def find_modal_element(selector, **options)
    doc.find(selector, **options.merge(visible: :all))
  end

  describe "basic rendering" do
    it "renders a modal backdrop" do
      expect(doc).to have_css("div[data-controller='catalyst-modal']", visible: false)
    end

    it "includes test selector" do
      expect(doc).to have_css("div[data-test='modal']", visible: false)
    end

    it "applies backdrop styling" do
      backdrop = find_modal_element("div[data-controller='catalyst-modal']")
      expect(backdrop[:class]).to include("fixed", "inset-0", "bg-zinc-950/25")
    end

    it "is hidden by default" do
      backdrop = find_modal_element("div[data-controller='catalyst-modal']")
      expect(backdrop[:style]).to include("display: none")
    end

    it "has proper controller attributes" do
      backdrop = find_modal_element("div[data-controller='catalyst-modal']")
      expect(backdrop[:"data-catalyst-modal-open-value"]).to eq("false")
      expect(backdrop[:"data-action"]).to include("click->catalyst-modal#clickBackdrop")
      expect(backdrop[:"data-action"]).to include("keydown.escape->catalyst-modal#close")
    end
  end

  describe "sizes" do
    Catalyst::ModalComponent::SIZES.each do |size_name, size_class|
      context "#{size_name} size" do
        let(:options) { { size: size_name } }

        it "applies correct size class" do
          panel = find_modal_element("div[data-catalyst-modal-target='panel']")
          expect(panel[:class]).to include(size_class)
        end
      end
    end

    context "invalid size" do
      let(:options) { { size: :invalid } }

      it "raises an error" do
        expect { component }.to raise_error(ArgumentError, "Invalid size: invalid")
      end
    end
  end

  describe "open state" do
    context "when open" do
      let(:options) { { open: true } }

      it "is visible" do
        backdrop = find_modal_element("div[data-controller='catalyst-modal']")
        expect(backdrop[:style]).to be_nil
      end

      it "sets open value to true" do
        backdrop = find_modal_element("div[data-controller='catalyst-modal']")
        expect(backdrop[:"data-catalyst-modal-open-value"]).to eq("true")
      end
    end

    context "when closed" do
      let(:options) { { open: false } }

      it "is hidden" do
        backdrop = find_modal_element("div[data-controller='catalyst-modal']")
        expect(backdrop[:style]).to include("display: none")
      end

      it "sets open value to false" do
        backdrop = find_modal_element("div[data-controller='catalyst-modal']")
        expect(backdrop[:"data-catalyst-modal-open-value"]).to eq("false")
      end
    end
  end

  describe "title and description" do
    context "with title only" do
      let(:options) { { title: "Modal Title" } }

      it "renders title" do
        expect(doc).to have_css("h2[data-catalyst-modal-target='title']", text: "Modal Title", visible: false)
      end

      it "applies title styling" do
        title = find_modal_element("h2[data-catalyst-modal-target='title']")
        expect(title[:class]).to include("text-lg/6", "font-semibold", "text-zinc-950")
      end

      it "includes header section" do
        expect(doc).to have_css("div", class: /p-8/, visible: false)
      end

      it "does not render description" do
        expect(doc).not_to have_css("p[data-catalyst-modal-target='description']")
      end
    end

    context "with description only" do
      let(:options) { { description: "Modal description text" } }

      it "renders description" do
        expect(doc).to have_css("p[data-catalyst-modal-target='description']", text: "Modal description text", visible: false)
      end

      it "applies description styling" do
        description = find_modal_element("p[data-catalyst-modal-target='description']")
        expect(description[:class]).to include("mt-2", "text-pretty", "text-zinc-600")
      end

      it "does not render title" do
        expect(doc).not_to have_css("h2[data-catalyst-modal-target='title']")
      end
    end

    context "with both title and description" do
      let(:options) do
        {
          title: "Confirm Action",
          description: "Are you sure you want to continue? This action cannot be undone."
        }
      end

      it "renders both title and description" do
        expect(doc).to have_css("h2", text: "Confirm Action", visible: false)
        expect(doc).to have_css("p", text: "Are you sure you want to continue? This action cannot be undone.", visible: false)
      end

      it "description follows title" do
        title = find_modal_element("h2")
        description = find_modal_element("p")
        expect(description[:class]).to include("mt-2")
      end
    end

    context "without title or description" do
      let(:options) { {} }

      it "does not render header section" do
        expect(doc).not_to have_css("h2")
        expect(doc).not_to have_css("p[data-catalyst-modal-target='description']")
      end
    end
  end

  describe "body content" do
    let(:content) { "This is modal body content" }
    let(:options) { {} }

    before do
      allow(component).to receive_messages(content: content, content?: true)
    end

    it "renders content in body" do
      expect(find_modal_element("div[data-catalyst-modal-target='panel']")).to have_text("This is modal body content")
    end

    context "with title" do
      let(:options) { { title: "Title" } }

      it "applies correct body padding" do
        # Body should have different padding when title is present
        body_div = find_modal_element("div.px-8")
        expect(body_div[:class]).to include("px-8")
      end
    end

    context "without title" do
      it "applies default body padding" do
        body_div = find_modal_element("div.p-8")
        expect(body_div[:class]).to include("p-8")
      end
    end
  end

  describe "actions" do
    let(:action_buttons) do
      safe_join([
        content_tag(:button, "Confirm", class: "btn btn-primary"),
        content_tag(:button, "Cancel", class: "btn btn-secondary")
      ])
    end

    let(:options) do
      {
        title: "Confirm Action",
        actions: action_buttons
      }
    end

    it "renders action buttons" do
      expect(doc).to have_css("button", visible: false, text: "Confirm")
      expect(doc).to have_css("button", visible: false, text: "Cancel")
    end

    it "applies actions container styling" do
      actions_container = find_modal_element("div.flex.flex-col-reverse")
      expect(actions_container[:class]).to include(
        "flex", "flex-col-reverse", "items-center", "justify-end", "gap-3"
      )
    end

    it "adjusts body padding when actions present" do
      # When actions are present, body should have pb-0
      body_content = find_modal_element("div.pb-0")
      expect(body_content[:class]).to include("pb-0")
    end

    context "without title" do
      let(:options) { { actions: action_buttons } }

      before do
        allow(component).to receive(:content).and_return("Body content")
      end

      it "still renders actions" do
        expect(doc).to have_css("button", visible: false, text: "Confirm")
        expect(doc).to have_css("button", visible: false, text: "Cancel")
      end
    end
  end

  describe "panel structure" do
    let(:options) { { title: "Test Modal" } }

    it "includes panel target" do
      expect(doc).to have_css("div[data-catalyst-modal-target='panel']", visible: false)
    end

    it "applies panel styling" do
      panel = find_modal_element("div[data-catalyst-modal-target='panel']")
      expect(panel[:class]).to include(
        "row-start-2", "w-full", "min-w-0", "rounded-t-3xl", "bg-white", "shadow-lg"
      )
    end

    it "includes click handler" do
      panel = find_modal_element("div[data-catalyst-modal-target='panel']")
      expect(panel[:"data-action"]).to eq("click->catalyst-modal#clickPanel")
    end

    it "applies transition classes" do
      panel = find_modal_element("div[data-catalyst-modal-target='panel']")
      expect(panel[:class]).to include(
        "transition", "duration-100", "will-change-transform"
      )
    end
  end

  describe "grid layout" do
    it "uses proper grid structure" do
      expect(doc).to have_css("div", class: /grid.*min-h-full.*grid-rows/, visible: false)
    end

    it "centers content" do
      grid = find_modal_element("div", class: /grid/)
      expect(grid[:class]).to include("justify-items-center")
    end

    it "handles responsive grid rows" do
      grid = find_modal_element("div", class: /grid/)
      expect(grid[:class]).to include("sm:grid-rows-[1fr_auto_3fr]")
    end
  end

  describe "accessibility" do
    let(:options) do
      {
        title: "Accessible Modal",
        description: "This modal follows accessibility guidelines"
      }
    end

    it "uses semantic heading for title" do
      expect(doc).to have_css("h2", text: "Accessible Modal", visible: false)
    end

    it "provides proper focus management structure" do
      # Panel should be focusable
      panel = find_modal_element("div[data-catalyst-modal-target='panel']")
      expect(panel).to be_present
    end

    it "supports keyboard navigation" do
      backdrop = find_modal_element("div[data-controller='catalyst-modal']")
      expect(backdrop[:"data-action"]).to include("keydown.escape->catalyst-modal#close")
    end
  end

  describe "dark mode support" do
    let(:options) { { title: "Dark Mode Test" } }

    it "includes dark mode classes" do
      panel = find_modal_element("div[data-catalyst-modal-target='panel']")
      expect(panel[:class]).to include("dark:bg-zinc-900", "dark:ring-white/10")
    end

    it "applies dark mode to title" do
      title = find_modal_element("h2")
      expect(title[:class]).to include("dark:text-white")
    end
  end

  describe "responsive design" do
    let(:options) { { size: :lg } }

    it "applies responsive sizing" do
      panel = find_modal_element("div[data-catalyst-modal-target='panel']")
      expect(panel[:class]).to include("sm:max-w-lg")
    end

    it "uses responsive border radius" do
      panel = find_modal_element("div[data-catalyst-modal-target='panel']")
      expect(panel[:class]).to include("rounded-t-3xl", "sm:rounded-2xl")
    end

    it "applies responsive backdrop padding" do
      backdrop = find_modal_element("div[data-controller='catalyst-modal']")
      expect(backdrop[:class]).to include("px-2", "py-2", "sm:px-6", "sm:py-8")
    end
  end

  describe "custom attributes" do
    let(:options) do
      {
        title: "Custom Modal",
        id: "custom-modal",
        class: "custom-class",
        data: { custom: "value" }
      }
    end

    it "passes through custom attributes" do
      backdrop = find_modal_element("div[data-controller='catalyst-modal']")
      expect(backdrop[:id]).to eq("custom-modal")
      expect(backdrop[:"data-custom"]).to eq("value")
    end

    it "merges custom classes" do
      backdrop = find_modal_element("div[data-controller='catalyst-modal']")
      expect(backdrop[:class]).to include("custom-class")
    end
  end

  describe "forced colors mode" do
    let(:options) { { title: "Forced Colors Test" } }

    it "includes forced colors outline" do
      panel = find_modal_element("div[data-catalyst-modal-target='panel']")
      expect(panel[:class]).to include("forced-colors:outline")
    end
  end

  describe "transition animations" do
    let(:options) { { title: "Animated Modal" } }

    it "includes backdrop transition classes" do
      backdrop = find_modal_element("div[data-controller='catalyst-modal']")
      expect(backdrop[:class]).to include(
        "transition", "duration-100", "data-closed:opacity-0", "data-enter:ease-out"
      )
    end

    it "includes panel transition classes" do
      panel = find_modal_element("div[data-catalyst-modal-target='panel']")
      expect(panel[:class]).to include(
        "data-closed:translate-y-12", "data-closed:opacity-0", "data-enter:ease-out"
      )
    end

    it "includes responsive panel animations" do
      panel = find_modal_element("div[data-catalyst-modal-target='panel']")
      expect(panel[:class]).to include(
        "sm:data-closed:translate-y-0", "sm:data-closed:data-enter:scale-95"
      )
    end
  end
end
