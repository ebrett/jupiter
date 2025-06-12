# frozen_string_literal: true

require "rails_helper"

RSpec.describe Catalyst::CheckboxComponent, type: :component do
  subject(:component) { described_class.new(**options) }

  let(:options) { {} }
  let(:doc) { render_component(component) }

  describe "basic rendering" do
    it "renders a checkbox input" do
      expect(doc).to have_css("input[type='checkbox']")
    end

    it "wraps checkbox in a label" do
      expect(doc).to have_css("label > input[type='checkbox']")
    end

    it "includes visual checkbox span" do
      expect(doc).to have_css("label > span")
    end

    it "includes test selector" do
      expect(doc).to have_css("input[data-test='checkbox-anonymous']")
    end

    it "hides actual checkbox visually" do
      input = doc.find("input[type='checkbox']")
      expect(input[:class]).to include("sr-only")
    end
  end

  describe "checkbox attributes" do
    let(:options) do
      {
        name: "agree_terms",
        value: "yes",
        checked: true,
        disabled: false,
        required: true
      }
    end

    it "applies all checkbox attributes" do
      input = doc.find("input[type='checkbox']")
      expect(input[:name]).to eq("agree_terms")
      expect(input[:value]).to eq("yes")
      expect(input[:checked]).to be true
      expect(input[:required]).to eq("required")
    end

    it "includes correct test selector" do
      expect(doc).to have_css("input[data-test='checkbox-agree_terms']")
    end

    context "when not checked" do
      let(:options) { { name: "test_checkbox" } }

      it "does not have checked attribute" do
        input = doc.find("input[type='checkbox']")
        expect(input[:checked]).to be false
      end
    end

    context "when disabled" do
      let(:options) { { disabled: true } }

      it "adds disabled attribute" do
        input = doc.find("input[type='checkbox']")
        expect(input[:disabled]).to eq("disabled")
      end

      it "applies disabled styling" do
        span = doc.find("label > span")
        expect(span[:class]).to include("peer-disabled:opacity-50")
      end
    end
  end

  describe "with label" do
    let(:options) { { label: "I agree to the terms", name: "agree" } }

    it "renders in field layout" do
      expect(doc).to have_css("div.grid")
    end

    it "renders label text" do
      expect(doc).to have_css("span", text: "I agree to the terms")
    end

    it "associates label with checkbox" do
      label = doc.find("label")
      input = doc.find("input")
      expect(label[:for]).to eq(input[:id])
    end

    it "applies label styling" do
      label_span = doc.find("span[data-slot='label']")
      expect(label_span[:class]).to include("block", "text-sm", "font-medium")
    end

    context "when required" do
      let(:options) { { label: "Required field", required: true } }

      it "adds required indicator to label" do
        label_span = doc.find("span[data-slot='label']")
        expect(label_span[:class]).to include("required:after:content-['*']")
      end
    end
  end

  describe "with description" do
    let(:options) do
      {
        label: "Newsletter",
        description: "Receive updates about new features",
        name: "newsletter"
      }
    end

    it "renders description text" do
      expect(doc).to have_css("span", text: "Receive updates about new features")
    end

    it "applies description styling" do
      desc = doc.find("span:nth-of-type(2)")
      expect(desc[:class]).to include("text-sm", "text-zinc-600")
    end

    it "associates description with checkbox" do
      input = doc.find("input")
      description = doc.find("span:nth-of-type(2)")
      expect(input["aria-describedby"]).to include(description[:id])
    end
  end

  describe "error states" do
    context "with error message" do
      let(:options) do
        {
          label: "Accept terms",
          error_message: "You must accept the terms",
          name: "terms"
        }
      end

      it "renders error message" do
        expect(doc).to have_css("span[role='alert']", text: "You must accept the terms")
      end

      it "applies error styling to message" do
        error = doc.find("span[role='alert']")
        expect(error[:class]).to include("text-red-600")
      end

      it "applies error styling to visual checkbox" do
        visual = doc.find("label > span")
        expect(visual[:class]).to include("border-red-500")
      end

      it "marks checkbox as invalid" do
        input = doc.find("input")
        expect(input["aria-invalid"]).to eq("true")
      end

      it "associates error with checkbox" do
        input = doc.find("input")
        error = doc.find("span[role='alert']")
        expect(input["aria-describedby"]).to include(error[:id])
      end
    end

    context "with Rails form errors" do
      let(:options) do
        {
          label: "Terms",
          name: "terms",
          form_errors: { "terms" => [ "must be accepted" ] }
        }
      end

      it "renders first error message" do
        expect(doc).to have_css("span[role='alert']", text: "must be accepted")
      end

      it "applies error styling" do
        visual = doc.find("label > span")
        expect(visual[:class]).to include("border-red-500")
      end
    end
  end

  describe "colors" do
    context "with primary color" do
      let(:options) { { color: :primary } }

      it "uses blue color scheme" do
        visual = doc.find("label > span")
        expect(visual[:class]).to include("peer-checked:bg-blue-600")
      end
    end

    context "with green color" do
      let(:options) { { color: :green } }

      it "uses green color scheme" do
        visual = doc.find("label > span")
        expect(visual[:class]).to include("peer-checked:bg-green-600")
      end
    end

    context "with red color" do
      let(:options) { { color: :red } }

      it "uses red color scheme" do
        visual = doc.find("label > span")
        expect(visual[:class]).to include("peer-checked:bg-red-600")
      end
    end

    context "with invalid color" do
      it "raises an error" do
        expect { described_class.new(color: :invalid) }
          .to raise_error(ArgumentError, /Invalid color/)
      end
    end
  end

  describe "states" do
    context "when checked" do
      let(:options) { { checked: true } }

      it "has checked attribute" do
        input = doc.find("input")
        expect(input[:checked]).to be true
      end

      it "applies checked styling" do
        visual = doc.find("label > span")
        expect(visual[:class]).to include("peer-checked:bg-blue-600")
      end
    end

    context "when indeterminate" do
      let(:options) { { indeterminate: true } }

      it "sets data attribute for indeterminate" do
        input = doc.find("input")
        expect(input["data-indeterminate"]).to eq("true")
      end
    end
  end

  describe "visual elements" do
    it "renders checkmark icon" do
      expect(doc).to have_css("svg")
    end

    it "includes checkmark path" do
      expect(doc).to have_css("svg path")
    end

    it "applies proper icon styling" do
      icon = doc.find("svg")
      expect(icon[:class]).to include("stroke-white", "peer-checked:opacity-100")
    end

    it "hides icon by default" do
      icon = doc.find("svg")
      expect(icon[:class]).to include("opacity-0")
    end
  end

  describe "Rails form integration" do
    context "with hidden input for unchecked state" do
      let(:options) { { name: "newsletter" } }

      it "includes hidden input with value 0" do
        expect(doc).to have_css("input[type='hidden'][value='0']", visible: :all)
      end

      it "hidden input has same name" do
        hidden = doc.find("input[type='hidden']", visible: :all)
        expect(hidden[:name]).to eq("newsletter")
      end
    end

    context "without name" do
      it "does not include hidden input" do
        expect(doc).not_to have_css("input[type='hidden']")
      end
    end
  end

  describe "accessibility" do
    let(:options) do
      {
        label: "Subscribe",
        description: "Get email updates",
        required: true,
        name: "subscribe"
      }
    end

    it "has proper ARIA attributes" do
      input = doc.find("input")
      expect(input["aria-required"]).to eq("true")
      expect(input["aria-describedby"]).to be_present
    end

    it "associates all descriptive elements" do
      input = doc.find("input")
      describedby = input["aria-describedby"]

      expect(describedby).to include("description")
    end

    it "uses semantic label association" do
      label = doc.find("label")
      input = doc.find("input")
      expect(label[:for]).to eq(input[:id])
    end
  end

  describe "focus and interaction" do
    it "includes focus styles" do
      visual = doc.find("label > span")
      expect(visual[:class]).to include("peer-focus:ring-2", "peer-focus:ring-blue-500")
    end

    it "includes hover styles" do
      visual = doc.find("label > span")
      expect(visual[:class]).to include("hover:border-zinc-400")
    end

    it "has cursor pointer on label" do
      label = doc.find("label")
      expect(label[:class]).to include("cursor-pointer")
    end
  end

  describe "custom attributes" do
    let(:options) do
      {
        id: "custom-checkbox",
        class: "custom-class",
        data: { action: "change->form#validate" },
        name: "custom"
      }
    end

    it "passes through custom attributes to input" do
      input = doc.find("input")
      expect(input[:id]).to eq("custom-checkbox")
      expect(input["data-action"]).to eq("change->form#validate")
    end

    it "merges custom classes" do
      input = doc.find("input")
      expect(input[:class]).to include("custom-class")
    end
  end

  describe "standalone checkbox (no label)" do
    it "renders just the checkbox element" do
      expect(doc).to have_css("label > input")
      expect(doc).not_to have_css("div.grid")
    end

    it "does not use field layout" do
      expect(doc).not_to have_css("span[data-slot='label']")
    end
  end

  describe "ID generation" do
    context "with custom ID" do
      let(:options) { { id: "my-checkbox" } }

      it "uses custom ID" do
        input = doc.find("input")
        expect(input[:id]).to eq("my-checkbox")
      end
    end

    context "with name but no ID" do
      let(:options) { { name: "user_consent" } }

      it "generates ID from name" do
        input = doc.find("input")
        expect(input[:id]).to eq("checkbox_user_consent")
      end
    end

    context "without name or ID" do
      it "generates random ID" do
        input = doc.find("input")
        expect(input[:id]).to match(/checkbox_[a-f0-9]{8}/)
      end
    end
  end
end
