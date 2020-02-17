class Api::V1::Patients::AvailableExerciseTreesController < ApplicationController
  include I18nSupport
  include PatientSupport
  before_action :set_patient_allow_roles
  before_action :set_available_exercise_tree, only: [:show, :update]

  # GET /patient/:patient_id/available_exercise_trees/:exercise_tree_id
  def show
    render json: @available_exercise_tree, serializer: Api::V1::Patients::AvailableExerciseTreeSerializer, status: :ok
  end

  # PATCH /patient/:patient_id/available_exercise_trees/:exercise_tree_id
  def update
    if params.has_key?(:force_completed)
      if params[:force_completed]
        success = params.require(:success)
        bypass_completion_checks = params.require(:bypass_completion_checks)
        @available_exercise_tree.exercise_tree.completed_by @patient, true, success, bypass_completion_checks
      else
        @available_exercise_tree.exercise_tree.set_as_available_for @patient
      end

      @available_exercise_tree.reload
    end
    
    render json: @available_exercise_tree, serializer: Api::V1::Patients::AvailableExerciseTreeSerializer, status: :ok
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_available_exercise_tree
      # Check existence
      @available_exercise_tree = AvailableExerciseTree.where(patient_id: params[:patient_id], exercise_tree_id: params[:exercise_tree_id]).limit(1).first
      if @available_exercise_tree.nil? 
        render json: {errors: [I18n.t("error"), "id: #{params[:exercise_tree_id]}"]}, status: :not_found
      end
    end

end
