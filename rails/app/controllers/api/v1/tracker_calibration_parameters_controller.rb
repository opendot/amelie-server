class Api::V1::TrackerCalibrationParametersController < ApplicationController
  def create
    calibration = TrackerCalibrationParameter.create!(tracker_calibration_parameters_params)
    render json: calibration, status: :created, serializer: Api::V1::TrackerCalibrationParameterSerializer
  end

  def show
    unless Patient.exists?(params[:patient_id])
      render json: {errors: ["#{I18n.t :error_invalid_patient_id}."]}, status: :not_found
      return
    end
    calibration = TrackerCalibrationParameter.where(patient_id: params[:patient_id]).last
    render json: calibration, status: :ok, serializer: Api::V1::TrackerCalibrationParameterSerializer
  end

  # PUT /patients/:patient_id/tracker_calibration_parameters/:id
  # create a clone of the last tracker_calibration_parameter and update the given data
  # this is used to create a new tracker_calibration_parameter without sending all params
  def update
    unless current_user.patients.exists?(params[:patient_id]) || current_user.is_a?(DesktopPc)
      render json: {errors: [I18n.t(:error_invalid_patient_id), "id: #{params[:patient_id]}"]}, status: :not_found
      return
    end

    # Clone the current params
    last_calibration = TrackerCalibrationParameter.where(patient_id: params[:patient_id]).last
    calibration = last_calibration.get_a_clone

    # Assign the params received from the request
    calibration.update(tracker_calibration_parameters_update_params)
    if calibration.save
      render json: calibration, status: :ok, serializer: Api::V1::TrackerCalibrationParameterSerializer
    else
      render json: {errors: [I18n.t(:error_saving), I18n.t(:should_never)]}, status: :bad_request
    end
  end

  private

  def tracker_calibration_parameters_params
    params.permit(:id, :setting, :fixing_radius, :fixing_time_ms, :transition_matrix, :trained_fixation_time, :type, :patient_id)
  end

  def tracker_calibration_parameters_update_params
    params.permit(:setting, :fixing_radius, :fixing_time_ms, :transition_matrix, :trained_fixation_time, :type, :patient_id)
  end
end
