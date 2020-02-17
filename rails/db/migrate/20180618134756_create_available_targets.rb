class CreateAvailableTargets < ActiveRecord::Migration[5.1]
  def change
    create_table :available_targets do |t|
      t.integer :target_id
      t.string :patient_id
      t.integer :status,      null: false,  default: 0

      t.timestamps
    end
  end
end
