class CreateFeatureFlagAssignments < ActiveRecord::Migration[8.0]
  def change
    create_table :feature_flag_assignments do |t|
      t.references :feature_flag, null: false, foreign_key: true
      t.references :assignable, polymorphic: true, null: false

      t.timestamps
    end

    add_index :feature_flag_assignments, [ :feature_flag_id, :assignable_type, :assignable_id ],
              unique: true, name: 'index_feature_flag_assignments_unique'
    add_index :feature_flag_assignments, [ :assignable_type, :assignable_id ]
  end
end
