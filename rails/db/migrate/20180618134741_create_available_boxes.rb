class CreateAvailableBoxes < ActiveRecord::Migration[5.1]
  def change
    create_table :available_boxes do |t|
      t.integer :box_id
      t.string :patient_id
      t.integer :status, :null => false, :default => 0
      t.float :progress, :null => false, :default => 0.0

      t.integer :current_target_id
      t.string :current_target_name
      t.integer :current_target_position, :null => false, :default => 0
      t.integer :targets_count, :null => false, :default => 0

      t.string :current_exercise_tree_id
      t.string :current_exercise_tree_name
      t.integer :current_exercise_tree_conclusions_count
      t.integer :current_exercise_tree_consecutive_conclusions_required
      t.integer :target_exercise_tree_position, :null => false, :default => 0
      t.integer :target_exercise_trees_count, :null => false, :default => 0

      t.datetime :last_completed_exercise_tree_at

      t.timestamps
    end
  end
end
