# frozen_string_literal: true

require "view_component/test_helpers"

module ViewComponentTestHelpers
  extend ActiveSupport::Concern

  included do
    include ViewComponent::TestHelpers
    include ActionView::Helpers::TagHelper
    include ActionView::Context
  end

  # Helper to render a component and parse the HTML
  def render_component(component)
    render_inline(component)
    Capybara.string(rendered_content)
  end

  # Helper to find elements with test selectors
  def find_test_selector(selector)
    page.find("[data-test='#{selector}']")
  end

  # Helper to assert presence of CSS classes
  def assert_css_classes(element, *classes)
    classes.flatten.each do |css_class|
      expect(element[:class]).to include(css_class)
    end
  end

  # Helper to assert absence of CSS classes
  def refute_css_classes(element, *classes)
    classes.flatten.each do |css_class|
      expect(element[:class]).not_to include(css_class)
    end
  end

  # Helper to assert ARIA attributes
  def assert_aria_attributes(element, attributes = {})
    attributes.each do |attr, value|
      expect(element[:"aria-#{attr}"]).to eq(value.to_s)
    end
  end

  # Helper to assert data attributes
  def assert_data_attributes(element, attributes = {})
    attributes.each do |attr, value|
      expect(element[:"data-#{attr}"]).to eq(value.to_s)
    end
  end
end

RSpec.configure do |config|
  config.include ViewComponentTestHelpers, type: :component
end
