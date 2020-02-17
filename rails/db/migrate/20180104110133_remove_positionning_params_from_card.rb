class RemovePositionningParamsFromCard < ActiveRecord::Migration[5.1]
  def change
    remove_column :cards, :x_pos
    remove_column :cards, :y_pos
    remove_column :cards, :scale
    remove_column :cards, :page_id
  end
end
