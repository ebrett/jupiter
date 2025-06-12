# frozen_string_literal: true

module Catalyst
  class DropdownComponent < ViewComponent::Base
    attr_reader :anchor, :additional_classes

    def initialize(anchor: "bottom", class: nil, **html_options)
      @anchor = anchor
      @additional_classes = binding.local_variable_get(:class)
      @html_options = html_options
    end

    def call
      content_tag(:div, **dropdown_options) do
        content
      end
    end

    private

    def dropdown_options
      {
        data: {
          controller: "dropdown",
          action: "click@window->dropdown#closeOnClickOutside keydown.esc@window->dropdown#close keydown->dropdown#keydown"
        },
        class: class_names(
          "relative inline-block",
          additional_classes
        )
      }.merge(@html_options)
    end
  end
end
