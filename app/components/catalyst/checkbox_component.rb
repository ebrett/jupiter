# frozen_string_literal: true

module Catalyst
  # Checkbox component with support for different states and descriptions
  # Supports checked, unchecked, indeterminate, and disabled states
  class CheckboxComponent < BaseComponent
    ALLOWED_COLORS = %i[
      default primary secondary
      red orange amber yellow lime green emerald teal cyan sky blue indigo violet purple fuchsia pink rose zinc
    ].freeze

    # Map simplified colors to Catalyst colors
    COLOR_MAP = {
      default: :"dark/zinc",
      primary: :blue,
      secondary: :zinc
    }.freeze

    def initialize(
      name: nil,
      value: "1",
      checked: false,
      indeterminate: false,
      disabled: false,
      required: false,
      label: nil,
      description: nil,
      color: :default,
      form_errors: nil,
      error_message: nil,
      **options
    )
      @name = name
      @value = value
      @checked = checked
      @indeterminate = indeterminate
      @disabled = disabled
      @required = required
      @label = label
      @description = description
      @color = color
      @form_errors = form_errors
      @error_message = error_message
      @options = options

      validate_color!
    end

    def call
      if @label || @description
        render_checkbox_field
      else
        render_checkbox_only
      end
    end

    private

    def render_checkbox_field
      tag.div(class: field_wrapper_classes) do
        safe_join([
          hidden_input_element,
          checkbox_element,
          label_element,
          description_element,
          error_element
        ].compact)
      end
    end

    def render_checkbox_only
      safe_join([
        hidden_input_element,
        checkbox_element
      ].compact)
    end

    def checkbox_element
      tag.label(
        class: checkbox_wrapper_classes,
        for: checkbox_id,
        **checkbox_wrapper_attributes
      ) do
        safe_join([
          actual_checkbox_input,
          checkbox_visual_element
        ].compact)
      end
    end

    def hidden_input_element
      # Hidden input for Rails form submission when unchecked
      tag.input(
        type: "hidden",
        name: @name,
        value: "0"
      ) if @name
    end

    def actual_checkbox_input
      tag.input(**checkbox_input_attributes)
    end

    def checkbox_visual_element
      tag.span(class: checkbox_visual_classes) do
        checkmark_icon
      end
    end

    def checkmark_icon
      tag.svg(
        class: icon_classes,
        viewbox: "0 0 14 14",
        fill: "none",
        "aria-hidden": true
      ) do
        safe_join([
          # Checkmark path
          tag.path(
            class: "opacity-100 group-data-[indeterminate]:opacity-0",
            d: "M3 8L6 11L11 3.5",
            "stroke-width": "2",
            "stroke-linecap": "round",
            "stroke-linejoin": "round"
          ),
          # Indeterminate path
          tag.path(
            class: "opacity-0 group-data-[indeterminate]:opacity-100",
            d: "M3 7H11",
            "stroke-width": "2",
            "stroke-linecap": "round",
            "stroke-linejoin": "round"
          )
        ])
      end
    end

    def label_element
      return unless @label

      tag.span(
        @label,
        class: label_classes,
        **label_attributes
      )
    end

    def description_element
      return unless @description

      tag.span(
        @description,
        class: description_classes,
        id: "#{checkbox_id}-description"
      )
    end

    def error_element
      return unless has_errors?

      tag.span(
        error_text,
        class: error_classes,
        id: "#{checkbox_id}-error",
        role: "alert"
      )
    end

    def field_wrapper_classes
      class_names(
        "grid grid-cols-[1rem_1fr] gap-x-3 gap-y-1",
        # Control positioning
        "*:data-[slot=control]:col-start-1 *:data-[slot=control]:row-start-1 *:data-[slot=control]:mt-0.5",
        # Label positioning
        "*:data-[slot=label]:col-start-2 *:data-[slot=label]:row-start-1",
        # Description positioning
        "*:data-[slot=description]:col-start-2 *:data-[slot=description]:row-start-2",
        # Error positioning (if any)
        "*:data-[slot=error]:col-start-2 *:data-[slot=error]:row-start-3" => has_errors?
      )
    end

    def checkbox_wrapper_classes
      class_names(
        "group inline-flex items-start cursor-pointer",
        "focus-within:outline-none" => @label || @description,
        "disabled:cursor-not-allowed disabled:opacity-50" => @disabled
      )
    end

    def checkbox_wrapper_attributes
      attrs = {}
      attrs[:data] = { slot: "control" } if @label || @description
      attrs
    end

    def checkbox_visual_classes
      class_names(
        # Basic layout
        "relative isolate flex size-4 items-center justify-center rounded",
        "border transition-colors duration-150",
        # Default unchecked state
        "border-zinc-300 bg-white",
        # Hover state
        "hover:border-zinc-400",
        # Focus state (using peer selector)
        "peer-focus:ring-2 peer-focus:ring-offset-1 peer-focus:ring-blue-500",
        # Checked state (using peer selector)
        "peer-checked:border-blue-600 peer-checked:bg-blue-600",
        "peer-checked:hover:border-blue-700 peer-checked:hover:bg-blue-700",
        # Disabled state
        "peer-disabled:opacity-50 peer-disabled:cursor-not-allowed",
        "peer-disabled:border-zinc-200 peer-disabled:bg-zinc-50",
        # Error state
        error_visual_classes,
        # Color variations
        color_visual_classes
      )
    end

    def icon_classes
      class_names(
        "size-3.5 transition-opacity duration-150",
        # Default state - hidden
        "opacity-0",
        # Show when checked
        "peer-checked:opacity-100",
        # Stroke color
        "stroke-white"
      )
    end

    def color_visual_classes
      return "" if @color == :default || @color == :"dark/zinc"

      color = COLOR_MAP[@color] || @color

      case color
      when :green
        "peer-checked:border-green-600 peer-checked:bg-green-600 peer-checked:hover:border-green-700 peer-checked:hover:bg-green-700"
      when :red
        "peer-checked:border-red-600 peer-checked:bg-red-600 peer-checked:hover:border-red-700 peer-checked:hover:bg-red-700"
      when :amber
        "peer-checked:border-amber-500 peer-checked:bg-amber-500 peer-checked:hover:border-amber-600 peer-checked:hover:bg-amber-600"
      when :indigo
        "peer-checked:border-indigo-600 peer-checked:bg-indigo-600 peer-checked:hover:border-indigo-700 peer-checked:hover:bg-indigo-700"
      when :purple
        "peer-checked:border-purple-600 peer-checked:bg-purple-600 peer-checked:hover:border-purple-700 peer-checked:hover:bg-purple-700"
      else
        ""
      end
    end

    def error_visual_classes
      return unless has_errors?

      "border-red-500 hover:border-red-500"
    end

    def label_classes
      class_names(
        "block text-sm font-medium text-zinc-900 cursor-pointer",
        "required:after:content-['*'] required:after:ml-0.5 required:after:text-red-500" => @required,
        "group-disabled:text-zinc-500" => @disabled
      )
    end

    def label_attributes
      attrs = { data: { slot: "label" } }
      attrs["aria-describedby"] = describedby_ids if describedby_ids.present?
      attrs
    end

    def description_classes
      class_names(
        "block text-sm text-zinc-600 mt-1",
        "group-disabled:text-zinc-400" => @disabled
      )
    end

    def error_classes
      "block text-sm text-red-600 mt-1"
    end

    def checkbox_input_attributes
      attrs = {
        type: "checkbox",
        name: @name,
        value: @value,
        id: checkbox_id,
        class: class_names("sr-only peer", @options[:class]) # Screen reader only, visually hidden, but used for styling
      }

      # Set checked state
      attrs[:checked] = @checked
      attrs[:disabled] = @disabled if @disabled
      attrs[:required] = @required if @required

      # Set indeterminate via data attribute (handled by JavaScript)
      attrs[:data] = { indeterminate: true } if @indeterminate

      # ARIA attributes
      attrs["aria-invalid"] = true if has_errors?
      attrs["aria-describedby"] = describedby_ids if describedby_ids.present?
      attrs["aria-required"] = true if @required

      # Custom attributes
      attrs.merge!(@options.except(:class))

      # Test selector
      attrs.merge!(test_selector("checkbox-#{@name || 'anonymous'}"))

      attrs
    end

    def describedby_ids
      ids = []
      ids << "#{checkbox_id}-description" if @description
      ids << "#{checkbox_id}-error" if has_errors?
      ids.join(" ") if ids.any?
    end

    def checkbox_id
      @checkbox_id ||= @options[:id] || "checkbox_#{@name || SecureRandom.hex(4)}"
    end

    def has_errors?
      @error_message.present? || rails_errors.present?
    end

    def error_text
      @error_message || rails_errors.first
    end

    def rails_errors
      return [] unless @form_errors && @name

      Array(@form_errors[@name.to_s] || @form_errors[@name.to_sym])
    end

    def validate_color!
      return if ALLOWED_COLORS.include?(@color)

      raise ArgumentError, "Invalid color: #{@color}. Allowed colors: #{ALLOWED_COLORS.join(', ')}"
    end
  end
end
