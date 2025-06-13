# frozen_string_literal: true

module Catalyst
  # Button component with multiple variants and sizes
  # Supports solid, outline, and plain styles with various color options
  class ButtonComponent < BaseComponent
    ALLOWED_VARIANTS = %i[primary secondary danger ghost].freeze
    ALLOWED_SIZES = %i[sm md lg].freeze
    ALLOWED_TYPES = %w[button submit reset].freeze

    def initialize(
      variant: :primary,
      size: :md,
      outline: false,
      plain: false,
      loading: false,
      disabled: false,
      type: "button",
      href: nil,
      **options
    )
      @variant = variant
      @size = size
      @outline = outline
      @plain = plain
      @loading = loading
      @disabled = disabled || loading
      @type = type
      @href = href
      @options = options

      validate_variant!(@variant, ALLOWED_VARIANTS)
      validate_size!(@size, ALLOWED_SIZES)
      validate_type!
    end

    def call
      if @href.present?
        render_link
      else
        render_button
      end
    end

    private

    def render_link
      link_to @href, class: css_classes, **link_attributes do
        button_content
      end
    end

    def render_button
      tag.button(
        type: @type,
        class: css_classes,
        disabled: @disabled,
        **button_attributes
      ) do
        button_content
      end
    end

    def button_content
      tag.span(class: "flex items-center justify-center gap-2") do
        safe_join([
          loading_spinner,
          content
        ].compact)
      end
    end

    def loading_spinner
      return unless @loading

      tag.svg(
        class: "animate-spin h-4 w-4",
        xmlns: "http://www.w3.org/2000/svg",
        fill: "none",
        viewBox: "0 0 24 24",
        "aria-hidden": true
      ) do
        tag.circle(
          class: "opacity-25",
          cx: "12",
          cy: "12",
          r: "10",
          stroke: "currentColor",
          "stroke-width": "4"
        ) +
        tag.path(
          class: "opacity-75",
          fill: "currentColor",
          d: "M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
        )
      end
    end

    def css_classes
      class_names(
        base_classes,
        size_classes,
        variant_classes,
        state_classes,
        @options[:class]
      )
    end

    def base_classes
      [
        "relative inline-flex items-center justify-center",
        "font-medium rounded-md",
        "transition-colors duration-200",
        "focus:outline-none focus:ring-2 focus:ring-offset-2",
        "disabled:opacity-50 disabled:cursor-not-allowed"
      ]
    end

    def size_classes
      case @size
      when :sm
        "px-3 py-1.5 text-sm"
      when :md
        "px-4 py-2 text-base"
      when :lg
        "px-6 py-3 text-lg"
      end
    end

    def variant_classes
      if @plain
        plain_variant_classes
      elsif @outline
        outline_variant_classes
      else
        solid_variant_classes
      end
    end

    def solid_variant_classes
      case @variant
      when :primary
        [
          "bg-indigo-600 text-white",
          "hover:bg-indigo-700",
          "focus:ring-indigo-500",
          "disabled:hover:bg-indigo-600"
        ]
      when :secondary
        [
          "bg-gray-200 text-gray-900",
          "hover:bg-gray-300",
          "focus:ring-gray-500",
          "disabled:hover:bg-gray-200"
        ]
      when :danger
        [
          "bg-red-600 text-white",
          "hover:bg-red-700",
          "focus:ring-red-500",
          "disabled:hover:bg-red-600"
        ]
      when :ghost
        [
          "bg-transparent text-gray-700",
          "hover:bg-gray-100",
          "focus:ring-gray-500",
          "disabled:hover:bg-transparent"
        ]
      end
    end

    def outline_variant_classes
      case @variant
      when :primary
        [
          "border border-indigo-600 text-indigo-600",
          "hover:bg-indigo-50",
          "focus:ring-indigo-500",
          "disabled:hover:bg-transparent"
        ]
      when :secondary
        [
          "border border-gray-300 text-gray-700",
          "hover:bg-gray-50",
          "focus:ring-gray-500",
          "disabled:hover:bg-transparent"
        ]
      when :danger
        [
          "border border-red-600 text-red-600",
          "hover:bg-red-50",
          "focus:ring-red-500",
          "disabled:hover:bg-transparent"
        ]
      when :ghost
        [
          "border border-transparent text-gray-700",
          "hover:bg-gray-100",
          "focus:ring-gray-500",
          "disabled:hover:bg-transparent"
        ]
      end
    end

    def plain_variant_classes
      case @variant
      when :primary
        [
          "text-indigo-600",
          "hover:text-indigo-700 hover:bg-indigo-50",
          "focus:ring-indigo-500"
        ]
      when :secondary
        [
          "text-gray-700",
          "hover:text-gray-900 hover:bg-gray-50",
          "focus:ring-gray-500"
        ]
      when :danger
        [
          "text-red-600",
          "hover:text-red-700 hover:bg-red-50",
          "focus:ring-red-500"
        ]
      when :ghost
        [
          "text-gray-700",
          "hover:text-gray-900 hover:bg-gray-50",
          "focus:ring-gray-500"
        ]
      end
    end

    def state_classes
      return "cursor-wait" if @loading
      return "cursor-not-allowed" if @disabled
      "cursor-pointer"
    end

    def button_attributes
      attrs = @options.except(:class, :variant, :size, :outline, :plain)
      attrs.merge!(
        aria_attributes(
          disabled: @disabled,
          label: @options[:aria_label]
        )
      )
      attrs.merge!(test_selector("button-#{@variant}"))
      attrs[:data] ||= {}
      attrs[:data][:loading] = true if @loading
      attrs
    end

    def link_attributes
      attrs = @options.except(:class, :variant, :size, :outline, :plain, :type)
      attrs.merge!(
        aria_attributes(
          label: @options[:aria_label]
        )
      )
      attrs.merge!(test_selector("button-link-#{@variant}"))
      attrs
    end

    def validate_type!
      return if ALLOWED_TYPES.include?(@type)

      raise ArgumentError, "Invalid type: #{@type}. Allowed types: #{ALLOWED_TYPES.join(', ')}"
    end
  end
end
