class Api::V1::Patients::BoxesController < ApplicationController
  include I18nSupport
  include PatientSupport
  before_action :set_patient_allow_roles

  # GET /patient/:patient_id/boxes
  def index
    boxes = Box.joins(:level)
      .select(:id, :name)
      .select("levels.value as level_value", "levels.id as level_id", "levels.name as level_name")
      .joins("LEFT OUTER JOIN available_boxes ON boxes.id = available_boxes.box_id AND available_boxes.patient_id = '#{params[:patient_id]}'")
      .select("available_boxes.status as status", "available_boxes.progress as progress",
        "available_boxes.current_target_id as current_target_id", "available_boxes.current_target_position as current_target_position",
        "available_boxes.targets_count as targets_count", "available_boxes.current_exercise_tree_id as current_exercise_tree_id",
        "available_boxes.target_exercise_tree_position as target_exercise_tree_position", "available_boxes.target_exercise_trees_count as target_exercise_trees_count",
        "available_boxes.last_completed_exercise_tree_at as last_completed_exercise_tree_at"
      )
      
  
    paginate json: boxes, status: :ok, per_page: 25
  end

end
