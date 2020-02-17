class RemoveIdToUserPatient < ActiveRecord::Migration[5.1]
  def change
    remove_column :patients_users, :id, :string
    add_index :patients_users, [:patient_id, :user_id], :unique => true
  end
end
