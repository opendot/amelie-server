class Api::V1::TrackerCalibrationParameterChangeEventsController < Api::V1::SessionEventsController
  def create
    session = TrainingSession.find(params[:training_session_id])
    patient = session.patient
    event_params = session_event_params
    calibration = TrackerCalibrationParameter.new(event_params[:tracker_calibration_parameter])
    calibration.patient = patient
    calibration.training_session = session
    calibration.id = SecureRandom.uuid() if calibration.id.blank?
    event_params.delete(:tracker_calibration_parameter)
    event = TrackerCalibrationParameterChangeEvent.new(event_params)
    event.id = SecureRandom.uuid()
    calibration.tracker_calibration_parameter_change_event_id = event.id
    unless calibration.valid?
      render json: { errors: calibration.errors.full_messages }
      return
    end
    TrackerCalibrationParameterChangeEvent.transaction do
      calibration.save!
      
      
      event.tracker_calibration_parameter_id = calibration.id
      if event.save
        broadcast_event_message(calibration)
        render_event(event)
      else
        render json: {errors: event.errors.full_messages}, status: :unprocessable_entity
        raise ActiveRecord::Rollback
      end
    end
  end
  
  protected 

  def broadcast_event_message(calibration)
    ActionCable.server.broadcast("cable_#{ENV['SERVER_TO_DESKTOP_SOCKET_CHANNEL_NAME']}", {type: "SET_TRACKER_CALIBRATION_PARAMS", data: Api::V1::TrackerCalibrationParameterSerializer.new(calibration)}.to_json)
  end

  def session_event_params
    params.permit(:type, :page_id, :training_session_id, tracker_calibration_parameter: [:fixing_radius, :fixing_time_ms, :type])
  end
end
