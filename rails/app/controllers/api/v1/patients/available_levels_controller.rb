class Api::V1::Patients::AvailableLevelsController < ApplicationController
  include I18nSupport
  include PatientSupport
  before_action :set_patient_allow_roles

  # GET /patient/:patient_id/available_levels
  # List of all levels with informations about completed exercises
  def index
    available_levels = @patient.available_levels.includes(
      :level, :patient => [:available_exercise_trees, :training_sessions],
    )
  
    paginate json: available_levels, each_serializer: Api::V1::Patients::AvailableLevelSerializer, status: :ok, per_page: 25
  end

end
  