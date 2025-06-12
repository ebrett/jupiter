# frozen_string_literal: true

class Catalyst::BreadcrumbItemComponent < ViewComponent::Base
  def initialize(
    label:,
    href: nil,
    current: false,
    icon: nil,
    **attrs
  )
    @label = label
    @href = href
    @current = current
    @icon = icon
    @attrs = attrs
  end

  attr_reader :label, :href, :current, :icon, :attrs

  def item_classes
    class_names(
      "flex items-center",
      current ? current_classes : link_classes,
      attrs[:class]
    )
  end

  def current_classes
    "text-gray-500 font-medium cursor-default"
  end

  def link_classes
    "text-gray-700 hover:text-gray-900 transition-colors duration-200"
  end

  def icon_classes
    "mr-2 h-4 w-4"
  end

  def render_icon
    return unless icon

    case icon
    when :home
      home_icon
    when :folder
      folder_icon
    when :document
      document_icon
    else
      icon.to_s
    end
  end

  def home_icon
    content_tag :svg, class: icon_classes, fill: "none", viewBox: "0 0 24 24", "stroke-width": "1.5", stroke: "currentColor" do
      content_tag :path, "", "stroke-linecap": "round", "stroke-linejoin": "round", d: "m2.25 12 8.954-8.955c.44-.439 1.152-.439 1.591 0L21.75 12M4.5 9.75v10.125c0 .621.504 1.125 1.125 1.125H9.75v-4.875c0-.621.504-1.125 1.125-1.125h2.25c.621 0 1.125.504 1.125 1.125V21h4.125c.621 0 1.125-.504 1.125-1.125V9.75M8.25 21h8.25"
    end
  end

  def folder_icon
    content_tag :svg, class: icon_classes, fill: "none", viewBox: "0 0 24 24", "stroke-width": "1.5", stroke: "currentColor" do
      content_tag :path, "", "stroke-linecap": "round", "stroke-linejoin": "round", d: "M2.25 12.75V12A2.25 2.25 0 0 1 4.5 9.75h15A2.25 2.25 0 0 1 21.75 12v.75m-8.69-6.44-2.12-2.12a1.5 1.5 0 0 0-1.061-.44H4.5A2.25 2.25 0 0 0 2.25 6v12a2.25 2.25 0 0 0 2.25 2.25h15A2.25 2.25 0 0 0 21.75 18V9a2.25 2.25 0 0 0-2.25-2.25H11.69Z"
    end
  end

  def document_icon
    content_tag :svg, class: icon_classes, fill: "none", viewBox: "0 0 24 24", "stroke-width": "1.5", stroke: "currentColor" do
      content_tag :path, "", "stroke-linecap": "round", "stroke-linejoin": "round", d: "M19.5 14.25v-2.625a3.375 3.375 0 0 0-3.375-3.375h-1.5A1.125 1.125 0 0 1 13.5 7.125v-1.5a3.375 3.375 0 0 0-3.375-3.375H8.25m2.25 0H5.625c-.621 0-1.125.504-1.125 1.125v17.25c0 .621.504 1.125 1.125 1.125h12.75c.621 0 1.125-.504 1.125-1.125V11.25a9 9 0 0 0-9-9Z"
    end
  end
end
