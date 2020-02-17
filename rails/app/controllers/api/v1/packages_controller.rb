class Api::V1::PackagesController < ApplicationController

  def index
    DownloadPackageJob.perform_later(current_user, params[:patients], params[:sessions], params[:patient_region],
                                     params.fetch(:session_type, '').split(','), params[:with_eyetracker_data])
    render json: {success: true}, status: :ok
  end

end