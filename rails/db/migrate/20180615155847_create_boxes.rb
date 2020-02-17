class CreateBoxes < ActiveRecord::Migration[5.1]
  def change
    create_table :boxes do |t|
      t.string :name
      t.integer :level_id

      t.timestamps
    end
  end
end
