# frozen_string_literal: true

module Catalyst
  class DividerComponent < ViewComponent::Base
    attr_reader :soft, :additional_classes

    def initialize(soft: false, class: nil, **html_options)
      @soft = soft
      @additional_classes = binding.local_variable_get(:class)
      @html_options = html_options
    end

    def call
      tag(:hr, **divider_options)
    end

    private

    def divider_options
      {
        role: "presentation",
        class: class_names(
          "w-full border-t",
          soft ? "border-zinc-950/5" : "border-zinc-950/10",
          additional_classes
        )
      }.merge(@html_options)
    end
  end
end
