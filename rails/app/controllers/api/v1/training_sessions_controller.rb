class Api::V1::TrainingSessionsController < ApplicationController
  def index
    if params[:type].present?
      training_sessions = TrainingSession.where(type: params[:type])
    else
      training_sessions = TrainingSession.all
    end
    if params[:no_raw_data] == "true"
      training_sessions.includes(:tracker_calibration_parameter, :audio_file)
      paginate json: training_sessions, each_serializer: Api::V1::TrainingSessionNoRawDataSerializer, status: :ok
    else
      training_sessions.includes(:tracker_calibration_parameter, :audio_file, :tracker_raw_data)
      paginate json: training_sessions, each_serializer: Api::V1::TrainingSessionSerializer, status: :ok
    end
  end

  def show
    if params[:no_raw_data] == "true"
      render json: TrainingSession.includes(:tracker_calibration_parameter, :audio_file).find(params[:id]), serializer: Api::V1::TrainingSessionNoRawDataSerializer
    else
      render json: TrainingSession.includes(:tracker_calibration_parameter, :audio_file, :tracker_raw_data).find(params[:id]), serializer: Api::V1::TrainingSessionSerializer
    end
  end

  # Creates a new TrainingSession. This method expects to have a tracker_calibration_parameter inside the json
  # in order to have a default tracker_calibration_parameter.
  def create
    patient = Patient.find(params[:patient_id])
    session_params = training_session_params
    calibration = TrackerCalibrationParameter.new(session_params[:tracker_calibration_parameter])
    calibration.patient = patient
    session_params[:tracker_calibration_parameter] = calibration

    # If it's a preview delete the old one.
    if session_params[:id].to_s.start_with?('preview_')
      training_session = TrainingSession.find_by_id(params[:id])
      unless training_session.nil?
        training_session.destroy
      end
    end

    session = TrainingSession.new(session_params)
    unless params.has_key?(:user_id)
      session.user_id = current_user.id
    end
    unless params.has_key?(:start_time)
      session.start_time = DateTime.current
    end
    unless calibration.valid?
      render json: { errors: calibration.errors.full_messages }, status: :unprocessable_entity
      return
    end
    TrackerCalibrationParameter.transaction do
      calibration.save!
      session.tracker_calibration_parameter_id = calibration.id
      session.save!
      ActionCable.server.broadcast("cable_#{ENV['SERVER_TO_DESKTOP_SOCKET_CHANNEL_NAME']}", {type: "SET_TRAINING_SESSION_PARAMS", data: {training_session_id: session.id, type: params[:type], tracker_calibration_parameters: calibration}}.to_json)
      render json: session, serializer: Api::V1::TrainingSessionNoRawDataSerializer, status: :created
    end
  end

  def update
    update_params = params.permit(:start_time, :duration, :screen_resolution_x, :screen_resolution_y, :tracker_type, :user_id, :patient_id, :type)
    session = TrainingSession.find(params[:id])
    if session.update(update_params)
      render json: session, serializer: Api::V1::TrainingSessionNoRawDataSerializer, status: :accepted
    else
      render json: session.errors.full_messages, status: :unprocessable_entity
    end
  end

  # POST /training_sessions/align_eyetracker
  def align_eyetracker
    if params[:show].nil?
      return render json: {errors: [ I18n.t(:error), "show: #{params[:show]}"]}, status: :unprocessable_entity
    end

    if params[:show] == true
      ActionCable.server.broadcast("cable_#{ENV['SERVER_TO_DESKTOP_SOCKET_CHANNEL_NAME']}",
        {type: "SHOW_ALIGN_ON", data: nil}.to_json)
    else
      ActionCable.server.broadcast("cable_#{ENV['SERVER_TO_DESKTOP_SOCKET_CHANNEL_NAME']}",
        {type: "SHOW_ALIGN_OFF", data: nil}.to_json)
    end
    render json: {success: true}, status: :ok
  end

  # POST /training_sessions/change_route
  def change_route
    if params[:name].nil?
      return render json: {errors: [ "name: #{params[:name]}"]}, status: :unprocessable_entity
    end

    ActionCable.server.broadcast("cable_#{ENV['SERVER_TO_DESKTOP_SOCKET_CHANNEL_NAME']}",
      {type: "CHANGE_ROUTE", data: {name: params[:name]}}.to_json)
    render json: {success: true}, status: :ok
  end

  private
  
  def training_session_params
    params.permit(:id, :start_time, :duration, :screen_resolution_x, :screen_resolution_y, :tracker_type, :user_id, :patient_id, :type, :tracker_calibration_parameter => [:id, :setting, :fixing_radius, :fixing_time_ms, :trained_fixation_time, :transition_matrix, :type])
  end
end
