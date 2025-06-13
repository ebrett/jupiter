# frozen_string_literal: true

class Catalyst::TableComponent < Catalyst::BaseComponent
  renders_many :columns, Catalyst::TableColumnComponent

  def initialize(
    data: [],
    sortable: false,
    sort_column: nil,
    sort_direction: :asc,
    striped: false,
    hover: true,
    compact: false,
    **attrs
  )
    @data = data
    @sortable = sortable
    @sort_column = sort_column
    @sort_direction = sort_direction
    @striped = striped
    @hover = hover
    @compact = compact
    @attrs = attrs
  end

  private

  attr_reader :data, :sortable, :sort_column, :sort_direction, :striped, :hover, :compact, :attrs

  def table_classes
    class_names(
      "min-w-full",
      "divide-y divide-gray-200",
      striped_classes,
      compact_classes,
      attrs[:class]
    )
  end

  def table_wrapper_classes
    class_names(
      "overflow-x-auto",
      "shadow ring-1 ring-black ring-opacity-5",
      "rounded-lg"
    )
  end

  def thead_classes
    "bg-gray-50"
  end

  def tbody_classes
    class_names(
      "bg-white",
      "divide-y divide-gray-200",
      hover_classes
    )
  end

  def th_classes(column)
    class_names(
      "px-6 py-3",
      "text-left text-xs font-medium text-gray-500 uppercase tracking-wider",
      compact ? "px-4 py-2" : "px-6 py-3",
      sortable_th_classes(column)
    )
  end

  def td_classes
    class_names(
      "whitespace-nowrap text-sm text-gray-900",
      compact ? "px-4 py-2" : "px-6 py-4"
    )
  end

  def striped_classes
    striped ? "divide-y divide-gray-200" : ""
  end

  def compact_classes
    compact ? "text-sm" : ""
  end

  def hover_classes
    hover ? "hover:bg-gray-50" : ""
  end

  def sortable_th_classes(column)
    return "" unless sortable && column.sortable

    "cursor-pointer hover:bg-gray-100 select-none"
  end

  def sort_indicator(column)
    return "" unless sortable && column.sortable && sort_column == column.key

    case sort_direction
    when :asc
      svg_icon("chevron-up", class: "ml-1 w-4 h-4 inline")
    when :desc
      svg_icon("chevron-down", class: "ml-1 w-4 h-4 inline")
    else
      ""
    end
  end

  def render_cell_content(column, row)
    if column.block
      capture { column.block.call(row) }
    elsif column.key
      value = row.respond_to?(column.key) ? row.public_send(column.key) : row[column.key]
      format_cell_value(value, column.format)
    else
      ""
    end
  end

  def format_cell_value(value, format)
    case format
    when :currency
      value ? number_to_currency(value) : ""
    when :date
      value&.strftime("%m/%d/%Y")
    when :datetime
      value&.strftime("%m/%d/%Y %I:%M %p")
    when :boolean
      value ? "Yes" : "No"
    when :truncate
      value.present? ? truncate(value.to_s, length: 50) : ""
    else
      value.to_s
    end
  rescue StandardError
    value.to_s
  end

  def sort_params(column)
    return {} unless sortable && column.sortable

    new_direction = (sort_column == column.key && sort_direction == :asc) ? :desc : :asc
    { sort: column.key, direction: new_direction }
  end

  def svg_icon(name, **options)
    case name
    when "chevron-up"
      content_tag :svg, options.merge(fill: "none", viewBox: "0 0 24 24", "stroke-width": "1.5", stroke: "currentColor") do
        content_tag :path, "", "stroke-linecap": "round", "stroke-linejoin": "round", d: "m4.5 15.75 7.5-7.5 7.5 7.5"
      end
    when "chevron-down"
      content_tag :svg, options.merge(fill: "none", viewBox: "0 0 24 24", "stroke-width": "1.5", stroke: "currentColor") do
        content_tag :path, "", "stroke-linecap": "round", "stroke-linejoin": "round", d: "m19.5 8.25-7.5 7.5-7.5-7.5"
      end
    else
      ""
    end
  end
end
