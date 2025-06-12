# frozen_string_literal: true

require "rails_helper"

# Test component for BaseComponent specs
class TestComponent < Catalyst::BaseComponent
  def initialize(variant: :primary, size: :md, **options)
    @variant = variant
    @size = size
    @options = options

    validate_variant!(variant)
    validate_size!(size)
  end

  def call
    tag.div(class: class_names("test-component", VARIANT_CLASSES[@variant], SIZE_CLASSES[@size]),
             **stimulus_attributes("test", click: "handleClick"),
             **aria_attributes(@options[:aria] || {}),
             **test_selector("test-component")) do
      "Test Content"
    end
  end
end

RSpec.describe Catalyst::BaseComponent, type: :component do
  describe "class inheritance" do
    it "inherits from ViewComponent::Base" do
      expect(described_class.ancestors).to include(ViewComponent::Base)
    end

    it "includes ApplicationHelper" do
      expect(described_class.ancestors).to include(ApplicationHelper)
    end
  end

  describe "constants" do
    it "defines VARIANT_CLASSES" do
      expect(Catalyst::BaseComponent::VARIANT_CLASSES).to eq({
        primary: "primary",
        secondary: "secondary",
        danger: "danger",
        ghost: "ghost",
        success: "success",
        warning: "warning",
        info: "info"
      })
    end

    it "defines SIZE_CLASSES" do
      expect(Catalyst::BaseComponent::SIZE_CLASSES).to eq({
        xs: "xs",
        sm: "sm",
        md: "md",
        lg: "lg",
        xl: "xl"
      })
    end
  end

  describe "helper methods" do
    let(:component) { TestComponent.new }
    let(:doc) { render_component(component) }

    describe "#class_names" do
      it "merges multiple class strings" do
        result = component.send(:class_names, "class1", "class2", "class3")
        expect(result).to eq("class1 class2 class3")
      end

      it "removes duplicates" do
        result = component.send(:class_names, "class1", "class2", "class1")
        expect(result).to eq("class1 class2")
      end

      it "handles nil values" do
        result = component.send(:class_names, "class1", nil, "class2")
        expect(result).to eq("class1 class2")
      end

      it "flattens arrays" do
        result = component.send(:class_names, [ "class1", "class2" ], "class3")
        expect(result).to eq("class1 class2 class3")
      end
    end

    describe "#stimulus_attributes" do
      it "generates controller attribute" do
        attrs = component.send(:stimulus_attributes, "modal")
        expect(attrs).to eq({ "data-controller" => "modal" })
      end

      it "generates action attributes" do
        attrs = component.send(:stimulus_attributes, "modal", click: "open", keydown: "handleKey")
        expect(attrs).to eq({
          "data-controller" => "modal",
          "data-action" => "click->modal#open keydown->modal#handleKey"
        })
      end
    end

    describe "#aria_attributes" do
      it "generates ARIA attributes" do
        attrs = component.send(:aria_attributes, {
          label: "Test Label",
          hidden: true,
          expanded: false,
          controls: "target-id"
        })

        expect(attrs).to eq({
          "aria-label" => "Test Label",
          "aria-hidden" => true,
          "aria-expanded" => false,
          "aria-controls" => "target-id"
        })
      end

      it "omits nil values" do
        attrs = component.send(:aria_attributes, { label: nil })
        expect(attrs).to eq({})
      end
    end

    describe "#test_selector" do
      it "generates test selector in test environment" do
        selector = component.send(:test_selector, "my-component")
        expect(selector).to eq({ "data-test" => "my-component" })
      end
    end

    describe "#validate_variant!" do
      it "accepts valid variants" do
        expect { component.send(:validate_variant!, :primary) }.not_to raise_error
      end

      it "raises error for invalid variants" do
        expect { component.send(:validate_variant!, :invalid) }
          .to raise_error(ArgumentError, /Invalid variant: invalid/)
      end
    end

    describe "#validate_size!" do
      it "accepts valid sizes" do
        expect { component.send(:validate_size!, :md) }.not_to raise_error
      end

      it "raises error for invalid sizes" do
        expect { component.send(:validate_size!, :invalid) }
          .to raise_error(ArgumentError, /Invalid size: invalid/)
      end
    end
  end

  describe "rendered output" do
    it "renders with all helper methods applied" do
      component = TestComponent.new(
        variant: :primary,
        size: :lg,
        aria: { label: "Test Component", expanded: true }
      )
      doc = render_component(component)
      element = doc.find(".test-component")

      expect(element[:class]).to include("test-component", "primary", "lg")
      expect(element[:"data-controller"]).to eq("test")
      expect(element[:"data-action"]).to eq("click->test#handleClick")
      expect(element[:"aria-label"]).to eq("Test Component")
      expect(element[:"aria-expanded"]).to eq("true")
      expect(element[:"data-test"]).to eq("test-component")
      expect(element.text).to include("Test Content")
    end
  end
end
