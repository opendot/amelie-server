class Api::V1::LevelsController < ApplicationController
  include I18nSupport
  before_action :check_level_existence, only: [:show]
  before_action :set_level, only: [:update, :destroy]
  
  def index
    levels = Level.base_params.with_boxes_count
    paginate json: levels, status: :ok, adapter: nil, per_page: 25
  end

  def create

    # Check for the required parameters existance
    unless params.has_key?(:name) && params.has_key?(:value)
      return render json: {errors: [I18n.t(:error_create), I18n.t(:error_invalid_parameters)]}, status: :unprocessable_entity
    end

    # If there is a problem during level creation, it will raise an exception
    level = Level.create(level_params)
    unless level.save
      return render json: {errors: JSON.parse(exception.message)}, status: :unprocessable_entity
    end
    # if nothing went wrong, return the created object
    render json: level, adapter: nil, status: :created
  end

  def show
    level = Level.where(id: params[:id]).base_params.includes(:boxes).first
    render json: level, serializer: Api::V1::LevelWithBoxesSerializer, status: :ok
  end

  def update
    if @level.update(level_params)
      render json: @level, adapter: nil, include: [:boxes], status: :ok
    else
      render json: {errors: [I18n.t("error_invalid_parameters"), "id: #{params[:id]}", @level.errors]}, status: :unprocessable_entity
    end
  end

  # PUT levels/order
  # Given an array of level ids, change the value field of the levels according
  # to the order in the given array
  def order
    order_array = params[:_json]

    # To update the value field, create an Hash in the form { <level_id> => {value: <new_value>} }
    count = 0
    new_order = Hash[order_array.map{ |level_id| [level_id, {value: count += 1}] }]

    # Update all levels
    updated_levels = Level.update(new_order.keys, new_order.values)
    render json: updated_levels, status: :ok, adapter: nil, per_page: 25
  end

  def destroy
    @level.destroy!
    render json: {success: true}, status: :ok
  end

  private
    
    def level_params
        params.permit(:name, :value, :published)
    end

    def check_level_existence
      unless Level.exists?(params[:id])
        render json: {errors: [I18n.t("error"), "id: #{params[:id]}"]}, status: :not_found
      end
    end

    def set_level
      # Check level existence
      unless Level.exists?(params[:id])
        render json: {errors: [I18n.t("error"), "id: #{params[:id]}"]}, status: :not_found
        return
      end
      @level = Level.find(params[:id])
    end

end