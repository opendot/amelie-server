class AddSelectionOptionsToCards < ActiveRecord::Migration[5.1]
  def change
    add_column :cards, :selection_action, :integer, default: 0
    add_column :cards, :selection_sound, :string
  end
end
