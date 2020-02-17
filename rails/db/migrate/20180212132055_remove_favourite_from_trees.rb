class RemoveFavouriteFromTrees < ActiveRecord::Migration[5.1]
  def change
    remove_column :trees, :favourite
  end
end
