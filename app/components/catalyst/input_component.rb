# frozen_string_literal: true

module Catalyst
  # Input component for forms with validation states and Rails integration
  # Supports various input types and error display
  class InputComponent < BaseComponent
    ALLOWED_TYPES = %w[
      text email password search tel url number
      date datetime-local month time week
      file hidden
    ].freeze

    def initialize(
      name: nil,
      type: "text",
      value: nil,
      placeholder: nil,
      label: nil,
      description: nil,
      required: false,
      disabled: false,
      readonly: false,
      autofocus: false,
      autocomplete: nil,
      maxlength: nil,
      minlength: nil,
      pattern: nil,
      leading_icon: nil,
      trailing_icon: nil,
      form_errors: nil,
      error_message: nil,
      **options
    )
      @name = name
      @type = type
      @value = value
      @placeholder = placeholder
      @label = label
      @description = description
      @required = required
      @disabled = disabled
      @readonly = readonly
      @autofocus = autofocus
      @autocomplete = autocomplete
      @maxlength = maxlength
      @minlength = minlength
      @pattern = pattern
      @leading_icon = leading_icon
      @trailing_icon = trailing_icon
      @form_errors = form_errors
      @error_message = error_message
      @options = options

      validate_type!
    end

    def call
      tag.div(class: wrapper_classes) do
        safe_join([
          label_element,
          input_group,
          description_element,
          error_element
        ].compact)
      end
    end

    private

    def label_element
      return unless @label

      tag.label(
        @label,
        for: input_id,
        class: label_classes
      )
    end

    def input_group
      tag.span(
        class: input_group_classes,
        data: { slot: "control" }
      ) do
        safe_join([
          leading_icon_element,
          input_element,
          trailing_icon_element
        ].compact)
      end
    end

    def input_element
      tag.input(
        type: @type,
        name: @name,
        id: input_id,
        value: @value,
        placeholder: @placeholder,
        required: @required,
        disabled: @disabled,
        readonly: @readonly,
        autofocus: @autofocus,
        autocomplete: @autocomplete,
        maxlength: @maxlength,
        minlength: @minlength,
        pattern: @pattern,
        class: input_classes,
        **input_attributes
      )
    end

    def leading_icon_element
      return unless @leading_icon

      render_icon(@leading_icon, "left")
    end

    def trailing_icon_element
      return unless @trailing_icon

      render_icon(@trailing_icon, "right")
    end

    def render_icon(icon, position)
      icon_class = class_names(
        "absolute top-1/2 -translate-y-1/2 pointer-events-none",
        "w-5 h-5 text-zinc-500",
        position == "left" ? "left-3" : "right-3"
      )

      case icon
      when :email
        email_icon(icon_class)
      when :lock
        lock_icon(icon_class)
      when :search
        search_icon(icon_class)
      when :user
        user_icon(icon_class)
      when :eye
        eye_icon(icon_class)
      when :eye_slash
        eye_slash_icon(icon_class)
      else
        icon if icon.is_a?(String)
      end
    end

    def email_icon(icon_class)
      tag.svg(
        class: icon_class,
        fill: "none",
        stroke: "currentColor",
        viewbox: "0 0 24 24",
        data: { slot: "icon" },
        "aria-hidden": true
      ) do
        tag.path(
          "stroke-linecap": "round",
          "stroke-linejoin": "round",
          "stroke-width": "2",
          d: "M16 12a4 4 0 10-8 0 4 4 0 008 0zm0 0v1.5a2.5 2.5 0 005 0V12a9 9 0 10-9 9m4.5-1.206a8.959 8.959 0 01-4.5 1.207"
        )
      end
    end

    def lock_icon(icon_class)
      tag.svg(
        class: icon_class,
        fill: "none",
        stroke: "currentColor",
        viewbox: "0 0 24 24",
        data: { slot: "icon" },
        "aria-hidden": true
      ) do
        tag.path(
          "stroke-linecap": "round",
          "stroke-linejoin": "round",
          "stroke-width": "2",
          d: "M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z"
        )
      end
    end

    def search_icon(icon_class)
      tag.svg(
        class: icon_class,
        fill: "none",
        stroke: "currentColor",
        viewbox: "0 0 24 24",
        data: { slot: "icon" },
        "aria-hidden": true
      ) do
        tag.path(
          "stroke-linecap": "round",
          "stroke-linejoin": "round",
          "stroke-width": "2",
          d: "M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"
        )
      end
    end

    def user_icon(icon_class)
      tag.svg(
        class: icon_class,
        fill: "none",
        stroke: "currentColor",
        viewbox: "0 0 24 24",
        data: { slot: "icon" },
        "aria-hidden": true
      ) do
        tag.path(
          "stroke-linecap": "round",
          "stroke-linejoin": "round",
          "stroke-width": "2",
          d: "M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"
        )
      end
    end

    def eye_icon(icon_class)
      tag.svg(
        class: icon_class,
        fill: "none",
        stroke: "currentColor",
        viewbox: "0 0 24 24",
        data: { slot: "icon" },
        "aria-hidden": true
      ) do
        tag.path(
          "stroke-linecap": "round",
          "stroke-linejoin": "round",
          "stroke-width": "2",
          d: "M15 12a3 3 0 11-6 0 3 3 0 016 0z"
        ) +
        tag.path(
          "stroke-linecap": "round",
          "stroke-linejoin": "round",
          "stroke-width": "2",
          d: "M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"
        )
      end
    end

    def eye_slash_icon(icon_class)
      tag.svg(
        class: icon_class,
        fill: "none",
        stroke: "currentColor",
        viewbox: "0 0 24 24",
        data: { slot: "icon" },
        "aria-hidden": true
      ) do
        tag.path(
          "stroke-linecap": "round",
          "stroke-linejoin": "round",
          "stroke-width": "2",
          d: "M13.875 18.825A10.05 10.05 0 0112 19c-4.478 0-8.268-2.943-9.543-7a9.97 9.97 0 011.563-3.029m5.858.908a3 3 0 114.243 4.243M9.878 9.878l4.242 4.242M9.878 9.878L3 3m6.878 6.878L21 21"
        )
      end
    end

    def description_element
      return unless @description

      tag.p(
        @description,
        class: "mt-1 text-sm text-zinc-600",
        id: "#{input_id}-description"
      )
    end

    def error_element
      return unless has_errors?

      tag.p(
        error_text,
        class: "mt-1 text-sm text-red-600",
        id: "#{input_id}-error",
        role: "alert"
      )
    end

    def wrapper_classes
      "space-y-1"
    end

    def label_classes
      class_names(
        "block text-sm font-medium text-zinc-700",
        "required:after:content-['*'] required:after:ml-0.5 required:after:text-red-500" => @required
      )
    end

    def input_group_classes
      class_names(
        "relative block w-full",
        # Shadow and background for light mode
        "before:absolute before:inset-px before:rounded-lg before:bg-white before:shadow-sm",
        # Hide before pseudo in dark mode
        "dark:before:hidden",
        # Focus ring
        "after:pointer-events-none after:absolute after:inset-0 after:rounded-lg after:ring-transparent",
        "focus-within:after:ring-2 focus-within:after:ring-blue-500 focus-within:after:ring-offset-0",
        # Disabled state
        "has-[:disabled]:opacity-50 has-[:disabled]:before:bg-zinc-50 has-[:disabled]:before:shadow-none",
        # Error state
        "has-[:invalid]:after:ring-red-500 has-[:invalid]:before:shadow-red-500/10" => has_errors?,
        # Icon padding
        "has-[svg:first-child]:pl-10 has-[svg:last-child]:pr-10" => @leading_icon || @trailing_icon
      )
    end

    def input_classes
      class_names(
        # Basic layout
        "relative block w-full appearance-none rounded-lg",
        "px-3 py-2 sm:px-3 sm:py-1.5",
        # Typography
        "text-base text-zinc-950 placeholder:text-zinc-500 sm:text-sm",
        "dark:text-white dark:placeholder:text-zinc-400",
        # Border
        "border border-zinc-300 hover:border-zinc-400",
        "dark:border-zinc-600 dark:hover:border-zinc-500",
        # Background
        "bg-transparent dark:bg-zinc-800/50",
        # Focus styles
        "focus:outline-none focus:ring-0 focus:border-transparent",
        # Error state
        error_input_classes,
        # Disabled state
        "disabled:border-zinc-200 disabled:bg-zinc-50 disabled:text-zinc-500",
        "dark:disabled:border-zinc-700 dark:disabled:bg-zinc-800 dark:disabled:text-zinc-400",
        # Icon padding
        icon_padding_classes,
        # Custom classes
        @options[:class]
      )
    end

    def error_input_classes
      return unless has_errors?

      "border-red-500 hover:border-red-500 focus:border-red-500"
    end

    def icon_padding_classes
      return unless @leading_icon || @trailing_icon

      class_names(
        "pl-10" => @leading_icon,
        "pr-10" => @trailing_icon
      )
    end

    def input_attributes
      attrs = @options.except(:class)

      # ARIA attributes
      attrs["aria-invalid"] = true if has_errors?
      attrs["aria-describedby"] = describedby_ids if describedby_ids.present?
      attrs["aria-required"] = true if @required

      # Test selector
      attrs.merge!(test_selector("input-#{@name || @type}"))

      attrs
    end

    def describedby_ids
      ids = []
      ids << "#{input_id}-description" if @description
      ids << "#{input_id}-error" if has_errors?
      ids.join(" ") if ids.any?
    end

    def input_id
      @input_id ||= @options[:id] || "input_#{@name || SecureRandom.hex(4)}"
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

    def validate_type!
      return if ALLOWED_TYPES.include?(@type)

      raise ArgumentError, "Invalid type: #{@type}. Allowed types: #{ALLOWED_TYPES.join(', ')}"
    end
  end
end
