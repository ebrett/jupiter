# frozen_string_literal: true

# TailwindFormBuilder provides consistent Tailwind CSS styling for all form inputs
# while maintaining compatibility with Rails form helpers and error handling.
#
# This eliminates the need to repeat lengthy Tailwind class strings across forms
# and ensures consistent styling throughout the application.
#
# Usage:
#   <%= form_with model: @user, builder: TailwindFormBuilder do |form| %>
#     <%= form.email_field :email %>
#     <%= form.password_field :password %>
#   <% end %>
#
class TailwindFormBuilder < ActionView::Helpers::FormBuilder
  # Base CSS classes for form inputs - extracted from existing DAFA forms
  BASE_INPUT_CLASSES = "appearance-none block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm placeholder-gray-400 focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm"

  # Error state classes that replace the base border/text styling
  ERROR_INPUT_CLASSES = "appearance-none block w-full px-3 py-2 border border-red-300 text-red-900 placeholder-red-300 rounded-md shadow-sm focus:outline-none focus:ring-red-500 focus:border-red-500 sm:text-sm"

  # Label styling
  LABEL_CLASSES = "block text-sm font-medium text-gray-700"

  # Submit button styling
  SUBMIT_BUTTON_CLASSES = "w-full flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:opacity-50 disabled:cursor-not-allowed"

  # Checkbox styling
  CHECKBOX_CLASSES = "h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded"

  # Text input fields
  def email_field(method, options = {})
    options = apply_input_classes(method, options)
    super(method, options)
  end

  def text_field(method, options = {})
    options = apply_input_classes(method, options)
    super(method, options)
  end

  def password_field(method, options = {})
    options = apply_input_classes(method, options)
    super(method, options)
  end

  def number_field(method, options = {})
    options = apply_input_classes(method, options)
    super(method, options)
  end

  def date_field(method, options = {})
    options = apply_input_classes(method, options)
    super(method, options)
  end

  def text_area(method, options = {})
    options = apply_input_classes(method, options)
    super(method, options)
  end

  # Select fields
  def select(method, choices = nil, options = {}, html_options = {})
    html_options = apply_input_classes(method, html_options)
    super(method, choices, options, html_options)
  end

  # Checkbox with custom styling
  def check_box(method, options = {}, checked_value = "1", unchecked_value = "0")
    options = apply_checkbox_classes(options)
    super(method, options, checked_value, unchecked_value)
  end

  # Submit button with consistent styling
  def submit(value = nil, options = {})
    options = apply_submit_classes(options)
    super(value, options)
  end

  # Enhanced label with consistent styling
  def label(method, text = nil, options = {}, &block)
    options = apply_label_classes(options)
    super(method, text, options, &block)
  end

  private

  # Determine appropriate input classes based on validation errors
  def apply_input_classes(method, options)
    options = options.dup

    # Get existing classes and split them
    existing_classes = options[:class].to_s.split

    # Check if the field has validation errors
    base_classes = field_has_error?(method) ? ERROR_INPUT_CLASSES : BASE_INPUT_CLASSES

    # Combine with any additional classes provided
    options[:class] = [ base_classes, existing_classes ].flatten.join(" ").strip

    options
  end

  # Apply checkbox-specific styling
  def apply_checkbox_classes(options)
    options = options.dup
    existing_classes = options[:class].to_s.split
    options[:class] = [ CHECKBOX_CLASSES, existing_classes ].flatten.join(" ").strip
    options
  end

  # Apply submit button styling
  def apply_submit_classes(options)
    options = options.dup
    existing_classes = options[:class].to_s.split
    options[:class] = [ SUBMIT_BUTTON_CLASSES, existing_classes ].flatten.join(" ").strip
    options
  end

  # Apply label styling
  def apply_label_classes(options)
    options = options.dup
    existing_classes = options[:class].to_s.split
    options[:class] = [ LABEL_CLASSES, existing_classes ].flatten.join(" ").strip
    options
  end

  # Check if a field has validation errors
  def field_has_error?(method)
    object&.errors&.include?(method)
  end
end
