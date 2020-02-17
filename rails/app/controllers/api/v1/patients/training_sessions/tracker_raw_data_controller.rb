class Api::V1::Patients::TrainingSessions::TrackerRawDataController < ApplicationController
  include I18nSupport
  include PatientSupport
  before_action :set_patient_allow_roles, :set_training_session

  def index
    # paginate json: @session.tracker_raw_data, each_serializer: Api::V1::TrackerRawDatumSerializer, status: :ok, per_page: 25
    render json: @session.tracker_raw_data, each_serializer: Api::V1::TrackerRawDatumSerializer, status: :ok
  end

end
