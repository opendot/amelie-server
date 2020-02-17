class Api::V1::CustomTreesController < Api::V1::TreesController
  def destroy
    tree = Tree.find(params[:id])
    if tree.update(type: 'ArchivedTree')
      render json: {success: true}, status: :ok
    else
      render json: {errors: destroyed.errors.full_messages}, status: :locked
    end
  end
end
