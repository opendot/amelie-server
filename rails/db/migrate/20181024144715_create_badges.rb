class CreateBadges < ActiveRecord::Migration[5.1]
  def change
    create_table :badges, id: :string do |t|
      t.string :patient_id, index: true
      t.datetime :date
      t.integer :achievement
      t.integer :target_id
      t.string :target_name
      t.integer :box_id
      t.string :box_name
      t.integer :level_id
      t.string :level_name
      t.integer :count

      t.timestamps
    end
  end
end
