# frozen_string_literal: true

module Catalyst
  class NotificationComponent < BaseComponent
    attr_reader :title, :message, :variant, :dismissible, :icon, :actions

    VARIANTS = {
      success: {
        container: "bg-green-50 border-green-200",
        icon: "text-green-400",
        title: "text-green-800",
        message: "text-green-700",
        button: "text-green-500 hover:text-green-600 focus:ring-green-600"
      },
      error: {
        container: "bg-red-50 border-red-200",
        icon: "text-red-400",
        title: "text-red-800",
        message: "text-red-700",
        button: "text-red-500 hover:text-red-600 focus:ring-red-600"
      },
      warning: {
        container: "bg-yellow-50 border-yellow-200",
        icon: "text-yellow-400",
        title: "text-yellow-800",
        message: "text-yellow-700",
        button: "text-yellow-500 hover:text-yellow-600 focus:ring-yellow-600"
      },
      info: {
        container: "bg-blue-50 border-blue-200",
        icon: "text-blue-400",
        title: "text-blue-800",
        message: "text-blue-700",
        button: "text-blue-500 hover:text-blue-600 focus:ring-blue-600"
      }
    }.freeze

    ICONS = {
      success: "M9 12.75L11.25 15 15 9.75M21 12a9 9 0 11-18 0 9 9 0 0118 0z",
      error: "M9.75 9.75l4.5 4.5m0-4.5l-4.5 4.5M21 12a9 9 0 11-18 0 9 9 0 0118 0z",
      warning: "M12 9v3.75m-9.303 3.376c-.866 1.5.217 3.374 1.948 3.374h14.71c1.73 0 2.813-1.874 1.948-3.374L13.949 3.378c-.866-1.5-3.032-1.5-3.898 0L2.697 16.126zM12 15.75h.007v.008H12v-.008z",
      info: "M11.25 11.25l.041-.02a.75.75 0 011.063.852l-.708 2.836a.75.75 0 001.063.853l.041-.021M21 12a9 9 0 11-18 0 9 9 0 0118 0zm-9-3.75h.008v.008H12V8.25z"
    }.freeze

    def initialize(
      title: nil,
      message: nil,
      variant: :info,
      dismissible: false,
      icon: nil,
      actions: nil,
      **attrs
    )
      @title = title
      @message = message
      @variant = variant.to_sym
      @dismissible = dismissible
      @icon = icon
      @actions = actions
      @attrs = attrs

      raise ArgumentError, "Invalid variant: #{variant}" unless VARIANTS.key?(@variant)

      super(**attrs)
    end

    def call
      content_tag :div, class: notification_classes, role: "alert", **notification_attributes do
        render_content
      end
    end

    private

    def render_content
      content_tag :div, class: "flex" do
        safe_join([
          render_icon,
          render_text_content,
          render_actions,
          render_dismiss_button
        ].compact)
      end
    end

    def render_icon
      return unless should_show_icon?

      content_tag :div, class: "flex-shrink-0" do
        content_tag :svg, class: icon_classes, viewbox: "0 0 24 24", fill: "none", stroke: "currentColor", "stroke-width": "1.5" do
          content_tag :path, nil, "stroke-linecap": "round", "stroke-linejoin": "round", d: icon_path
        end
      end
    end

    def render_text_content
      content_tag :div, class: text_content_classes do
        safe_join([
          render_title,
          render_message
        ].compact)
      end
    end

    def render_title
      return unless title.present?

      content_tag :h3, title, class: title_classes
    end

    def render_message
      return unless message.present?

      content_tag :div, class: message_classes do
        if message.is_a?(String)
          content_tag :p, message, class: "text-sm"
        else
          message
        end
      end
    end

    def render_actions
      return unless actions.present?

      content_tag :div, class: actions_classes do
        actions
      end
    end

    def render_dismiss_button
      return unless dismissible

      content_tag :div, class: "ml-auto pl-3" do
        content_tag :div, class: "-mx-1.5 -my-1.5" do
          content_tag :button, type: "button", class: dismiss_button_classes, **dismiss_button_attributes do
            safe_join([
              content_tag(:span, "Dismiss", class: "sr-only"),
              content_tag(:svg, class: "h-5 w-5", viewbox: "0 0 20 20", fill: "currentColor", "aria-hidden": "true") do
                content_tag :path, nil, d: "M6.28 5.22a.75.75 0 00-1.06 1.06L8.94 10l-3.72 3.72a.75.75 0 101.06 1.06L10 11.06l3.72 3.72a.75.75 0 101.06-1.06L11.06 10l3.72-3.72a.75.75 0 00-1.06-1.06L10 8.94 6.28 5.22z"
              end
            ])
          end
        end
      end
    end

    def notification_classes
      class_names(
        "rounded-md border p-4",
        variant_classes[:container],
        @attrs[:class]
      )
    end

    def notification_attributes
      attrs = @attrs.except(:class)
      attrs.merge!(test_selector("notification-#{variant}"))
      attrs[:"data-controller"] = "notification" if dismissible
      attrs
    end

    def icon_classes
      class_names(
        "h-5 w-5",
        variant_classes[:icon]
      )
    end

    def text_content_classes
      class_names(
        should_show_icon? ? "ml-3" : nil,
        "flex-1"
      )
    end

    def title_classes
      class_names(
        "text-sm font-medium",
        variant_classes[:title]
      )
    end

    def message_classes
      class_names(
        title.present? ? "mt-1" : nil,
        variant_classes[:message]
      )
    end

    def actions_classes
      "ml-auto pl-3"
    end

    def dismiss_button_classes
      class_names(
        "inline-flex rounded-md p-1.5 focus:outline-none focus:ring-2 focus:ring-offset-2",
        variant_classes[:button]
      )
    end

    def dismiss_button_attributes
      {
        "data-action": "click->notification#dismiss"
      }
    end

    def variant_classes
      VARIANTS[@variant]
    end

    def should_show_icon?
      icon != false
    end

    def icon_path
      return icon if icon.is_a?(String)

      ICONS[@variant]
    end
  end
end
