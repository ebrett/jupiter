# frozen_string_literal: true

module Catalyst
  class SelectComponent < BaseComponent
    attr_reader :label, :description, :error_message, :required, :disabled, :placeholder,
                :name, :value, :multiple, :size, :options, :include_blank, :form_errors

    def initialize(
      label: nil,
      description: nil,
      error_message: nil,
      required: false,
      disabled: false,
      placeholder: nil,
      name: nil,
      value: nil,
      multiple: false,
      size: nil,
      options: [],
      include_blank: nil,
      form_errors: nil,
      **attrs
    )
      @label = label
      @description = description
      @error_message = error_message
      @required = required
      @disabled = disabled
      @placeholder = placeholder
      @name = name
      @value = value
      @multiple = multiple
      @size = size
      @options = options
      @include_blank = include_blank
      @form_errors = form_errors
      @attrs = attrs

      super(**attrs)
    end

    def call
      if label.present?
        render_field_layout
      else
        render_standalone_select
      end
    end

    private

    def render_field_layout
      content_tag :div, class: field_wrapper_classes do
        safe_join([
          render_label,
          render_select_with_wrapper,
          render_description,
          render_error_message
        ].compact)
      end
    end

    def render_standalone_select
      render_select_with_wrapper
    end

    def render_label
      return unless label.present?

      content_tag :label, for: select_id do
        content_tag :span, label, **label_attributes
      end
    end

    def render_select_with_wrapper
      content_tag :div, class: select_wrapper_classes do
        safe_join([
          render_select,
          render_chevron_icon
        ])
      end
    end

    def render_select
      content_tag :select, **select_attributes do
        safe_join([
          render_blank_option,
          *render_options
        ].compact)
      end
    end

    def render_blank_option
      return unless should_include_blank?

      blank_text = include_blank.is_a?(String) ? include_blank : "Select an option"
      content_tag :option, blank_text, value: ""
    end

    def render_options
      return [] if options.empty?

      if options.first.is_a?(Array)
        # Handle array of [text, value] pairs
        options.map do |option_text, option_value|
          render_option(option_text, option_value)
        end
      elsif options.first.is_a?(String)
        # Handle simple array of strings
        options.map do |option|
          render_option(option, option)
        end
      else
        # Handle collection of objects with text/value methods
        options.map do |item|
          option_text = item.first
          option_value = item.last
          render_option(option_text, option_value)
        end
      end
    end

    def render_option(text, val)
      selected = option_selected?(val)
      content_tag :option, text, value: val, selected: selected
    end

    def render_chevron_icon
      content_tag :div, class: chevron_wrapper_classes do
        content_tag :svg, class: chevron_icon_classes, fill: "none", viewbox: "0 0 24 24", "stroke-width": "1.5", stroke: "currentColor" do
          content_tag :path, nil, "stroke-linecap": "round", "stroke-linejoin": "round", d: "m19.5 8.25-7.5 7.5-7.5-7.5"
        end
      end
    end

    def render_description
      return unless description.present?

      content_tag :span, description, id: description_id, class: description_classes
    end

    def render_error_message
      error_text = error_message || rails_errors&.first
      return unless error_text.present?

      content_tag :span, error_text, id: error_id, role: "alert", class: error_classes
    end

    def select_attributes
      attrs = @attrs.except(:class).merge({
        id: select_id,
        name: name,
        class: select_classes
      })

      attrs[:required] = "required" if required
      attrs[:disabled] = "disabled" if disabled
      attrs[:multiple] = "multiple" if multiple
      attrs[:size] = size if size.present?

      # Add ARIA attributes
      described_by_ids = []
      described_by_ids << description_id if description.present?
      described_by_ids << error_id if has_errors?

      attrs["aria-describedby"] = described_by_ids.join(" ") if described_by_ids.any?
      attrs["aria-invalid"] = "true" if has_errors?
      attrs["aria-required"] = "true" if required

      attrs.merge!(test_selector("select-#{name || 'anonymous'}"))

      attrs
    end

    def label_attributes
      attrs = { "data-slot": "label", class: label_classes }
      attrs
    end

    def field_wrapper_classes
      "grid grid-cols-1 gap-2"
    end

    def label_classes
      class_names(
        "block text-sm font-medium leading-6",
        error_label_classes,
        normal_label_classes,
        required_indicator_classes
      )
    end

    def error_label_classes
      return unless has_errors?

      "text-red-900"
    end

    def normal_label_classes
      return if has_errors?

      "text-gray-900"
    end

    def required_indicator_classes
      return unless required

      "required:after:content-['*'] required:after:ml-0.5 required:after:text-red-500"
    end

    def select_wrapper_classes
      "relative"
    end

    def select_classes
      class_names(
        # Base styles
        "block w-full rounded-md border-0 py-1.5 pl-3 pr-10",
        "text-gray-900 shadow-sm ring-1 ring-inset",
        "focus:ring-2 focus:ring-inset sm:text-sm sm:leading-6",
        "appearance-none bg-white",

        # States
        "placeholder:text-gray-400",
        "disabled:cursor-not-allowed disabled:bg-gray-50 disabled:text-gray-500 disabled:ring-gray-200",

        # Error/normal state
        error_select_classes,
        normal_select_classes,

        # Custom classes
        @attrs[:class]
      )
    end

    def error_select_classes
      return unless has_errors?

      "ring-red-300 focus:ring-red-500"
    end

    def normal_select_classes
      return if has_errors?

      "ring-gray-300 focus:ring-blue-600"
    end

    def chevron_wrapper_classes
      class_names(
        "pointer-events-none absolute inset-y-0 right-0 flex items-center pr-2"
      )
    end

    def chevron_icon_classes
      class_names(
        "h-5 w-5",
        error_chevron_classes,
        normal_chevron_classes
      )
    end

    def error_chevron_classes
      return unless has_errors?

      "text-red-400"
    end

    def normal_chevron_classes
      return if has_errors?

      "text-gray-400"
    end

    def description_classes
      "text-sm text-gray-600"
    end

    def error_classes
      "text-sm text-red-600"
    end

    def select_id
      @select_id ||= @attrs[:id] || (name ? "select_#{name.to_s.gsub(/[\[\]]/, '_').gsub(/__+/, '_').chomp('_')}" : "select_#{SecureRandom.hex(4)}")
    end

    def description_id
      "#{select_id}_description"
    end

    def error_id
      "#{select_id}_error"
    end

    def has_errors?
      error_message.present? || rails_errors.present?
    end

    def rails_errors
      return nil unless form_errors.present? && name.present?

      field_name = name.to_s.gsub(/\[\]$/, "").split("[").first
      form_errors[field_name]
    end

    def should_include_blank?
      include_blank == true ||
        (include_blank.is_a?(String) && include_blank.present?) ||
        (!multiple && include_blank != false && placeholder.nil?)
    end

    def option_selected?(option_value)
      return false unless value.present?

      if multiple
        Array(value).map(&:to_s).include?(option_value.to_s)
      else
        value.to_s == option_value.to_s
      end
    end
  end
end
