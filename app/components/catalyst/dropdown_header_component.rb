# frozen_string_literal: true

module Catalyst
  class DropdownHeaderComponent < ViewComponent::Base
    attr_reader :additional_classes

    def initialize(class: nil, **html_options)
      @additional_classes = binding.local_variable_get(:class)
      @html_options = html_options
    end

    def call
      content_tag(:div, **header_options) do
        content
      end
    end

    private

    def header_options
      {
        class: class_names(
          "px-3.5 pt-2.5 pb-1 sm:px-3 text-sm font-medium text-zinc-500",
          additional_classes
        )
      }.merge(@html_options)
    end
  end
end
