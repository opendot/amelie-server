class Api::V1::Levels::BoxesController < ApplicationController
  include I18nSupport
  before_action :set_level
  before_action :set_box, only: [:show, :update, :destroy]

  # GET /levels/:level_id/boxes
  def index
    boxes = @level.boxes.base_params.with_targets_count
    paginate json: boxes, adapter: nil, status: :ok, per_page: 25
  end

  # POST /levels/:level_id/boxes
  def create

    # Check for the required parameters existance
    unless params.has_key?(:name)
      return render json: {errors: [I18n.t(:error_create), I18n.t(:error_invalid_parameters)]}, status: :unprocessable_entity
    end

    box = Box.new(box_params)
    @level.boxes << box
    unless box
      return render json: {errors: JSON.parse(exception.message)}, status: :unprocessable_entity
    end

    # if nothing went wrong, return the created object
    render json: box, adapter: nil, status: :created
  end

  def show
    render json: @box, serializer: Api::V1::Levels::BoxSerializer, status: :ok
  end

  # PUT /levels/:level_id/boxes/:id
  def update
    if @box.update(box_params)
      render json: @box, serializer: Api::V1::Levels::BoxSerializer, status: :ok
    else
      render json: {errors: [I18n.t("error_invalid_parameters"), "id: #{params[:id]}", @box.errors]}, status: :unprocessable_entity
    end
  end

  # DELETE /levels/:level_id/boxes/:id
  def destroy
    @box.destroy!
    render json: {success: true}, status: :ok
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

    def set_box
      # Check box existence
      unless @level.boxes.exists?(params[:id])
        render json: {errors: [I18n.t("error"), "id: #{params[:id]}"]}, status: :not_found
        return
      end
      @box = @level.boxes.find(params[:id])
    end

    def box_params
      params.permit(:name, :published)
    end

end
