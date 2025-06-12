# frozen_string_literal: true

class Catalyst::CardComponent < Catalyst::BaseComponent
  renders_one :header
  renders_one :footer

  def initialize(
    variant: :default,
    padding: :default,
    shadow: :default,
    hover: false,
    clickable: false,
    href: nil,
    **attrs
  )
    @variant = variant
    @padding = padding
    @shadow = shadow
    @hover = hover
    @clickable = clickable
    @href = href
    @attrs = attrs
  end

  private

  attr_reader :variant, :padding, :shadow, :hover, :clickable, :href, :attrs

  def card_classes
    class_names(
      "bg-white rounded-lg",
      variant_classes,
      padding_classes,
      shadow_classes,
      interactive_classes,
      attrs[:class]
    )
  end

  def variant_classes
    case variant
    when :outlined
      "border border-gray-200"
    when :elevated
      "border-0"
    when :ghost
      "bg-transparent shadow-none border-0"
    else # :default
      "border border-gray-200"
    end
  end

  def padding_classes
    case padding
    when :none
      "p-0"
    when :sm
      "p-4"
    when :lg
      "p-8"
    when :xl
      "p-12"
    else # :default
      "p-6"
    end
  end

  def shadow_classes
    return "" if variant == :ghost

    case shadow
    when :none
      "shadow-none"
    when :sm
      "shadow-sm"
    when :lg
      "shadow-lg"
    when :xl
      "shadow-xl"
    else # :default
      "shadow"
    end
  end

  def interactive_classes
    classes = []

    if hover
      classes << "transition-shadow duration-200 hover:shadow-lg"
    end

    if clickable || href.present?
      classes << "cursor-pointer hover:shadow-lg transition-all duration-200"
    end

    classes.join(" ")
  end

  def header_classes
    case padding
    when :none
      "px-6 py-4 border-b border-gray-200"
    when :sm
      "px-4 py-3 border-b border-gray-200"
    when :lg
      "px-8 py-6 border-b border-gray-200"
    when :xl
      "px-12 py-8 border-b border-gray-200"
    else # :default
      "px-6 py-4 border-b border-gray-200"
    end
  end

  def body_classes
    case padding
    when :none
      "p-0"
    when :sm
      "p-4"
    when :lg
      "p-8"
    when :xl
      "p-12"
    else # :default
      "p-6"
    end
  end

  def footer_classes
    case padding
    when :none
      "px-6 py-4 border-t border-gray-200 bg-gray-50"
    when :sm
      "px-4 py-3 border-t border-gray-200 bg-gray-50"
    when :lg
      "px-8 py-6 border-t border-gray-200 bg-gray-50"
    when :xl
      "px-12 py-8 border-t border-gray-200 bg-gray-50"
    else # :default
      "px-6 py-4 border-t border-gray-200 bg-gray-50"
    end
  end

  def card_tag
    href.present? ? :a : :div
  end

  def card_attributes
    base_attrs = {
      class: card_classes,
      data: { test: "card" }
    }

    if href.present?
      base_attrs[:href] = href
    end

    if clickable && href.blank?
      base_attrs[:role] = "button"
      base_attrs[:tabindex] = "0"
    end

    # Merge custom attributes, handling data attributes specially
    merged_attrs = base_attrs.merge(attrs.except(:class, :data))

    # Merge data attributes separately to preserve the test attribute
    if attrs[:data]
      merged_attrs[:data] = base_attrs[:data].merge(attrs[:data])
    end

    merged_attrs
  end
end
