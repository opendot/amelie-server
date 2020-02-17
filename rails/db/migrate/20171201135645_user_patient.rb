class UserPatient < ActiveRecord::Migration[5.1]
  def change
    create_table :patients_users, id: :string do |t|
      t.string :user_id, index: true
      t.string :patient_id, index: true
    end
  end
end
