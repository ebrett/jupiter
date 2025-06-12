# frozen_string_literal: true

require "rails_helper"

RSpec.describe Catalyst::NotificationComponent, type: :component do
  subject(:component) { described_class.new(**options) }

  let(:options) { {} }
  let(:doc) { render_component(component) }

  describe "basic rendering" do
    it "renders a notification div" do
      expect(doc).to have_css("div[role='alert']")
    end

    it "includes test selector" do
      expect(doc).to have_css("div[data-test='notification-info']")
    end

    it "applies default styling" do
      notification = doc.find("div[role='alert']")
      expect(notification[:class]).to include("rounded-md", "border", "p-4")
    end
  end

  describe "variants" do
    context "success variant" do
      let(:options) { { variant: :success, message: "Success message" } }

      it "applies success styling" do
        notification = doc.find("div[role='alert']")
        expect(notification[:class]).to include("bg-green-50", "border-green-200")
      end

      it "uses success icon" do
        expect(doc).to have_css("svg")
        icon = doc.find("svg")
        expect(icon[:class]).to include("text-green-400")
      end

      it "applies success text colors" do
        message = doc.find("p")
        expect(message[:class]).to include("text-sm")
      end

      it "includes correct test selector" do
        expect(doc).to have_css("div[data-test='notification-success']")
      end
    end

    context "error variant" do
      let(:options) { { variant: :error, message: "Error message" } }

      it "applies error styling" do
        notification = doc.find("div[role='alert']")
        expect(notification[:class]).to include("bg-red-50", "border-red-200")
      end

      it "uses error icon" do
        icon = doc.find("svg")
        expect(icon[:class]).to include("text-red-400")
      end
    end

    context "warning variant" do
      let(:options) { { variant: :warning, message: "Warning message" } }

      it "applies warning styling" do
        notification = doc.find("div[role='alert']")
        expect(notification[:class]).to include("bg-yellow-50", "border-yellow-200")
      end

      it "uses warning icon" do
        icon = doc.find("svg")
        expect(icon[:class]).to include("text-yellow-400")
      end
    end

    context "info variant" do
      let(:options) { { variant: :info, message: "Info message" } }

      it "applies info styling" do
        notification = doc.find("div[role='alert']")
        expect(notification[:class]).to include("bg-blue-50", "border-blue-200")
      end

      it "uses info icon" do
        icon = doc.find("svg")
        expect(icon[:class]).to include("text-blue-400")
      end
    end

    context "invalid variant" do
      let(:options) { { variant: :invalid } }

      it "raises an error" do
        expect { component }.to raise_error(ArgumentError, "Invalid variant: invalid")
      end
    end
  end

  describe "title and message" do
    context "with title only" do
      let(:options) { { title: "Important Notice" } }

      it "renders title" do
        expect(doc).to have_css("h3", text: "Important Notice")
      end

      it "applies title styling" do
        title = doc.find("h3")
        expect(title[:class]).to include("text-sm", "font-medium", "text-blue-800")
      end

      it "does not render message" do
        expect(doc).not_to have_css("p")
      end
    end

    context "with message only" do
      let(:options) { { message: "This is a notification message" } }

      it "renders message" do
        expect(doc).to have_css("p", text: "This is a notification message")
      end

      it "applies message styling" do
        message = doc.find("p")
        expect(message[:class]).to include("text-sm")
      end

      it "does not render title" do
        expect(doc).not_to have_css("h3")
      end
    end

    context "with both title and message" do
      let(:options) do
        {
          title: "Success!",
          message: "Your changes have been saved.",
          variant: :success
        }
      end

      it "renders both title and message" do
        expect(doc).to have_css("h3", text: "Success!")
        expect(doc).to have_css("p", text: "Your changes have been saved.")
      end

      it "adds margin to message when title present" do
        message_container = doc.find("div.text-green-700")
        expect(message_container[:class]).to include("mt-1")
      end
    end

    context "with HTML message content" do
      let(:message_html) { "<p>First paragraph</p><p>Second paragraph</p>".html_safe }

      let(:options) { { message: message_html } }

      it "renders HTML content" do
        expect(doc).to have_css("p", text: "First paragraph")
        expect(doc).to have_css("p", text: "Second paragraph")
      end
    end
  end

  describe "icon handling" do
    context "with default icon" do
      let(:options) { { message: "Test", variant: :success } }

      it "shows the default success icon" do
        expect(doc).to have_css("svg")
        svg = doc.find("svg")
        expect(svg[:class]).to include("h-5", "w-5", "text-green-400")
      end

      it "uses correct SVG path for success" do
        path = doc.find("svg path")
        expect(path[:d]).to include("M9 12.75L11.25 15 15 9.75")
      end
    end

    context "with custom icon path" do
      let(:custom_path) { "M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z" }
      let(:options) { { message: "Custom icon", icon: custom_path } }

      it "uses custom icon path" do
        path = doc.find("svg path")
        expect(path[:d]).to eq(custom_path)
      end
    end

    context "with icon disabled" do
      let(:options) { { message: "No icon", icon: false } }

      it "does not show icon" do
        expect(doc).not_to have_css("svg")
      end

      it "does not add margin to text content" do
        text_content = doc.find("div.flex-1")
        expect(text_content[:class]).not_to include("ml-3")
      end
    end
  end

  describe "dismissible notifications" do
    context "when dismissible" do
      let(:options) { { message: "Dismissible notification", dismissible: true } }

      it "includes dismiss button" do
        expect(doc).to have_css("button")
      end

      it "adds notification controller" do
        notification = doc.find("div[role='alert']")
        expect(notification[:"data-controller"]).to eq("notification")
      end

      it "includes dismiss action" do
        button = doc.find("button")
        expect(button[:"data-action"]).to eq("click->notification#dismiss")
      end

      it "applies dismiss button styling" do
        button = doc.find("button")
        expect(button[:class]).to include("inline-flex", "rounded-md", "p-1.5")
      end

      it "includes accessibility text" do
        expect(doc).to have_css("span.sr-only", text: "Dismiss")
      end

      it "includes close icon" do
        expect(doc).to have_css("button svg")
      end
    end

    context "when not dismissible" do
      let(:options) { { message: "Non-dismissible notification", dismissible: false } }

      it "does not include dismiss button" do
        expect(doc).not_to have_css("button")
      end

      it "does not add notification controller" do
        notification = doc.find("div[role='alert']")
        expect(notification[:"data-controller"]).to be_nil
      end
    end
  end

  describe "actions" do
    let(:action_buttons) do
      safe_join([
        content_tag(:button, "Retry", class: "btn btn-sm"),
        content_tag(:button, "Cancel", class: "btn btn-sm btn-secondary")
      ])
    end

    let(:options) do
      {
        title: "Action Required",
        message: "Please choose an action",
        actions: action_buttons
      }
    end

    it "renders action buttons" do
      expect(doc).to have_css("button", text: "Retry")
      expect(doc).to have_css("button", text: "Cancel")
    end

    it "applies actions container styling" do
      actions_container = doc.find("div.ml-auto.pl-3")
      expect(actions_container).to have_css("button", text: "Retry")
    end
  end

  describe "accessibility" do
    let(:options) { { title: "Alert", message: "Important message" } }

    it "has proper ARIA role" do
      notification = doc.find("div[role='alert']")
      expect(notification).to be_present
    end

    it "uses semantic heading for title" do
      expect(doc).to have_css("h3", text: "Alert")
    end

    context "with dismiss button" do
      let(:options) { { message: "Dismissible", dismissible: true } }

      it "includes screen reader text" do
        expect(doc).to have_css("span.sr-only", text: "Dismiss")
      end

      it "marks dismiss icon as decorative" do
        dismiss_svg = doc.find("button svg")
        expect(dismiss_svg[:"aria-hidden"]).to eq("true")
      end
    end
  end

  describe "custom attributes" do
    let(:options) do
      {
        message: "Custom notification",
        id: "custom-notification",
        class: "custom-class",
        data: { timeout: "3000" }
      }
    end

    it "passes through custom attributes" do
      notification = doc.find("div[role='alert']")
      expect(notification[:id]).to eq("custom-notification")
      expect(notification[:"data-timeout"]).to eq("3000")
    end

    it "merges custom classes" do
      notification = doc.find("div[role='alert']")
      expect(notification[:class]).to include("custom-class")
    end
  end

  describe "layout and positioning" do
    let(:options) { { title: "Test", message: "Layout test", dismissible: true } }

    it "uses flex layout for main content" do
      main_content = doc.find("div.flex")
      expect(main_content).to be_present
    end

    it "positions icon as flex-shrink-0" do
      icon_container = doc.find("div.flex-shrink-0")
      expect(icon_container).to be_present
      expect(icon_container).to have_css("svg")
    end

    it "makes text content flexible" do
      text_content = doc.find("div.flex-1")
      expect(text_content).to be_present
    end

    it "positions dismiss button on the right" do
      dismiss_container = doc.find("div.ml-auto")
      expect(dismiss_container).to be_present
      expect(dismiss_container).to have_css("button")
    end
  end

  describe "variant color consistency" do
    Catalyst::NotificationComponent::VARIANTS.each do |variant_name, _|
      context "#{variant_name} variant colors" do
        let(:options) { { variant: variant_name, message: "Test", dismissible: true } }

        it "uses consistent colors across all elements" do
          notification = doc.find("div[role='alert']")
          color_prefix = {
            success: "green",
            error: "red",
            warning: "yellow",
            info: "blue"
          }[variant_name]

          expect(notification[:class]).to include("bg-#{color_prefix}-50")

          if doc.has_css?("div.flex-shrink-0 svg")
            icon = doc.find("div.flex-shrink-0 svg")
            expect(icon[:class]).to include("text-#{color_prefix}-400")
          end

          if doc.has_css?("button")
            button = doc.find("button")
            expect(button[:class]).to include("text-#{color_prefix}-500")
          end
        end
      end
    end
  end
end
