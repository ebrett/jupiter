class CreateExpenseCategories < ActiveRecord::Migration[8.0]
  def change
    create_table :expense_categories do |t|
      t.string :code, null: false
      t.string :name, null: false
      t.references :parent, foreign_key: { to_table: :expense_categories }
      t.string :qb_account_id
      t.boolean :active, default: true

      t.timestamps
    end
    add_index :expense_categories, :code, unique: true
  end
end
