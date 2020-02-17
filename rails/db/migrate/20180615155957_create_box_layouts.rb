class CreateBoxLayouts < ActiveRecord::Migration[5.1]
  def change
    create_table :box_layouts do |t|
      t.string :box_id
      t.integer :target_id
      t.integer :position

      t.timestamps
    end
  end
end
