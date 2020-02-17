class Api::V1::Patients::BadgesController < ApplicationController
  include PatientSupport
  before_action :set_patient_allow_roles
  before_action :set_badge, only: [:show]

  # GET /patients/:patient_id/badges
  def index
    badges = Badge.for_patient(params[:patient_id])
    
    if params.has_key?(:type)
      case params[:type]
      when "cognitive_sessions"
        badges = badges.cognitive_sessions
      when "communication_sessions"
        badges = badges.communication_sessions
      end
    end

    if params.has_key?(:limit)
      badges = badges.order(date: :desc).limit(params[:limit])

      # The limit param is overwritten by the pagination
      if params[:limit].to_i < (params[:per_page] || 25).to_i
        return render json: badges, status: :ok, each_serializer: Api::V1::BadgeSerializer
      end
    end

    paginate json: badges, status: :ok, each_serializer: Api::V1::BadgeSerializer, per_page: params[:per_page] || 25
  end

  # GET /patients/:patient_id/badges/:id
  def show
    render json: @badge, serializer: Api::V1::BadgeSerializer, status: :ok
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_badge
      @badge = Badge.where(id: params[:id], patient_id: params[:patient_id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def badge_params
      params.require(:badge).permit(:id, :patient_id, :date, :achievement, :target_id, :target_name, :box_id, :box_name, :level_id, :level_name)
    end
end
