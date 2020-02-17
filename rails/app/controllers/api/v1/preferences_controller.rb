class Api::V1::PreferencesController < ApplicationController

  def index
    render json: Preference.first, status: :ok
  end

  def change
    @preference = Preference.first
    if @preference.update(preference_params)
      render json: @preference, status: :accepted
    else
      render json: { errors: @notice.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def preference_params
    params.permit(:num_invites, :user_expiration_days)
  end

end

