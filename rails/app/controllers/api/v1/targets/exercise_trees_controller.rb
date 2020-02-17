class Api::V1::Targets::ExerciseTreesController < Api::V1::TreesController
  include I18nSupport
  before_action :set_target
  before_action :check_exercise_tree_existence, only: [:show, :update, :destroy]
  before_action :prevent_presentation_page_id, only: [:create, :update]

  # GET /targets/:target_id/exercise_trees
  # WARNING this is a N+1 query due to the number_of_pages param
  def index
    # To have both the position of the exercise trees,
    # I search all the target_layouts, but I insert inside them the values of the exercise_trees
    exercise_trees = @target.exercise_trees.base_params.with_position

    if params.has_key?(:query)
      exercise_trees = exercise_trees.where("name LIKE :query", query: "#{params[:query]}%").order(:name)
    end
    paginate json: exercise_trees, each_serializer: Api::V1::Targets::ListExerciseTreeSerializer, status: :ok, per_page: 25
  end

  # POST /targets/:target_id/exercise_trees
  def create

    # Check for the required parameters existance
    unless params.has_key?(:position)
      return render json: {errors: [I18n.t(:error_create), I18n.t(:error_invalid_parameters), "Required: position"]}, status: :unprocessable_entity
    end
    unless params.has_key?(:pages) && !params[:pages].nil?
      return render json: {errors: [I18n.t(:error_create), I18n.t(:error_invalid_parameters), "Required: pages"]}, status: :unprocessable_entity
    end

    ExerciseTree.transaction do
      begin
        exercise_tree = ExerciseTree.create_tree(exercise_tree_params, false)
        if params.has_key?(:consecutive_conclusions_required)
          exercise_tree.update_default_available_exercise_tree!(consecutive_conclusions_required: params[:consecutive_conclusions_required])
        end

        @target.add_exercise_tree(exercise_tree, params[:position])
        render json: exercise_tree, serializer: Api::V1::Targets::ExerciseTreeSerializer, status: :created
      rescue => exception
        render json: {errors: JSON.parse(exception.message)}, status: :unprocessable_entity
      end
    end
   
  end

  # GET /targets/:target_id/exercise_trees/:id
  # WARNING this is a N+1 query due to the number_of_pages param
  def show
    exercise_tree = ExerciseTree.includes( :available_exercise_trees, root_page:[:cards, page_children:[:cards, page_layouts:[:card]], page_layouts:[:card]]).find(params[:id])
    render json: exercise_tree, serializer: Api::V1::Targets::ExerciseTreeSerializer, status: :ok
  end

  # PUT /targets/:target_id/exercise_trees/:id
  # As we are following the immutable pattern, update is really a soft delete followed by a creation.
  def update
    updated_exercise_tree = @target.update_exercise_tree(params[:id], exercise_tree_params)

    if updated_exercise_tree.nil?
      render json: {errors: [I18n.t(:error_edit), "id: #{params[:id]}"]}, status: :unprocessable_entity
      return
    else

      # Update values stored in the default AvailableExerciseTree
      if params.has_key?(:consecutive_conclusions_required)
        updated_exercise_tree.update_default_available_exercise_tree!(consecutive_conclusions_required: params[:consecutive_conclusions_required])
      end
      if params.has_key?(:published)
        updated_exercise_tree.set_published(params[:published])
      end

      render json: updated_exercise_tree, serializer: Api::V1::Targets::ExerciseTreeSerializer, status: :accepted
    end
  end

  # PUT /targets/:target_id/exercise_trees/order
  # Given an array of exercise_tree ids, change the position field of the target_layouts according
  # to the order in the given array
  def order
    order_array = params[:_json]

    # Update all position fields inside the target_layouts
    unless @target.reorder_exercise_trees(order_array)
      return render json: {errors: [I18n.t(:error_invalid_parameters), "Given #{order_array.length} ids but not all elements where found"]}, status: :unprocessable_entity
    end

    exercise_trees = @target.exercise_trees.base_params.with_position.limit(25)
    render json: exercise_trees, adapter: nil, status: :ok
  end

  # DELETE /targets/:target_id/exercise_trees/:id
  def destroy
    tree = ExerciseTree.find(params[:id])
    if tree.update(type: 'ArchivedTree')

      # Destroy liks with target and patients
      tree.archive
      
      render json: {success: true}, status: :ok
    else
      render json: {errors: destroyed.errors.full_messages}, status: :locked
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_target
      # Check target existence
      unless Target.exists?(params[:target_id])
        render json: {errors: [I18n.t("error"), "id: #{params[:target_id]}"]}, status: :not_found
        return
      end
      @target = Target.find(params[:target_id])
    end

    def check_exercise_tree_existence
      # Check existence inside the target
      unless @target.exercise_trees.exists?(params[:id])
        render json: {errors: [I18n.t("error"), "id: #{params[:id]}"]}, status: :not_found
        return
      end
    end

    def exercise_tree_params
      params.permit(:id, :name, :type, :strong_feedback_page_id, pages: [:id, :name, :level, :background_color, :page_tags => [], cards:[:id, :x_pos, :y_pos, :scale, :next_page_id, :correct, :hidden_link]],
        presentation_page: [:id, :name, :background_color, :page_tags => [], cards:[:id, :x_pos, :y_pos, :scale]]
      )
    end

    def prevent_presentation_page_id
      # If updating with presentation_page_id, return an error
      if params.has_key?(:presentation_page_id)
        render json: {errors: [I18n.t(:error_invalid_parameters), "id: #{params[:id]}", I18n.t(:error_edit_presentation_page_id)]}, status: :unprocessable_entity
        return
      end
    end

end
