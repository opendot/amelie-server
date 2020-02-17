class AddSettingToTrackerCalibrationParameter < ActiveRecord::Migration[5.1]
  def change
    add_column :tracker_calibration_parameters, :setting, :integer, default: 1
    add_column :tracker_calibration_parameters, :transition_matrix, :text
    add_column :tracker_calibration_parameters, :trained_fixation_time, :float
  end
end
