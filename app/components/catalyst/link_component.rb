# frozen_string_literal: true

module Catalyst
  class LinkComponent < ViewComponent::Base
    attr_reader :href, :variant, :external, :additional_classes

    def initialize(href:, variant: :default, external: nil, class: nil, **html_options)
      @href = href
      @variant = variant
      @external = external.nil? ? external_link?(href) : external
      @additional_classes = binding.local_variable_get(:class)
      @html_options = html_options
    end

    def call
      link_to(href, **link_options) do
        safe_join([
          content,
          external_icon
        ].compact)
      end
    end

    private

    def link_options
      {
        class: class_names(
          base_classes,
          variant_classes,
          additional_classes
        ),
        target: external ? "_blank" : nil,
        rel: external ? "noopener noreferrer" : nil
      }.merge(@html_options)
    end

    def base_classes
      [
        "transition-colors duration-150",
        "focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 rounded-sm"
      ]
    end

    def variant_classes
      case variant.to_sym
      when :default
        [
          "text-blue-600 hover:text-blue-800 underline decoration-blue-600/30 hover:decoration-blue-800/50",
          "visited:text-purple-600 visited:hover:text-purple-800"
        ]
      when :primary
        [
          "text-blue-600 hover:text-blue-800 font-medium",
          "visited:text-purple-600 visited:hover:text-purple-800"
        ]
      when :secondary
        [
          "text-gray-600 hover:text-gray-800",
          "visited:text-gray-600 visited:hover:text-gray-800"
        ]
      when :muted
        [
          "text-gray-500 hover:text-gray-700 underline decoration-gray-500/30 hover:decoration-gray-700/50",
          "visited:text-gray-500 visited:hover:text-gray-700"
        ]
      when :danger
        [
          "text-red-600 hover:text-red-800",
          "visited:text-red-600 visited:hover:text-red-800"
        ]
      when :plain
        [
          "text-gray-900 hover:text-gray-700 no-underline",
          "visited:text-gray-900 visited:hover:text-gray-700"
        ]
      else
        []
      end
    end

    def external_icon
      return unless external

      content_tag(:svg, class: "inline-block w-3 h-3 ml-1", fill: "currentColor", viewBox: "0 0 20 20") do
        content_tag(:path, "", fill_rule: "evenodd", d: "M4.25 5.5a.75.75 0 00-.75.75v8.5c0 .414.336.75.75.75h8.5a.75.75 0 00.75-.75v-4a.75.75 0 011.5 0v4A2.25 2.25 0 0112.75 17h-8.5A2.25 2.25 0 012 14.75v-8.5A2.25 2.25 0 014.25 4h5a.75.75 0 010 1.5h-5z", clip_rule: "evenodd") +
        content_tag(:path, "", fill_rule: "evenodd", d: "M6.194 12.753a.75.75 0 001.06.053L16.5 4.44v2.81a.75.75 0 001.5 0v-4.5a.75.75 0 00-.75-.75h-4.5a.75.75 0 000 1.5h2.553l-9.056 8.194a.75.75 0 00-.053 1.06z", clip_rule: "evenodd")
      end
    end

    def external_link?(url)
      return false if url.blank?
      return false if url.start_with?("/", "#")
      return false if url.start_with?("mailto:", "tel:")

      begin
        uri = URI.parse(url)
        uri.scheme.present? && !uri.host.nil?
      rescue URI::InvalidURIError
        false
      end
    end
  end
end
