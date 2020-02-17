class CreateQueuedSynchronizables < ActiveRecord::Migration[5.1]
  def change
    create_table :queued_synchronizables do |t|
      t.string :synchronizable_id
      t.string :synchronizable_type
      t.string :patient_id
      t.string :user_id

      t.timestamps
    end
  end
end
