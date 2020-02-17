class CreateTrainingSessions < ActiveRecord::Migration[5.1]
  def change
    create_table :training_sessions, id: :string do |t|
      t.datetime :start_time
      t.float :duration
      t.integer :screen_resolution_x
      t.integer :screen_resolution_y
      t.string :tracker_type
      t.string :user_id, index: true
      t.string :patient_id, index: true
      t.string :audio_file_id, index: true
      t.string :tracker_calibration_parameter_id, index: true
      t.string :type

      t.timestamps
    end
  end
end
