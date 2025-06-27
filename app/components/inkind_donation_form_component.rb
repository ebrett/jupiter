class InkindDonationFormComponent < ViewComponent::Base
  def initialize(inkind_request:, expense_categories:)
    @inkind_request = inkind_request
    @expense_categories = expense_categories
  end

  private

  attr_reader :inkind_request, :expense_categories

  def form_data
    @form_data ||= inkind_request.form_data || {}
  end

  def donation_type_options
    InkindRequest::DONATION_TYPES.map { |type| [ type, type ] }
  end

  def input_classes
    "mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
  end

  def error_classes
    "mt-1 block w-full rounded-md border-red-300 text-red-900 placeholder-red-300 shadow-sm focus:border-red-500 focus:ring-red-500"
  end

  def label_classes
    "block text-sm font-medium text-gray-700"
  end

  def error_message_classes
    "mt-1 text-sm text-red-600"
  end

  def required_asterisk
    content_tag(:span, "*", class: "text-red-500")
  end

  def field_error(field_name)
    errors = inkind_request.errors[:form_data]
    return nil if errors.blank?

    error_message = errors.find { |error| error.include?(field_name.to_s.humanize) }
    return nil unless error_message

    content_tag(:p, error_message, class: error_message_classes)
  end

  def field_has_error?(field_name)
    errors = inkind_request.errors[:form_data]
    return false if errors.blank?

    errors.any? { |error| error.include?(field_name.to_s.humanize) }
  end

  def input_class_for_field(field_name)
    field_has_error?(field_name) ? error_classes : input_classes
  end
end
