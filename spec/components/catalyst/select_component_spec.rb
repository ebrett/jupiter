# frozen_string_literal: true

require "rails_helper"

RSpec.describe Catalyst::SelectComponent, type: :component do
  subject(:component) { described_class.new(**options) }

  let(:options) { {} }
  let(:doc) { render_component(component) }

  describe "basic rendering" do
    it "renders a select element" do
      expect(doc).to have_css("select")
    end

    it "includes test selector" do
      expect(doc).to have_css("select[data-test='select-anonymous']")
    end

    it "includes chevron icon" do
      expect(doc).to have_css("svg")
    end

    it "has proper appearance-none styling" do
      select_element = doc.find("select")
      expect(select_element[:class]).to include("appearance-none")
    end
  end

  describe "select attributes" do
    let(:options) do
      {
        name: "country",
        value: "us",
        required: true,
        disabled: false,
        multiple: false
      }
    end

    it "applies all select attributes" do
      select_element = doc.find("select")
      expect(select_element[:name]).to eq("country")
      expect(select_element[:required]).to eq("required")
      expect(select_element[:multiple]).to be_falsey
    end

    it "includes correct test selector" do
      expect(doc).to have_css("select[data-test='select-country']")
    end

    context "when disabled" do
      let(:options) { { disabled: true } }

      it "adds disabled attribute" do
        select_element = doc.find("select")
        expect(select_element[:disabled]).to eq("disabled")
      end

      it "applies disabled styling" do
        select_element = doc.find("select")
        expect(select_element[:class]).to include("disabled:cursor-not-allowed", "disabled:bg-gray-50")
      end
    end

    context "when multiple" do
      let(:options) { { multiple: true, size: 5 } }

      it "adds multiple attribute" do
        select_element = doc.find("select")
        expect(select_element[:multiple]).to eq("multiple")
      end

      it "adds size attribute" do
        select_element = doc.find("select")
        expect(select_element[:size]).to eq("5")
      end
    end
  end

  describe "with label" do
    let(:options) { { label: "Choose your country", name: "country" } }

    it "renders in field layout" do
      expect(doc).to have_css("div.grid")
    end

    it "renders label text" do
      expect(doc).to have_css("label", text: "Choose your country")
    end

    it "associates label with select" do
      label = doc.find("label")
      select_element = doc.find("select")
      expect(label[:for]).to eq(select_element[:id])
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
        label: "Country",
        description: "Select your country of residence",
        name: "country"
      }
    end

    it "renders description text" do
      expect(doc).to have_css("span", text: "Select your country of residence")
    end

    it "applies description styling" do
      description = doc.find("span", text: "Select your country of residence")
      expect(description[:class]).to include("text-sm", "text-gray-600")
    end

    it "associates description with select" do
      select_element = doc.find("select")
      description = doc.find("span", text: "Select your country of residence")
      expect(select_element["aria-describedby"]).to include(description[:id])
    end
  end

  describe "error states" do
    context "with error message" do
      let(:options) do
        {
          label: "Country",
          error_message: "Please select a country",
          name: "country"
        }
      end

      it "renders error message" do
        expect(doc).to have_css("span[role='alert']", text: "Please select a country")
      end

      it "applies error styling to message" do
        error = doc.find("span[role='alert']")
        expect(error[:class]).to include("text-red-600")
      end

      it "applies error styling to select" do
        select_element = doc.find("select")
        expect(select_element[:class]).to include("ring-red-300", "focus:ring-red-500")
      end

      it "applies error styling to chevron" do
        icon = doc.find("svg")
        expect(icon[:class]).to include("text-red-400")
      end

      it "marks select as invalid" do
        select_element = doc.find("select")
        expect(select_element["aria-invalid"]).to eq("true")
      end

      it "associates error with select" do
        select_element = doc.find("select")
        error = doc.find("span[role='alert']")
        expect(select_element["aria-describedby"]).to include(error[:id])
      end
    end

    context "with Rails form errors" do
      let(:options) do
        {
          label: "Country",
          name: "country",
          form_errors: { "country" => [ "is required" ] }
        }
      end

      it "renders first error message" do
        expect(doc).to have_css("span[role='alert']", text: "is required")
      end

      it "applies error styling" do
        select_element = doc.find("select")
        expect(select_element[:class]).to include("ring-red-300")
      end
    end
  end

  describe "options rendering" do
    context "with simple string array" do
      let(:options) do
        {
          label: "Fruit",
          name: "fruit",
          options: [ "Apple", "Banana", "Cherry" ],
          value: "Banana"
        }
      end

      it "renders all options" do
        expect(doc).to have_css("option", count: 4) # Including blank option
        expect(doc).to have_css("option", text: "Apple")
        expect(doc).to have_css("option", text: "Banana")
        expect(doc).to have_css("option", text: "Cherry")
      end

      it "selects the correct option" do
        banana_option = doc.find("option", text: "Banana")
        expect(banana_option[:selected]).to eq("selected")
      end

      it "includes blank option by default" do
        expect(doc).to have_css("option[value='']", text: "Select an option")
      end
    end

    context "with array of [text, value] pairs" do
      let(:options) do
        {
          label: "Country",
          name: "country",
          options: [
            [ "United States", "us" ],
            [ "Canada", "ca" ],
            [ "Mexico", "mx" ]
          ],
          value: "ca"
        }
      end

      it "renders options with correct text and values" do
        expect(doc).to have_css("option[value='us']", text: "United States")
        expect(doc).to have_css("option[value='ca']", text: "Canada")
        expect(doc).to have_css("option[value='mx']", text: "Mexico")
      end

      it "selects the correct option by value" do
        canada_option = doc.find("option[value='ca']")
        expect(canada_option[:selected]).to eq("selected")
      end
    end

    context "with custom blank option" do
      let(:options) do
        {
          label: "Priority",
          name: "priority",
          options: [ "High", "Medium", "Low" ],
          include_blank: "Choose priority..."
        }
      end

      it "uses custom blank text" do
        expect(doc).to have_css("option[value='']", text: "Choose priority...")
      end
    end

    context "without blank option" do
      let(:options) do
        {
          label: "Status",
          name: "status",
          options: [ "Active", "Inactive" ],
          include_blank: false
        }
      end

      it "does not include blank option" do
        expect(doc).not_to have_css("option[value='']")
        expect(doc).to have_css("option", count: 2)
      end
    end

    context "with multiple selection" do
      let(:options) do
        {
          label: "Skills",
          name: "skills[]",
          options: [ "Ruby", "JavaScript", "Python" ],
          multiple: true,
          value: [ "Ruby", "Python" ]
        }
      end

      it "selects multiple values" do
        ruby_option = doc.find("option", text: "Ruby")
        python_option = doc.find("option", text: "Python")
        js_option = doc.find("option", text: "JavaScript")

        expect(ruby_option[:selected]).to eq("selected")
        expect(python_option[:selected]).to eq("selected")
        expect(js_option[:selected]).to be_nil
      end

      it "does not include blank option for multiple selects" do
        expect(doc).not_to have_css("option[value='']")
      end
    end
  end

  describe "visual styling" do
    it "includes proper select styling" do
      select_element = doc.find("select")
      expect(select_element[:class]).to include(
        "block", "w-full", "rounded-md", "border-0",
        "ring-1", "ring-inset", "ring-gray-300"
      )
    end

    it "positions chevron icon correctly" do
      chevron_wrapper = doc.find("div", class: /absolute/)
      expect(chevron_wrapper[:class]).to include(
        "pointer-events-none", "absolute", "inset-y-0", "right-0"
      )
    end

    it "renders chevron SVG with correct path" do
      expect(doc).to have_css("svg path[d='m19.5 8.25-7.5 7.5-7.5-7.5']")
    end
  end

  describe "accessibility" do
    let(:options) do
      {
        label: "Country",
        description: "Select your country",
        required: true,
        name: "country"
      }
    end

    it "has proper ARIA attributes" do
      select_element = doc.find("select")
      expect(select_element["aria-required"]).to eq("true")
      expect(select_element["aria-describedby"]).to be_present
    end

    it "associates all descriptive elements" do
      select_element = doc.find("select")
      describedby = select_element["aria-describedby"]

      expect(describedby).to include("description")
    end

    it "uses semantic label association" do
      label = doc.find("label")
      select_element = doc.find("select")
      expect(label[:for]).to eq(select_element[:id])
    end
  end

  describe "focus and interaction styles" do
    it "includes focus styles" do
      select_element = doc.find("select")
      expect(select_element[:class]).to include("focus:ring-2", "focus:ring-blue-600")
    end

    it "removes default browser appearance" do
      select_element = doc.find("select")
      expect(select_element[:class]).to include("appearance-none")
    end
  end

  describe "custom attributes" do
    let(:options) do
      {
        id: "custom-select",
        class: "custom-class",
        data: { action: "change->form#validate" },
        name: "custom"
      }
    end

    it "passes through custom attributes to select" do
      select_element = doc.find("select")
      expect(select_element[:id]).to eq("custom-select")
      expect(select_element["data-action"]).to eq("change->form#validate")
    end

    it "merges custom classes" do
      select_element = doc.find("select")
      expect(select_element[:class]).to include("custom-class")
    end
  end

  describe "standalone select (no label)" do
    let(:options) do
      {
        name: "status",
        options: [ "Active", "Inactive" ]
      }
    end

    it "renders just the select element with wrapper" do
      expect(doc).to have_css("div.relative > select")
      expect(doc).not_to have_css("div.grid")
    end

    it "does not use field layout" do
      expect(doc).not_to have_css("label")
    end
  end

  describe "ID generation" do
    context "with custom ID" do
      let(:options) { { id: "my-select" } }

      it "uses custom ID" do
        select_element = doc.find("select")
        expect(select_element[:id]).to eq("my-select")
      end
    end

    context "with name but no ID" do
      let(:options) { { name: "user_country" } }

      it "generates ID from name" do
        select_element = doc.find("select")
        expect(select_element[:id]).to eq("select_user_country")
      end
    end

    context "with array name" do
      let(:options) { { name: "user[preferences][]" } }

      it "generates clean ID from array name" do
        select_element = doc.find("select")
        expect(select_element[:id]).to eq("select_user_preferences")
      end
    end

    context "without name or ID" do
      it "generates random ID" do
        select_element = doc.find("select")
        expect(select_element[:id]).to match(/select_[a-f0-9]{8}/)
      end
    end
  end

  describe "empty options" do
    let(:options) do
      {
        label: "Empty Select",
        name: "empty",
        options: []
      }
    end

    it "renders select with only blank option" do
      expect(doc).to have_css("option", count: 1)
      expect(doc).to have_css("option[value='']")
    end
  end
end
