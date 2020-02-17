class Api::V1::PreviewTreesController < ApplicationController
  def destroy
    if params.has_key?(:all) && params[:all] == "true"
      PreviewTree.where(patient_id: params[:patient_id], user_id: current_user[:id]).destroy_all
      render_success
      return
    end
    preview_tree = Tree.find(params[:id])
    preview_tree.destroy
    render_success
  end

  private

  def preview_params
    params.permit(:id, :all, :patient_id)
  end

  def render_success
    render json: {success: true}, status: :ok
  end
end
