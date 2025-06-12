# frozen_string_literal: true

require "rails_helper"

RSpec.describe Catalyst::InputComponent, type: :component do
  subject(:component) { described_class.new(**options) }

  let(:options) { {} }
  let(:doc) { render_component(component) }

  describe "basic rendering" do
    it "renders an input element" do
      expect(doc).to have_css("input[type='text']")
    end

    it "wraps input in proper structure" do
      expect(doc).to have_css("div > span[data-slot='control'] > input")
    end

    it "includes test selector" do
      expect(doc).to have_css("input[data-test='input-text']")
    end

    it "has default text type" do
      expect(doc).to have_css("input[type='text']")
    end

    it "applies base input classes" do
      input = doc.find("input")
      expect(input[:class]).to include(
        "relative",
        "block",
        "w-full",
        "appearance-none",
        "rounded-lg"
      )
    end
  end

  describe "input types" do
    context "with email type" do
      let(:options) { { type: "email" } }

      it "renders email input" do
        expect(doc).to have_css("input[type='email']")
      end

      it "includes correct test selector" do
        expect(doc).to have_css("input[data-test='input-email']")
      end
    end

    context "with password type" do
      let(:options) { { type: "password" } }

      it "renders password input" do
        expect(doc).to have_css("input[type='password']")
      end
    end

    context "with search type" do
      let(:options) { { type: "search" } }

      it "renders search input" do
        expect(doc).to have_css("input[type='search']")
      end
    end

    context "with invalid type" do
      it "raises an error" do
        expect { described_class.new(type: "invalid") }
          .to raise_error(ArgumentError, /Invalid type/)
      end
    end
  end

  describe "attributes" do
    let(:options) do
      {
        name: "user_email",
        value: "test@example.com",
        placeholder: "Enter email",
        required: true,
        disabled: false,
        readonly: false,
        autofocus: true,
        autocomplete: "email",
        maxlength: 255,
        minlength: 3,
        pattern: ".*@.*"
      }
    end

    it "applies all input attributes" do
      input = doc.find("input")
      expect(input[:name]).to eq("user_email")
      expect(input[:value]).to eq("test@example.com")
      expect(input[:placeholder]).to eq("Enter email")
      expect(input[:required]).to eq("required")
      expect(input[:autofocus]).to eq("autofocus")
      expect(input[:autocomplete]).to eq("email")
      expect(input[:maxlength]).to eq("255")
      expect(input[:minlength]).to eq("3")
      expect(input[:pattern]).to eq(".*@.*")
    end

    it "does not have disabled when false" do
      input = doc.find("input")
      expect(input[:disabled]).to be_nil
    end

    context "when disabled" do
      let(:options) { { disabled: true } }

      it "adds disabled attribute" do
        input = doc.find("input")
        expect(input[:disabled]).to eq("disabled")
      end

      it "applies disabled classes" do
        input = doc.find("input")
        expect(input[:class]).to include("disabled:border-zinc-200", "disabled:bg-zinc-50")
      end
    end

    context "when readonly" do
      let(:options) { { readonly: true } }

      it "adds readonly attribute" do
        input = doc.find("input")
        expect(input[:readonly]).to eq("readonly")
      end
    end
  end

  describe "label" do
    context "with label" do
      let(:options) { { label: "Email Address", name: "email" } }

      it "renders label element" do
        expect(doc).to have_css("label", text: "Email Address")
      end

      it "associates label with input" do
        label = doc.find("label")
        input = doc.find("input")
        expect(label[:for]).to eq(input[:id])
      end

      it "applies label classes" do
        label = doc.find("label")
        expect(label[:class]).to include("block", "text-sm", "font-medium", "text-zinc-700")
      end
    end

    context "with required and label" do
      let(:options) { { label: "Email Address", required: true } }

      it "adds required indicator to label" do
        label = doc.find("label")
        expect(label[:class]).to include("required:after:content-['*']")
      end
    end

    context "without label" do
      it "does not render label element" do
        expect(doc).not_to have_css("label")
      end
    end
  end

  describe "description" do
    context "with description" do
      let(:options) { { description: "Enter your primary email address", name: "email" } }

      it "renders description element" do
        expect(doc).to have_css("p", text: "Enter your primary email address")
      end

      it "applies description classes" do
        description = doc.find("p")
        expect(description[:class]).to include("mt-1", "text-sm", "text-zinc-600")
      end

      it "associates description with input" do
        input = doc.find("input")
        description = doc.find("p")
        expect(input["aria-describedby"]).to include(description[:id])
      end
    end

    context "without description" do
      it "does not render description element" do
        expect(doc).not_to have_css("p")
      end
    end
  end

  describe "error states" do
    context "with error message" do
      let(:options) { { error_message: "Email is required", name: "email" } }

      it "renders error message" do
        expect(doc).to have_css("p[role='alert']", text: "Email is required")
      end

      it "applies error classes to message" do
        error = doc.find("p[role='alert']")
        expect(error[:class]).to include("mt-1", "text-sm", "text-red-600")
      end

      it "applies error styles to input" do
        input = doc.find("input")
        expect(input[:class]).to include("border-red-500")
        expect(input["aria-invalid"]).to eq("true")
      end

      it "associates error with input" do
        input = doc.find("input")
        error = doc.find("p[role='alert']")
        expect(input["aria-describedby"]).to include(error[:id])
      end
    end

    context "with Rails form errors" do
      let(:options) do
        {
          name: "email",
          form_errors: { "email" => [ "can't be blank", "is not valid" ] }
        }
      end

      it "renders first error message" do
        expect(doc).to have_css("p[role='alert']", text: "can't be blank")
      end

      it "applies error styles to input" do
        input = doc.find("input")
        expect(input[:class]).to include("border-red-500")
        expect(input["aria-invalid"]).to eq("true")
      end
    end

    context "without errors" do
      it "does not render error message" do
        expect(doc).not_to have_css("p[role='alert']")
      end

      it "does not apply error styles" do
        input = doc.find("input")
        expect(input[:class]).not_to include("border-red-500")
        expect(input["aria-invalid"]).to be_nil
      end
    end
  end

  describe "icons" do
    context "with leading email icon" do
      let(:options) { { leading_icon: :email } }

      it "renders email icon" do
        expect(doc).to have_css("span > svg[data-slot='icon']")
      end

      it "positions icon on the left" do
        icon = doc.find("svg")
        expect(icon[:class]).to include("left-3")
      end

      it "applies padding to input for icon" do
        input = doc.find("input")
        expect(input[:class]).to include("pl-10")
      end
    end

    context "with trailing lock icon" do
      let(:options) { { trailing_icon: :lock } }

      it "renders lock icon" do
        expect(doc).to have_css("span > svg[data-slot='icon']")
      end

      it "positions icon on the right" do
        icon = doc.find("svg")
        expect(icon[:class]).to include("right-3")
      end

      it "applies padding to input for icon" do
        input = doc.find("input")
        expect(input[:class]).to include("pr-10")
      end
    end

    context "with both leading and trailing icons" do
      let(:options) { { leading_icon: :user, trailing_icon: :eye } }

      it "renders both icons" do
        expect(doc).to have_css("svg", count: 2)
      end

      it "applies padding for both icons" do
        input = doc.find("input")
        expect(input[:class]).to include("pl-10", "pr-10")
      end
    end

    context "with search icon" do
      let(:options) { { leading_icon: :search } }

      it "renders search icon" do
        expect(doc).to have_css("svg[data-slot='icon']")
      end
    end

    context "with user icon" do
      let(:options) { { leading_icon: :user } }

      it "renders user icon" do
        expect(doc).to have_css("svg[data-slot='icon']")
      end
    end

    context "with eye icons" do
      let(:options) { { trailing_icon: :eye } }

      it "renders eye icon" do
        expect(doc).to have_css("svg[data-slot='icon']")
      end
    end

    context "with custom string icon" do
      let(:options) { { leading_icon: "🔍" } }

      it "renders custom icon" do
        expect(doc).to have_text("🔍")
      end
    end
  end

  describe "accessibility" do
    let(:options) do
      {
        label: "Email Address",
        description: "Enter your email",
        error_message: "Email is required",
        required: true,
        name: "email"
      }
    end

    it "has proper ARIA attributes" do
      input = doc.find("input")
      expect(input["aria-required"]).to eq("true")
      expect(input["aria-invalid"]).to eq("true")
      expect(input["aria-describedby"]).to be_present
    end

    it "associates all descriptive elements" do
      input = doc.find("input")
      describedby = input["aria-describedby"]

      expect(describedby).to include("description")
      expect(describedby).to include("error")
    end

    it "marks icons as decorative" do
      component = described_class.new(leading_icon: :email)
      doc = render_component(component)

      icon = doc.find("svg")
      expect(icon["aria-hidden"]).to eq("true")
    end
  end

  describe "focus and hover states" do
    it "includes focus styles" do
      wrapper = doc.find("span[data-slot='control']")
      expect(wrapper[:class]).to include("focus-within:after:ring-2", "focus-within:after:ring-blue-500")
    end

    it "includes hover styles" do
      input = doc.find("input")
      expect(input[:class]).to include("hover:border-zinc-400")
    end
  end

  describe "custom attributes and classes" do
    let(:options) do
      {
        id: "custom-input",
        class: "custom-class",
        data: { test_id: "my-input" },
        "aria-label": "Custom label"
      }
    end

    it "passes through custom attributes" do
      input = doc.find("input")
      expect(input[:id]).to eq("custom-input")
      expect(input[:class]).to include("custom-class")
      expect(input["data-test-id"]).to eq("my-input")
      expect(input["aria-label"]).to eq("Custom label")
    end
  end

  describe "input ID generation" do
    context "with custom ID" do
      let(:options) { { id: "custom-id" } }

      it "uses custom ID" do
        input = doc.find("input")
        expect(input[:id]).to eq("custom-id")
      end
    end

    context "with name but no ID" do
      let(:options) { { name: "user_email" } }

      it "generates ID from name" do
        input = doc.find("input")
        expect(input[:id]).to eq("input_user_email")
      end
    end

    context "without name or ID" do
      it "generates random ID" do
        input = doc.find("input")
        expect(input[:id]).to match(/input_[a-f0-9]{8}/)
      end
    end
  end

  describe "wrapper structure" do
    it "has proper nesting structure" do
      expect(doc).to have_css("div.space-y-1 > span[data-slot='control'] > input")
    end

    it "applies wrapper classes" do
      wrapper = doc.find("div")
      expect(wrapper[:class]).to include("space-y-1")
    end

    it "applies input group classes" do
      group = doc.find("span[data-slot='control']")
      expect(group[:class]).to include(
        "relative",
        "block",
        "w-full"
      )
    end
  end
end
