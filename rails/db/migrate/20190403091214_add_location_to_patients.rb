class AddLocationToPatients < ActiveRecord::Migration[5.1]
  def change
    add_column :patients, :region, :string
    add_column :patients, :province, :string
    add_column :patients, :city, :string
    add_column :patients, :mutation, :string
  end
end
