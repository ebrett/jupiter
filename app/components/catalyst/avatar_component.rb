# frozen_string_literal: true

module Catalyst
  class AvatarComponent < BaseComponent
    attr_reader :src, :initials, :alt, :size, :square, :clickable, :href

    SIZES = {
      xs: "size-4",
      sm: "size-6",
      md: "size-8",
      lg: "size-10",
      xl: "size-12",
      "2xl": "size-14"
    }.freeze

    def initialize(
      src: nil,
      initials: nil,
      alt: "",
      size: :md,
      square: false,
      clickable: false,
      href: nil,
      **attrs
    )
      @src = src
      @initials = initials
      @alt = alt
      @size = size.to_sym
      @square = square
      @clickable = clickable || href.present?
      @href = href
      @attrs = attrs

      raise ArgumentError, "Invalid size: #{size}" unless SIZES.key?(@size)

      super(**attrs)
    end

    def call
      if clickable?
        render_clickable_avatar
      else
        render_avatar_container
      end
    end

    private

    def render_clickable_avatar
      if href.present?
        link_to href, class: clickable_classes, **clickable_attributes do
          render_avatar_content
        end
      else
        content_tag :button, type: "button", class: clickable_classes, **clickable_attributes do
          render_avatar_content
        end
      end
    end

    def render_avatar_container
      content_tag :span, class: avatar_classes, **avatar_attributes do
        render_avatar_content
      end
    end

    def render_avatar_content
      safe_join([
        render_initials,
        render_image
      ].compact)
    end

    def render_initials
      return unless should_show_initials?

      content_tag :svg, class: initials_svg_classes, viewbox: "0 0 100 100", **initials_svg_attributes do
        safe_join([
          render_svg_title,
          render_svg_text
        ].compact)
      end
    end

    def render_svg_title
      return unless alt.present?

      content_tag :title, alt
    end

    def render_svg_text
      content_tag :text, processed_initials, **svg_text_attributes
    end

    def render_image
      return unless src.present?

      image_tag src, alt: alt, class: image_classes, **image_attributes
    end

    def avatar_classes
      class_names(
        # Base layout
        "inline-grid shrink-0 align-middle",
        "[--avatar-radius:20%] *:col-start-1 *:row-start-1",
        "outline -outline-offset-1 outline-black/10 dark:outline-white/10",

        # Size
        SIZES[@size],

        # Shape
        square ? "rounded-[--avatar-radius] *:rounded-[--avatar-radius]" : "rounded-full *:rounded-full",

        # Custom classes
        @attrs[:class]
      )
    end

    def clickable_classes
      class_names(
        # Shape
        square ? "rounded-[20%]" : "rounded-full",

        # Interactive states
        "relative inline-grid",
        "focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500",
        "hover:opacity-75 transition-opacity",

        # Custom classes
        @attrs[:class]
      )
    end

    def avatar_attributes
      attrs = @attrs.except(:class)
      attrs.merge!(test_selector("avatar"))
      attrs[:"data-slot"] = "avatar"
      attrs
    end

    def clickable_attributes
      attrs = @attrs.except(:class)
      attrs.merge!(test_selector("avatar-button"))

      unless href.present?
        attrs[:"data-action"] = "click->catalyst-avatar#click" if @attrs[:"data-action"].blank?
      end

      attrs
    end

    def initials_svg_classes
      class_names(
        "size-full fill-current p-[5%]",
        "font-medium uppercase select-none",
        font_size_class
      )
    end

    def initials_svg_attributes
      attrs = {}
      attrs[:"aria-hidden"] = "true" unless alt.present?
      attrs
    end

    def svg_text_attributes
      {
        x: "50%",
        y: "50%",
        "alignment-baseline": "middle",
        "dominant-baseline": "middle",
        "text-anchor": "middle",
        dy: ".125em"
      }
    end

    def image_classes
      "size-full object-cover"
    end

    def image_attributes
      {
        loading: "lazy",
        onError: "this.style.display='none'"
      }
    end

    def font_size_class
      case @size
      when :xs, :sm
        "text-xs"
      when :md
        "text-sm"
      when :lg, :xl
        "text-base"
      when :"2xl"
        "text-lg"
      else
        "text-sm"
      end
    end

    def should_show_initials?
      initials.present?
    end

    def processed_initials
      return "" unless initials.present?

      # Take first 2 characters, uppercase
      initials.strip.upcase[0, 2]
    end

    def clickable?
      @clickable
    end

    # Generate initials from name if not provided
    def self.initials_from_name(name)
      return "" unless name.present?

      words = name.strip.split(/\s+/)
      case words.length
      when 0
        ""
      when 1
        words.first[0, 2].upcase
      else
        "#{words.first[0]}#{words.last[0]}".upcase
      end
    end
  end
end
