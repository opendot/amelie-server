class CreateTrackerCalibrationParameters < ActiveRecord::Migration[5.1]
  def change
    create_table :tracker_calibration_parameters, id: :string do |t|
      t.float :fixing_area
      t.integer :fixing_time_ms
      t.string :patient_id, index: true
      t.string :training_session_id, index: true
      t.string :tracker_calibration_parameter_change_event_id, index: {name: 'index_tracker_calibration_parameter_change_event_id'}
      t.string :type

      t.timestamps
    end
  end
end
