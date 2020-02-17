class Api::V1::Boxes::TargetsController < ApplicationController
  include I18nSupport
  before_action :set_box
  before_action :set_target, only: [:show, :update, :destroy]

  # GET /boxes/:box_id/targets
  def index
    # To have both the position of the target and the number of exercise trees,
    # I search all the box_layouts, but I insert inside them the values of the targets
    targets = @box.box_layouts.as_target.with_exercise_trees_count
    paginate json: targets, adapter: nil, status: :ok, per_page: 25
  end

  # POST /boxes/:box_id/targets
  def create

    # Check for the required parameters existance
    unless params.has_key?(:name) && params.has_key?(:position)
      return render json: {errors: [I18n.t(:error_create), I18n.t(:error_invalid_parameters), "Required: name, position"]}, status: :unprocessable_entity
    end

    target = Target.create(target_params)
    unless target
      return render json: {errors: JSON.parse(exception.message)}, status: :unprocessable_entity
    end
    @box.add_target(target, params[:position])

    # if nothing went wrong, return the created object
    render json: target, adapter: nil, status: :created
  end

  def show
    render json: @target, serializer: Api::V1::Boxes::TargetSerializer, status: :ok
  end

  # PUT /boxes/:box_id/targets/:id
  def update
    if @target.update(target_params)
      render json: @target, serializer: Api::V1::Boxes::TargetSerializer, status: :ok
    else
      render json: {errors: [I18n.t("error_invalid_parameters"), "id: #{params[:id]}", @target.errors]}, status: :unprocessable_entity
    end
  end

  # PUT /boxes/:box_id/targets/order
  # Given an array of target ids, change the position field of the box_layouts according
  # to the order in the given array
  def order
    order_array = params[:_json]

    # Update all position fields inside the box_layouts
    unless @box.reorder_targets(order_array)
      return render json: {errors: [I18n.t(:error_invalid_parameters), "Given #{order_array.length} ids but not all elements where found"]}, status: :unprocessable_entity
    end

    targets = @box.box_layouts.as_target.with_exercise_trees_count.limit(25)
    render json: targets, adapter: nil, status: :ok
  end

  # DELETE /boxes/:box_id/targets/:id
  def destroy
    @target.destroy!
    render json: {success: true}, status: :ok
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_box
      # Check box existence
      unless Box.exists?(params[:box_id])
        render json: {errors: [I18n.t("error"), "id: #{params[:box_id]}"]}, status: :not_found
        return
      end
      @box = Box.find(params[:box_id])
    end

    def set_target
      # Check target existence
      unless @box.targets.exists?(params[:id])
        render json: {errors: [I18n.t("error"), "id: #{params[:id]}"]}, status: :not_found
        return
      end
      @target = @box.targets.find(params[:id])
    end

    def target_params
      params.permit(:name, :published)
    end

end
