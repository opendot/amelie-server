class AddDeletedAtToSynchronizables < ActiveRecord::Migration[5.1]
  def change
    add_column :available_boxes, :deleted_at, :datetime
    add_column :available_exercise_trees, :deleted_at, :datetime
    add_column :available_levels, :deleted_at, :datetime
    add_column :available_targets, :deleted_at, :datetime
    add_column :box_layouts, :deleted_at, :datetime
    add_column :boxes, :deleted_at, :datetime
    add_column :levels, :deleted_at, :datetime
    add_column :target_layouts, :deleted_at, :datetime
    add_column :targets, :deleted_at, :datetime

    add_index :available_boxes, :deleted_at
    add_index :available_exercise_trees, :deleted_at
    add_index :available_levels, :deleted_at
    add_index :available_targets, :deleted_at
    add_index :box_layouts, :deleted_at
    add_index :boxes, :deleted_at
    add_index :levels, :deleted_at
    add_index :target_layouts, :deleted_at
    add_index :targets, :deleted_at
  end
end
