class AddForceCompletedToAvailableExerciseTree < ActiveRecord::Migration[5.1]
  def change
    add_column :available_exercise_trees, :force_completed, :boolean, null: false, default: false
  end
end
