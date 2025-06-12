# frozen_string_literal: true

module Catalyst
  # Base component class for all Catalyst components
  # Provides shared functionality and consistent patterns
  class BaseComponent < ViewComponent::Base
    include ApplicationHelper

    # Common variant mappings used across components
    VARIANT_CLASSES = {
      primary: "primary",
      secondary: "secondary",
      danger: "danger",
      ghost: "ghost",
      success: "success",
      warning: "warning",
      info: "info"
    }.freeze

    # Common size mappings
    SIZE_CLASSES = {
      xs: "xs",
      sm: "sm",
      md: "md",
      lg: "lg",
      xl: "xl"
    }.freeze

    private

    # Helper to merge CSS classes intelligently
    def class_names(*args)
      args.flatten.compact.uniq.join(" ")
    end

    # Helper to generate data attributes with optional controller
    def stimulus_attributes(controller_name, actions = {})
      attrs = { "data-controller" => controller_name }

      actions.each do |event, action|
        attrs["data-action"] = [ attrs["data-action"], "#{event}->#{controller_name}##{action}" ].compact.join(" ")
      end

      attrs
    end

    # Helper to ensure accessibility
    def aria_attributes(options = {})
      attrs = {}

      # Common ARIA attributes
      attrs["aria-hidden"] = options[:hidden] if options.key?(:hidden)
      attrs["aria-label"] = options[:label] if options[:label]
      attrs["aria-labelledby"] = options[:labelledby] if options[:labelledby]
      attrs["aria-describedby"] = options[:describedby] if options[:describedby]
      attrs["aria-expanded"] = options[:expanded] if options.key?(:expanded)
      attrs["aria-selected"] = options[:selected] if options.key?(:selected)
      attrs["aria-disabled"] = options[:disabled] if options.key?(:disabled)
      attrs["aria-controls"] = options[:controls] if options[:controls]
      attrs["role"] = options[:role] if options[:role]

      attrs
    end

    # Helper to generate test selectors for easier testing
    def test_selector(name)
      return {} unless Rails.env.test? || Rails.env.development?

      { "data-test" => name }
    end

    # Validate variant against allowed options
    def validate_variant!(variant, allowed_variants = VARIANT_CLASSES.keys)
      return if allowed_variants.include?(variant)

      raise ArgumentError, "Invalid variant: #{variant}. Allowed variants: #{allowed_variants.join(', ')}"
    end

    # Validate size against allowed options
    def validate_size!(size, allowed_sizes = SIZE_CLASSES.keys)
      return if allowed_sizes.include?(size)

      raise ArgumentError, "Invalid size: #{size}. Allowed sizes: #{allowed_sizes.join(', ')}"
    end
  end
end
