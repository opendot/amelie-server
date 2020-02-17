class CreateAvailableExerciseTrees < ActiveRecord::Migration[5.1]
  def change
    create_table :available_exercise_trees do |t|
      t.string :exercise_tree_id
      t.string :patient_id
      t.integer :status, :null => false, :default => 0

      t.integer :conclusions_count
      t.integer :consecutive_conclusions_required

      t.timestamps
    end
  end
end
