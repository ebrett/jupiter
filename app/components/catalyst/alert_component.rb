# frozen_string_literal: true

module Catalyst
  class AlertComponent < BaseComponent
    attr_reader :title, :message, :variant, :dismissible, :icon, :actions

    VARIANTS = {
      success: {
        container: "bg-green-50 border-green-200",
        icon: "text-green-400",
        title: "text-green-800",
        message: "text-green-700",
        button: "text-green-500 hover:text-green-600 focus:ring-green-600",
        action_primary: "bg-green-600 hover:bg-green-700 text-white",
        action_secondary: "bg-green-50 text-green-700 hover:bg-green-100"
      },
      error: {
        container: "bg-red-50 border-red-200",
        icon: "text-red-400",
        title: "text-red-800",
        message: "text-red-700",
        button: "text-red-500 hover:text-red-600 focus:ring-red-600",
        action_primary: "bg-red-600 hover:bg-red-700 text-white",
        action_secondary: "bg-red-50 text-red-700 hover:bg-red-100"
      },
      warning: {
        container: "bg-yellow-50 border-yellow-200",
        icon: "text-yellow-400",
        title: "text-yellow-800",
        message: "text-yellow-700",
        button: "text-yellow-500 hover:text-yellow-600 focus:ring-yellow-600",
        action_primary: "bg-yellow-600 hover:bg-yellow-700 text-white",
        action_secondary: "bg-yellow-50 text-yellow-700 hover:bg-yellow-100"
      },
      info: {
        container: "bg-blue-50 border-blue-200",
        icon: "text-blue-400",
        title: "text-blue-800",
        message: "text-blue-700",
        button: "text-blue-500 hover:text-blue-600 focus:ring-blue-600",
        action_primary: "bg-blue-600 hover:bg-blue-700 text-white",
        action_secondary: "bg-blue-50 text-blue-700 hover:bg-blue-100"
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
      @actions = actions || []
      @attrs = attrs

      raise ArgumentError, "Invalid variant: #{variant}" unless VARIANTS.key?(@variant)

      super(**attrs)
    end

    private

    def alert_classes
      class_names(
        "rounded-md border p-4 mb-6",
        variant_classes[:container],
        @attrs[:class]
      )
    end

    def alert_attributes
      attrs = @attrs.except(:class)
      attrs.merge!(test_selector("alert-#{variant}"))
      attrs[:"data-controller"] = "alert" if dismissible
      attrs[:role] = "alert"
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
        "text-sm",
        variant_classes[:message]
      )
    end

    def actions_container_classes
      "mt-4 flex space-x-3"
    end

    def action_classes(style = :primary)
      base_classes = "inline-flex items-center px-3 py-1.5 text-sm font-medium rounded-md focus:outline-none focus:ring-2 focus:ring-offset-2"

      case style.to_sym
      when :primary
        class_names(base_classes, variant_classes[:action_primary])
      when :secondary
        class_names(base_classes, variant_classes[:action_secondary])
      else
        class_names(base_classes, variant_classes[:action_secondary])
      end
    end

    def dismiss_button_classes
      class_names(
        "inline-flex rounded-md p-1.5 focus:outline-none focus:ring-2 focus:ring-offset-2",
        variant_classes[:button]
      )
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

    def should_show_actions?
      actions.present? && actions.any?
    end
  end
end
