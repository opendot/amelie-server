class ChangeAvailablesIdToUuid < ActiveRecord::Migration[5.1]
  def up
    change_column :available_levels, :id, :string
    change_column :available_boxes, :id, :string
    change_column :available_targets, :id, :string
    change_column :available_exercise_trees, :id, :string
  end

  def down
    change_column :available_levels, :id, :integer
    change_column :available_boxes, :id, :integer
    change_column :available_targets, :id, :integer
    change_column :available_exercise_trees, :id, :integer
  end
end
