class TrackerCalibrationParameterChangeEvent < OperatorEvent
  require_dependency 'session_event'  
    
  skip_callback :save, :before, :ensure_tracker_calibration_parameter_id_is_nil

  has_one :tracker_calibration_parameter
end
