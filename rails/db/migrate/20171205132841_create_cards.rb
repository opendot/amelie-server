class CreateCards < ActiveRecord::Migration[5.1]
  def change
    create_table :cards, id: :string do |t|
      t.string :label
      t.integer :level
      t.string :type
      t.string :page_id, index: true
      t.float :x_pos
      t.float :y_pos
      t.float :scale
      t.string :content_id, index: true
      t.string :patient_id, index: true
      t.string :session_event_id, index: true
      t.string :type
      t.timestamps
    end
  end
end
