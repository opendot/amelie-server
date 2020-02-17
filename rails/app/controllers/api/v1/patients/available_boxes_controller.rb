class Api::V1::Patients::AvailableBoxesController < ApplicationController
  include I18nSupport
  include PatientSupport
  before_action :set_patient_allow_roles
  before_action :check_patient_enabled

  # GET /patient/:patient_id/available_boxes
  def index
    available_boxes = @patient.available_boxes.add_box_and_level.select_info
  
    paginate json: available_boxes, status: :ok, per_page: 25
  end

end
  