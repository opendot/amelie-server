class Api::V1::PageTagsController < ApplicationController

  include FilterableTag

  def index
    tags = PageTag.all
    if params.has_key?(:query)
      tags = filter_by_query(tags, params[:query])
    end
    paginate json: tags, each_serializer: Api::V1::TagSerializer, status: :ok
  end

  def show
    tag = PageTag.find(page_tags_params[:id])
    render json: tag, serializer: Api::V1::TagSerializer, status: :ok
  end

  private

  def page_tags_params
    params.permit(:id)
  end
end
