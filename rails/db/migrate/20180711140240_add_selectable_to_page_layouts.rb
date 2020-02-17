class AddSelectableToPageLayouts < ActiveRecord::Migration[5.1]
  def change
    add_column :page_layouts, :selectable, :boolean, null: false, default: true
  end
end
