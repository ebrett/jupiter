# frozen_string_literal: true

module Catalyst
  class DropdownButtonComponent < ViewComponent::Base
    attr_reader :variant, :size, :additional_classes

    def initialize(variant: :primary, size: :md, class: nil, **html_options)
      @variant = variant
      @size = size
      @additional_classes = binding.local_variable_get(:class)
      @html_options = html_options
    end

    def call
      content_tag(:button, **button_options) do
        safe_join([
          content,
          chevron_icon
        ])
      end
    end

    private

    def button_options
      {
        type: "button",
        data: {
          action: "dropdown#toggle",
          dropdown_target: "button"
        },
        class: class_names(
          base_classes,
          variant_classes,
          size_classes,
          "inline-flex items-center justify-center gap-2",
          additional_classes
        )
      }.merge(@html_options)
    end

    def base_classes
      [
        "relative isolate inline-flex items-center justify-center gap-x-2 rounded-lg border text-base/6 font-semibold",
        "focus:outline-none data-[focus]:outline data-[focus]:outline-2 data-[focus]:outline-offset-2",
        "data-[disabled]:opacity-50 data-[disabled]:cursor-not-allowed"
      ]
    end

    def variant_classes
      case variant.to_sym
      when :primary
        [
          "px-[calc(theme(spacing[3.5])-1px)] py-[calc(theme(spacing[2.5])-1px)] sm:px-[calc(theme(spacing.3)-1px)] sm:py-[calc(theme(spacing[1.5])-1px)] sm:text-sm/6",
          "border-transparent bg-zinc-950 text-white data-[hover]:bg-zinc-800 data-[focus]:outline-zinc-950"
        ]
      when :secondary
        [
          "px-[calc(theme(spacing[3.5])-1px)] py-[calc(theme(spacing[2.5])-1px)] sm:px-[calc(theme(spacing.3)-1px)] sm:py-[calc(theme(spacing[1.5])-1px)] sm:text-sm/6",
          "border-zinc-950/10 text-zinc-950 data-[hover]:bg-zinc-950/[2.5%] data-[focus]:outline-zinc-950"
        ]
      when :outline
        [
          "px-[calc(theme(spacing[3.5])-1px)] py-[calc(theme(spacing[2.5])-1px)] sm:px-[calc(theme(spacing.3)-1px)] sm:py-[calc(theme(spacing[1.5])-1px)] sm:text-sm/6",
          "border-zinc-950/20 text-zinc-950 data-[hover]:bg-zinc-950/[2.5%] data-[focus]:outline-zinc-950"
        ]
      when :ghost
        [
          "px-[calc(theme(spacing[3.5])-1px)] py-[calc(theme(spacing[2.5])-1px)] sm:px-[calc(theme(spacing.3)-1px)] sm:py-[calc(theme(spacing[1.5])-1px)] sm:text-sm/6",
          "border-transparent text-zinc-950 data-[hover]:bg-zinc-950/5 data-[focus]:outline-zinc-950"
        ]
      end
    end

    def size_classes
      case size.to_sym
      when :xs
        "px-2 py-1 text-xs gap-1"
      when :sm
        "px-2.5 py-1.5 text-sm gap-1.5"
      when :md
        ""  # Default styling is medium
      when :lg
        "px-4 py-3 text-lg gap-2.5"
      when :xl
        "px-5 py-4 text-xl gap-3"
      end
    end

    def chevron_icon
      content_tag(:svg, class: "size-4 fill-current", viewBox: "0 0 16 16", fill: "currentColor") do
        content_tag(:path, "", fill_rule: "evenodd", d: "M5.22 10.22a.75.75 0 0 1 1.06 0L8 11.94l1.72-1.72a.75.75 0 1 1 1.06 1.06l-2.25 2.25a.75.75 0 0 1-1.06 0l-2.25-2.25a.75.75 0 0 1 0-1.06Z", clip_rule: "evenodd")
      end
    end
  end
end
