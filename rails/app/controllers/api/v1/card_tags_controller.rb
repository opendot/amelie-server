class Api::V1::CardTagsController < ApplicationController

  include FilterableTag

  def index
    tags = CardTag.all.order(:tag)
    if params.has_key?(:query)
      tags = filter_by_query(tags, params[:query])
    end
    paginate json: tags, each_serializer: Api::V1::TagSerializer
  end

  def show
    tag = CardTag.find(params[:id])
    render json: tag, serializer: Api::V1::TagSerializer, status: :ok
  end

end
