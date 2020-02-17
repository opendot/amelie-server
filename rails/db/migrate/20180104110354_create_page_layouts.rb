class CreatePageLayouts < ActiveRecord::Migration[5.1]
  def change
    create_table :page_layouts, id: :string do |t|
      t.string :page_id, index: true
      t.string :card_id
      t.float :x_pos
      t.float :y_pos
      t.float :scale
      t.string :next_page_id
      t.boolean :hidden_link, null: false, default: false

      t.timestamps
    end
  end
end
