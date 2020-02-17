class Api::V1::NoticesController < ApplicationController

  def index
    @notices = current_user.notices
    if params.has_key?(:read)
      puts params[:read]
      if params[:read] == "true"
        @notices = @notices.where({read:true})
      else
        @notices = @notices.where({read:false})
      end
    end
    render json: @notices, status: :ok
  end

  def update
    #@notice.assign_attributes(notice_params)
    @notice = Notice.find params[:id]
    if @notice.update(notice_params)
      render json: @notice, status: :accepted
    else
      render json: { errors: @notice.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def notice_params
    params.permit(:id, :message, :read, :user)
  end

  def true?(obj)
    obj.to_s == "true"
  end

end
