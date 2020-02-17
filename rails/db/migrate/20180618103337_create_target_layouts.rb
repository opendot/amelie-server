class CreateTargetLayouts < ActiveRecord::Migration[5.1]
  def change
    create_table :target_layouts do |t|
      t.string :exercise_tree_id
      t.integer :target_id
      t.integer :position

      t.timestamps
    end
  end
end
