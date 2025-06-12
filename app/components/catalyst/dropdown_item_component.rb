# frozen_string_literal: true

module Catalyst
  class DropdownItemComponent < ViewComponent::Base
    attr_reader :href, :disabled, :additional_classes

    def initialize(href: nil, disabled: false, class: nil, **html_options)
      @href = href
      @disabled = disabled
      @additional_classes = binding.local_variable_get(:class)
      @html_options = html_options
    end

    def call
      if href.present?
        link_to(href, **link_options) { content }
      else
        content_tag(:button, **button_options) { content }
      end
    end

    private

    def link_options
      {
        class: class_names(base_classes, additional_classes),
        data: {
          action: "dropdown#selectItem"
        }
      }.merge(@html_options)
    end

    def button_options
      {
        type: "button",
        disabled: disabled,
        class: class_names(base_classes, additional_classes),
        data: {
          action: "dropdown#selectItem"
        }
      }.merge(@html_options)
    end

    def base_classes
      [
        "group cursor-default rounded-lg px-3.5 py-2.5 focus:outline-hidden sm:px-3 sm:py-1.5",
        "text-left text-base/6 text-zinc-950 sm:text-sm/6",
        "hover:bg-blue-500 hover:text-white focus:bg-blue-500 focus:text-white",
        "transition-colors duration-150",
        "grid grid-cols-[auto_1fr_auto] items-center gap-2",
        disabled ? "opacity-50 cursor-not-allowed" : "cursor-pointer",
        "w-full text-left"
      ]
    end
  end
end
