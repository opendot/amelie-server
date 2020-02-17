class Api::V1::GamesController < ApplicationController
  include I18nSupport

  # Since there isn't a Game model, Cancancan can't process this controller
  # Make it available to all users
  skip_authorize_resource

  # POST /games
  # Start a game
  def create
    ActionCable.server.broadcast("cable_#{ENV['SERVER_TO_DESKTOP_SOCKET_CHANNEL_NAME']}", {
      type: "START_GAME",
      data: {game: params[:name], level: params[:level], fixingtime: params[:fixingtime]}
    }.to_json)
    return render json: {success: true}, status: :ok
  end

  # DELETE /games
  # End a game
  def destroy
    ActionCable.server.broadcast("cable_#{ENV['SERVER_TO_DESKTOP_SOCKET_CHANNEL_NAME']}", {
      type: "END_GAME",
      data: {game: params[:name]}
    }.to_json)
    return render json: {success: true}, status: :ok
  end

  private

  def game_params
    params.permit( :name, :level )
  end

end
