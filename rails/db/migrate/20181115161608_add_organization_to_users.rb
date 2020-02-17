class AddOrganizationToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :organization, :string
    add_column :users, :role, :string
    add_column :users, :description, :text
  end
end
