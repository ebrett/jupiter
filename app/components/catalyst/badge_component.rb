# frozen_string_literal: true

module Catalyst
  # Badge component for displaying status indicators, roles, and labels
  # Supports multiple color variants and sizes
  class BadgeComponent < BaseComponent
    ALLOWED_VARIANTS = %i[
      default success warning danger info
      primary secondary
      red orange amber yellow lime green emerald teal cyan sky blue indigo violet purple fuchsia pink rose zinc
    ].freeze

    ALLOWED_SIZES = %i[sm md].freeze

    # Map simplified variants to Catalyst colors
    VARIANT_COLOR_MAP = {
      default: :zinc,
      success: :green,
      warning: :amber,
      danger: :red,
      info: :blue,
      primary: :indigo,
      secondary: :zinc
    }.freeze

    def initialize(
      variant: :default,
      size: :sm,
      href: nil,
      icon: nil,
      dismissible: false,
      **options
    )
      @variant = variant
      @size = size
      @href = href
      @icon = icon
      @dismissible = dismissible
      @options = options

      validate_variant!(@variant, ALLOWED_VARIANTS)
      validate_size!(@size, ALLOWED_SIZES)
    end

    def call
      if @href.present?
        render_link_badge
      else
        render_badge
      end
    end

    private

    def render_badge
      tag.span(
        class: css_classes,
        **badge_attributes
      ) do
        badge_content
      end
    end

    def render_link_badge
      link_to @href, class: link_css_classes, **link_attributes do
        tag.span(class: css_classes) do
          badge_content
        end
      end
    end

    def badge_content
      safe_join([
        icon_element,
        content,
        dismiss_button
      ].compact)
    end

    def icon_element
      return unless @icon

      case @icon
      when :check
        check_icon
      when :warning
        warning_icon
      when :info
        info_icon
      when :x
        x_icon
      else
        @icon if @icon.is_a?(String)
      end
    end

    def check_icon
      tag.svg(
        class: icon_classes,
        fill: "currentColor",
        viewbox: "0 0 20 20",
        "aria-hidden": true
      ) do
        tag.path(
          "fill-rule": "evenodd",
          d: "M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z",
          "clip-rule": "evenodd"
        )
      end
    end

    def warning_icon
      tag.svg(
        class: icon_classes,
        fill: "currentColor",
        viewbox: "0 0 20 20",
        "aria-hidden": true
      ) do
        tag.path(
          "fill-rule": "evenodd",
          d: "M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z",
          "clip-rule": "evenodd"
        )
      end
    end

    def info_icon
      tag.svg(
        class: icon_classes,
        fill: "currentColor",
        viewbox: "0 0 20 20",
        "aria-hidden": true
      ) do
        tag.path(
          "fill-rule": "evenodd",
          d: "M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z",
          "clip-rule": "evenodd"
        )
      end
    end

    def x_icon
      tag.svg(
        class: icon_classes,
        fill: "currentColor",
        viewbox: "0 0 20 20",
        "aria-hidden": true
      ) do
        tag.path(
          "fill-rule": "evenodd",
          d: "M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z",
          "clip-rule": "evenodd"
        )
      end
    end

    def dismiss_button
      return unless @dismissible

      tag.button(
        type: "button",
        class: "ml-1.5 inline-flex items-center p-0.5 rounded-sm hover:bg-black/10 focus:outline-none focus:ring-2 focus:ring-offset-1 focus:ring-black/20",
        data: { action: "click->badge#dismiss" },
        "aria-label": "Dismiss"
      ) do
        tag.svg(
          class: "h-3 w-3",
          fill: "currentColor",
          viewbox: "0 0 20 20"
        ) do
          tag.path(
            "fill-rule": "evenodd",
            d: "M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z",
            "clip-rule": "evenodd"
          )
        end
      end
    end

    def css_classes
      class_names(
        base_classes,
        size_classes,
        color_classes,
        @options[:class]
      )
    end

    def link_css_classes
      class_names(
        "inline-flex items-center group",
        "focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 rounded-md"
      )
    end

    def base_classes
      [
        "inline-flex items-center gap-x-1.5",
        @size == :sm ? "rounded" : "rounded-md",
        "font-medium",
        "transition-colors duration-150"
      ]
    end

    def size_classes
      case @size
      when :sm
        "px-1.5 py-0.5 text-xs"
      when :md
        "px-2 py-1 text-sm"
      end
    end

    def color_classes
      color = VARIANT_COLOR_MAP[@variant] || @variant

      case color
      when :zinc
        "bg-zinc-100 text-zinc-700 hover:bg-zinc-200"
      when :red
        "bg-red-100 text-red-700 hover:bg-red-200"
      when :orange
        "bg-orange-100 text-orange-700 hover:bg-orange-200"
      when :amber
        "bg-amber-100 text-amber-700 hover:bg-amber-200"
      when :yellow
        "bg-yellow-100 text-yellow-700 hover:bg-yellow-200"
      when :lime
        "bg-lime-100 text-lime-700 hover:bg-lime-200"
      when :green
        "bg-green-100 text-green-700 hover:bg-green-200"
      when :emerald
        "bg-emerald-100 text-emerald-700 hover:bg-emerald-200"
      when :teal
        "bg-teal-100 text-teal-700 hover:bg-teal-200"
      when :cyan
        "bg-cyan-100 text-cyan-700 hover:bg-cyan-200"
      when :sky
        "bg-sky-100 text-sky-700 hover:bg-sky-200"
      when :blue
        "bg-blue-100 text-blue-700 hover:bg-blue-200"
      when :indigo
        "bg-indigo-100 text-indigo-700 hover:bg-indigo-200"
      when :violet
        "bg-violet-100 text-violet-700 hover:bg-violet-200"
      when :purple
        "bg-purple-100 text-purple-700 hover:bg-purple-200"
      when :fuchsia
        "bg-fuchsia-100 text-fuchsia-700 hover:bg-fuchsia-200"
      when :pink
        "bg-pink-100 text-pink-700 hover:bg-pink-200"
      when :rose
        "bg-rose-100 text-rose-700 hover:bg-rose-200"
      end
    end

    def icon_classes
      @size == :sm ? "w-3 h-3" : "w-4 h-4"
    end

    def badge_attributes
      attrs = @options.except(:class, :variant, :size, :icon, :dismissible, :href)
      attrs.merge!(test_selector("badge-#{@variant}"))
      attrs[:data] ||= {}
      attrs[:data][:controller] = "badge" if @dismissible
      attrs
    end

    def link_attributes
      attrs = @options.except(:class, :variant, :size, :icon, :dismissible)
      attrs.merge!(test_selector("badge-link-#{@variant}"))
      attrs
    end
  end
end
