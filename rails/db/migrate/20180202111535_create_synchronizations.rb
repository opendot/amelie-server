class CreateSynchronizations < ActiveRecord::Migration[5.1]
  def change
    create_table :synchronizations do |t|
      t.string :user_id
      t.string :patient_id
      t.string :type

      t.timestamps
    end
  end
end
