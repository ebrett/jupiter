# frozen_string_literal: true

module Catalyst
  class ModalComponent < BaseComponent
    attr_reader :size, :open, :title, :description, :actions

    SIZES = {
      xs: "sm:max-w-xs",
      sm: "sm:max-w-sm",
      md: "sm:max-w-md",
      lg: "sm:max-w-lg",
      xl: "sm:max-w-xl",
      "2xl": "sm:max-w-2xl",
      "3xl": "sm:max-w-3xl",
      "4xl": "sm:max-w-4xl",
      "5xl": "sm:max-w-5xl"
    }.freeze

    def initialize(
      size: :lg,
      open: false,
      title: nil,
      description: nil,
      actions: nil,
      **attrs
    )
      @size = size.to_s.to_sym
      @open = open
      @title = title
      @description = description
      @actions = actions
      @attrs = attrs

      raise ArgumentError, "Invalid size: #{size}" unless SIZES.key?(@size)

      super(**attrs)
    end

    def call
      content_tag :div, class: backdrop_classes, **backdrop_attributes do
        content_tag :div, class: container_classes do
          content_tag :div, class: grid_classes do
            content_tag :div, class: panel_classes, **panel_attributes do
              safe_join([
                render_header,
                render_body,
                render_actions
              ].compact)
            end
          end
        end
      end
    end

    private

    def render_header
      return unless title.present? || description.present?

      content_tag :div, class: header_classes do
        safe_join([
          render_title,
          render_description
        ].compact)
      end
    end

    def render_title
      return unless title.present?

      content_tag :h2, title, class: title_classes, **title_attributes
    end

    def render_description
      return unless description.present?

      content_tag :p, description, class: description_classes, **description_attributes
    end

    def render_body
      return unless content?

      content_tag :div, class: body_classes do
        content
      end
    end

    def render_actions
      return unless actions.present?

      content_tag :div, class: actions_classes do
        actions
      end
    end

    def backdrop_classes
      class_names(
        "fixed inset-0 flex w-screen justify-center overflow-y-auto",
        "bg-zinc-950/25 px-2 py-2 transition duration-100 focus:outline-0",
        "data-closed:opacity-0 data-enter:ease-out data-leave:ease-in",
        "sm:px-6 sm:py-8 lg:px-8 lg:py-16",
        "dark:bg-zinc-950/50",
        @attrs[:class]
      )
    end

    def backdrop_attributes
      attrs = @attrs.except(:class).merge(
        "data-controller": "catalyst-modal",
        "data-catalyst-modal-open-value": open.to_s,
        "data-action": "click->catalyst-modal#clickBackdrop keydown.escape->catalyst-modal#close"
      )

      attrs.merge!(test_selector("modal"))
      attrs[:style] = "display: none;" unless open
      attrs
    end

    def container_classes
      "fixed inset-0 w-screen overflow-y-auto pt-6 sm:pt-0"
    end

    def grid_classes
      "grid min-h-full grid-rows-[1fr_auto] justify-items-center sm:grid-rows-[1fr_auto_3fr] sm:p-4"
    end

    def panel_classes
      class_names(
        "row-start-2 w-full min-w-0 rounded-t-3xl bg-white shadow-lg",
        "ring-1 ring-zinc-950/10 transition duration-100 will-change-transform",
        "data-closed:translate-y-12 data-closed:opacity-0 data-enter:ease-out data-leave:ease-in",
        "sm:mb-auto sm:rounded-2xl sm:data-closed:translate-y-0 sm:data-closed:data-enter:scale-95",
        "dark:bg-zinc-900 dark:ring-white/10 forced-colors:outline",
        SIZES[@size]
      )
    end

    def panel_attributes
      {
        "data-catalyst-modal-target": "panel",
        "data-action": "click->catalyst-modal#clickPanel"
      }
    end

    def header_classes
      return "p-8 pb-6" unless actions.present?

      "p-8 pb-0"
    end

    def title_classes
      "text-lg/6 font-semibold text-balance text-zinc-950 sm:text-base/6 dark:text-white"
    end

    def title_attributes
      { "data-catalyst-modal-target": "title" }
    end

    def description_classes
      "mt-2 text-pretty text-zinc-600 dark:text-zinc-400"
    end

    def description_attributes
      { "data-catalyst-modal-target": "description" }
    end

    def body_classes
      if title.present? || description.present?
        return "px-8 pb-8" unless actions.present?
        "px-8 pb-0"
      else
        return "p-8" unless actions.present?
        "p-8 pb-0"
      end
    end

    def actions_classes
      "p-8 pt-6 flex flex-col-reverse items-center justify-end gap-3 *:w-full sm:flex-row sm:*:w-auto"
    end
  end
end
