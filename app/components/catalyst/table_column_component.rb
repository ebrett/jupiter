# frozen_string_literal: true

class Catalyst::TableColumnComponent < ViewComponent::Base
  def initialize(
    key: nil,
    label: nil,
    sortable: false,
    format: nil,
    width: nil,
    align: :left,
    &block
  )
    @key = key
    @label = label || key&.to_s&.humanize
    @sortable = sortable
    @format = format
    @width = width
    @align = align
    @block = block
  end

  attr_reader :key, :label, :sortable, :format, :width, :align, :block

  def th_style
    return "" unless width

    "width: #{width};"
  end

  def th_align_class
    case align
    when :center
      "text-center"
    when :right
      "text-right"
    else
      "text-left"
    end
  end

  def td_align_class
    case align
    when :center
      "text-center"
    when :right
      "text-right"
    else
      "text-left"
    end
  end
end
