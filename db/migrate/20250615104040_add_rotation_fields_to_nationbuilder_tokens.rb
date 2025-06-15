class AddRotationFieldsToNationbuilderTokens < ActiveRecord::Migration[8.0]
  def change
    add_column :nationbuilder_tokens, :rotated_at, :datetime
    add_column :nationbuilder_tokens, :version, :integer
  end
end
