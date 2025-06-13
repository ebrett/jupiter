# frozen_string_literal: true

module Catalyst
  class DropdownMenuComponent < ViewComponent::Base
    attr_reader :anchor, :additional_classes

    def initialize(anchor: "bottom", class: nil, **html_options)
      @anchor = anchor
      @additional_classes = binding.local_variable_get(:class)
      @html_options = html_options
    end

    def call
      content_tag(:div, **menu_options) do
        content
      end
    end

    private

    def menu_options
      {
        data: {
          dropdown_target: "menu"
        },
        class: class_names(
          base_classes,
          anchor_classes,
          "hidden", # Hidden by default
          additional_classes
        )
      }.merge(@html_options)
    end

    def base_classes
      [
        "absolute z-50 w-max rounded-xl p-1 min-w-48",
        "bg-white/95 backdrop-blur-xl shadow-lg ring-1 ring-zinc-950/10",
        "outline outline-transparent focus:outline-hidden",
        "overflow-y-auto"
      ]
    end

    def anchor_classes
      case anchor.to_s
      when "top"
        "bottom-full mb-2"
      when "top-start"
        "bottom-full right-0 mb-2"
      when "top-end"
        "bottom-full left-0 mb-2"
      when "bottom"
        "top-full mt-2"
      when "bottom-start"
        "top-full right-0 mt-2"
      when "bottom-end"
        "top-full left-0 mt-2"
      when "left"
        "right-full mr-2 top-0"
      when "right"
        "left-full ml-2 top-0"
      else
        "top-full mt-2" # Default to bottom
      end
    end
  end
end
