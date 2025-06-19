class ExpenseCategory < ApplicationRecord
  belongs_to :parent, class_name: "ExpenseCategory", optional: true
  has_many :children, class_name: "ExpenseCategory", foreign_key: "parent_id"

  validates :code, presence: true, uniqueness: true
  validates :name, presence: true

  scope :active, -> { where(active: true) }
  scope :top_level, -> { where(parent_id: nil) }
  scope :ordered, -> { order(:name) }

  def full_name
    return name unless parent
    "#{parent.name} - #{name}"
  end

  def self.options_for_select
    active.ordered.map { |category| [ category.full_name, category.code ] }
  end
end
