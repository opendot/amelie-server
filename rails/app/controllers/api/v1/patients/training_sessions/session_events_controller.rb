class Api::V1::Patients::TrainingSessions::SessionEventsController < ApplicationController
  include I18nSupport
  include PatientSupport
  before_action :set_patient_allow_roles, :set_training_session

  def index
    if params.has_key?(:detailed) && params[:detailed] == "true"
      paginate json: @session.session_events, serializer: Api::V1::SessionEventsCollectionDetailedSerializer, status: :ok, per_page: 25
    else
      paginate json: @session.session_events, serializer: Api::V1::SessionEventsCollectionSerializer, status: :ok, per_page: 25
    end
  end

end
