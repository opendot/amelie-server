class ChangeAncestryToTextInPages < ActiveRecord::Migration[5.1]
  def up
    remove_index :pages, :ancestry
    change_column :pages, :ancestry, :text
  end

  def down
    change_column :pages, :ancestry, :string
    add_index :pages, :ancestry
  end
end
