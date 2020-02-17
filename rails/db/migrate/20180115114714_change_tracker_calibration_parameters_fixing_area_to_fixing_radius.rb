class ChangeTrackerCalibrationParametersFixingAreaToFixingRadius < ActiveRecord::Migration[5.1]
  def change
    rename_column :tracker_calibration_parameters, :fixing_area, :fixing_radius
  end
end
