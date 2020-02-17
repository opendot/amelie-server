class AddUserIdToTrees < ActiveRecord::Migration[5.1]
  def change
    add_column :trees, :user_id, :string
  end
end
