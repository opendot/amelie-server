class AddDisabledToPatients < ActiveRecord::Migration[5.1]
  def change
    add_column :patients, :disabled, :boolean
  end
end
