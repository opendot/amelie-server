class Api::V1::Patients::LevelsController < ApplicationController
  include I18nSupport
  include PatientSupport
  before_action :set_patient_allow_roles

  # GET /patient/:patient_id/levels
  def index
    levels = Level.with_boxes.includes(available_levels: [:patient, :level])
      .page(params[:page]).per(3)

    # Preload all available_boxes of the patient
    patient_available_boxes = @patient.available_boxes.includes(:patient, box: [:level])
    patient_available_boxes_ids = @patient.available_box_ids

    levels.each do |level|
      level.available = level.available? @patient.id
      level.b = []
      boxes = level.boxes

      # Create the boxes, all this prevents N+1 queries
      boxes.each do |box|
        box_json = box.as_json

        # Find the available_box for this patient and this object, prevent N+1 queries
        available_box_ids = box.available_box_ids
        filtered_available_boxes = patient_available_boxes_ids & available_box_ids
        available_box = patient_available_boxes.find {|b| b.id == filtered_available_boxes.first}

        # Add the available_box to the box
        box_json["available_box"] = available_box
        level.b << box_json
      end
    end

    render json: levels, status: :ok
  end

end
