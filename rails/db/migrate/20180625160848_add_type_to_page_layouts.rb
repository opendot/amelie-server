class AddTypeToPageLayouts < ActiveRecord::Migration[5.1]
  def change
    add_column :page_layouts, :type, :string
    add_column :page_layouts, :correct, :boolean
  end
end
