class CreateUserTrees < ActiveRecord::Migration[5.1]
  def change
    create_table :user_trees, id: :string do |t|
      t.string :user_id
      t.string :tree_id
      t.boolean :favourite
      t.timestamps
    end
  end
end
