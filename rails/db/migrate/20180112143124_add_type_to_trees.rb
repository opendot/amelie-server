class AddTypeToTrees < ActiveRecord::Migration[5.1]
  def change
    add_column :trees, :type, :string
  end
end
