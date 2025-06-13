class AddNationbuilderProfileDataToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :nationbuilder_profile_data, :jsonb
  end
end
