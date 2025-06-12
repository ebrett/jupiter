# frozen_string_literal: true

module Catalyst
  class DropdownDividerComponent < ViewComponent::Base
    attr_reader :additional_classes

    def initialize(class: nil, **html_options)
      @additional_classes = binding.local_variable_get(:class)
      @html_options = html_options
    end

    def call
      content_tag(:div, **divider_options)
    end

    private

    def divider_options
      {
        class: class_names(
          "mx-3.5 my-1 h-px border-0 bg-zinc-950/5 sm:mx-3",
          additional_classes
        )
      }.merge(@html_options)
    end
  end
end
