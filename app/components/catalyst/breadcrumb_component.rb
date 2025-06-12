# frozen_string_literal: true

class Catalyst::BreadcrumbComponent < Catalyst::BaseComponent
  renders_many :items, Catalyst::BreadcrumbItemComponent

  def initialize(
    separator: :chevron,
    size: :default,
    **attrs
  )
    @separator = separator
    @size = size
    @attrs = attrs
  end

  private

  attr_reader :separator, :size, :attrs

  def breadcrumb_classes
    class_names(
      "flex items-center",
      size_classes,
      attrs[:class]
    )
  end

  def breadcrumb_attributes
    base_attrs = {
      class: breadcrumb_classes,
      "aria-label": "Breadcrumb",
      data: { test: "breadcrumb" }
    }

    # Merge custom attributes, handling data attributes specially
    merged_attrs = base_attrs.merge(attrs.except(:class, :data))

    # Merge data attributes separately to preserve both
    if attrs[:data]
      merged_attrs[:data] = base_attrs[:data].merge(attrs[:data])
    end

    merged_attrs
  end

  def size_classes
    case size
    when :sm
      "text-sm"
    when :lg
      "text-lg"
    else
      "text-base"
    end
  end

  def separator_content
    case separator
    when :chevron
      chevron_right_icon
    when :slash
      "/"
    when :arrow
      arrow_right_icon
    when :dot
      "•"
    when :pipe
      "|"
    else
      separator.to_s
    end
  end

  def chevron_right_icon
    content_tag :svg, class: "h-4 w-4 text-gray-400", fill: "none", viewBox: "0 0 24 24", "stroke-width": "1.5", stroke: "currentColor" do
      content_tag :path, "", "stroke-linecap": "round", "stroke-linejoin": "round", d: "m8.25 4.5 7.5 7.5-7.5 7.5"
    end
  end

  def arrow_right_icon
    content_tag :svg, class: "h-4 w-4 text-gray-400", fill: "none", viewBox: "0 0 24 24", "stroke-width": "1.5", stroke: "currentColor" do
      content_tag :path, "", "stroke-linecap": "round", "stroke-linejoin": "round", d: "M13.5 4.5 21 12l-7.5 7.5M3 12h16.5"
    end
  end

  def separator_classes
    "mx-2 text-gray-400"
  end
end
