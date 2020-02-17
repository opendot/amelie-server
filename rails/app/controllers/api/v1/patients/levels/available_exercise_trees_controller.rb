class Api::V1::Patients::Levels::AvailableExerciseTreesController < ApplicationController
  include I18nSupport
  include PatientSupport
  before_action :set_patient_allow_roles, :set_level
  before_action :set_available_exercise_tree, only: []

  # GET /patient/:patient_id/levels/:level_id/available_exercise_trees
  def index
    exercise_trees = @level.exercise_trees
    available_exercise_trees = exercise_trees.map {|e| e.available_exercise_tree_for(@patient.id) }

    paginate json: available_exercise_trees, each_serializer: Api::V1::Patients::Levels::AvailableExerciseTreeSerializer, status: :ok, per_page: 25
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_level
      # Check level existence
      unless Level.exists?(params[:level_id])
        render json: {errors: [I18n.t("error"), "id: #{params[:level_id]}"]}, status: :not_found
        return
      end
      @level = Level.find(params[:level_id])
    end

    def set_available_exercise_tree
      # Check existence
      @available_exercise_tree = AvailableExerciseTree.where(patient_id: params[:patient_id], exercise_tree_id: params[:exercise_tree_id]).limit(1).first
      if @available_exercise_tree.nil? 
        render json: {errors: [I18n.t("error"), "id: #{params[:exercise_tree_id]}"]}, status: :not_found
      end
    end

end
