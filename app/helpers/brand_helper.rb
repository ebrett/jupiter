# app/helpers/brand_helper.rb

module BrandHelper
    # Logo rendering helper
    def logo(variant: :primary, size: :medium, white_knockout: false, css_classes: "")
      logo_classes = build_logo_classes(variant, size, white_knockout, css_classes)

      case variant
      when :primary, :horizontal
        render_primary_logo(logo_classes, white_knockout)
      when :stacked
        render_stacked_logo(logo_classes, white_knockout)
      when :wordmark
        render_wordmark_logo(logo_classes, white_knockout)
      when :social_profile
        render_social_profile_logo(logo_classes, white_knockout)
      else
        render_primary_logo(logo_classes, white_knockout)
      end
    end

    # Caucus logo helper
    def caucus_logo(caucus_name, variant: :primary, size: :medium, css_classes: "")
      caucus_color = caucus_color_class(caucus_name)
      logo_classes = "#{build_logo_classes(variant, size, false, css_classes)} #{caucus_color}"

      content_tag :div, class: logo_classes do
        # Render caucus-specific logo with appropriate color
        render_caucus_logo_content(caucus_name)
      end
    end

    # Brand color helpers
    def primary_colors
      {
        navy: "#1F1646",
        blue_dark: "#003087",
        blue: "#00A9E0",
        blue_light: "#9EADE5",
        red: "#B2292E",
        gray: "#AFB5BF"
      }
    end

    def accent_colors
      {
        yellow: "#FFE16A",
        cream: "#EDD9BE",
        green: "#8AD594",
        coral: "#FF787E",
        purple: "#9271B2",
        sky: "#B9DEFF"
      }
    end

    # Typography helpers
    def heading(text, level: 1, style: :overpass, css_classes: "")
      font_class = case style
      when :overpass then "font-overpass"
      when :oswald then "font-oswald"
      when :open_sans then "font-open-sans"
      else "font-overpass"
      end

      base_classes = "#{font_class} text-da-navy font-bold #{css_classes}"

      content_tag "h#{level}", text, class: base_classes
    end

    def body_text(text, css_classes: "")
      content_tag :p, text, class: "font-overpass text-da-navy #{css_classes}"
    end

    # Button helpers with DA branding
    def button(text, url = "#", variant: :primary, size: :medium, css_classes: "")
      button_classes = build_button_classes(variant, size, css_classes)

      link_to text, url, class: button_classes
    end

    # Card/container helpers
    def card(css_classes: "", &block)
      content_tag :div,
                  class: "bg-white rounded-lg shadow-md p-6 border-l-4 border-da-blue #{css_classes}",
                  &block
    end

    def hero_section(css_classes: "", &block)
      content_tag :section,
                  class: "bg-da-gradient text-white py-16 #{css_classes}",
                  &block
    end

    # Navigation helpers
    def nav_link(text, url, current: false, css_classes: "")
      link_classes = if current
                      "text-da-blue font-semibold border-b-2 border-da-blue #{css_classes}"
      else
                      "text-da-navy hover:text-da-blue transition-colors #{css_classes}"
      end

      link_to text, url, class: "font-overpass #{link_classes}"
    end

    private

    def build_logo_classes(variant, size, white_knockout, additional_classes)
      size_class = case size
      when :small then "h-8"
      when :medium then "h-12"
      when :large then "h-16"
      when :xlarge then "h-24"
      else "h-12"
      end

      color_class = white_knockout ? "text-white" : "text-da-navy"
      spacing_class = "p-logo-clear"

      "#{size_class} #{color_class} #{spacing_class} #{additional_classes}".strip
    end

    def render_primary_logo(classes, white_knockout)
      # This would render the actual logo SVG or image
      # For now, returning a placeholder structure
      content_tag :div, class: classes do
        content_tag :div, "DEMOCRATS ABROAD", class: "font-bold text-lg"
      end
    end

    def render_stacked_logo(classes, white_knockout)
      content_tag :div, class: "#{classes} flex flex-col items-center" do
        content_tag :div, "DEMOCRATS", class: "font-bold" +
        content_tag(:div, "ABROAD", class: "font-bold")
      end
    end

    def render_wordmark_logo(classes, white_knockout)
      content_tag :div, "DEMOCRATS ABROAD", class: "#{classes} font-bold"
    end

    def render_social_profile_logo(classes, white_knockout)
      # Circular version for social media profiles
      content_tag :div, class: "#{classes} rounded-full border-2 border-da-navy flex items-center justify-center" do
        content_tag :span, "DA", class: "font-bold text-xs"
      end
    end

    def caucus_color_class(caucus_name)
      case caucus_name.to_s.downcase
      when "womens", "women" then "text-caucus-womens"
      when "black" then "text-caucus-black"
      when "disability" then "text-caucus-disability"
      when "hispanic", "latino" then "text-caucus-hispanic"
      when "youth" then "text-caucus-youth"
      when "environment", "climate" then "text-caucus-environment"
      when "aapi", "asian" then "text-caucus-aapi"
      when "veterans", "military" then "text-caucus-veterans"
      when "seniors" then "text-caucus-seniors"
      when "progressive" then "text-caucus-progressive"
      when "lgbtq" then "text-caucus-lgbtq-red" # Default to red from rainbow
      else "text-da-navy"
      end
    end

    def build_button_classes(variant, size, additional_classes)
      base_classes = "inline-flex items-center justify-center font-overpass font-semibold rounded-md transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2"

      variant_classes = case variant
      when :primary
                         "bg-da-blue text-white hover:bg-da-blue-dark focus:ring-da-blue"
      when :secondary
                         "bg-da-red text-white hover:bg-red-700 focus:ring-da-red"
      when :outline
                         "border-2 border-da-blue text-da-blue hover:bg-da-blue hover:text-white focus:ring-da-blue"
      else
                         "bg-da-blue text-white hover:bg-da-blue-dark focus:ring-da-blue"
      end

      size_classes = case size
      when :small then "px-3 py-1.5 text-sm"
      when :medium then "px-4 py-2 text-base"
      when :large then "px-6 py-3 text-lg"
      else "px-4 py-2 text-base"
      end

      "#{base_classes} #{variant_classes} #{size_classes} #{additional_classes}".strip
    end
end
