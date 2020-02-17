class Api::V1::Patients::TrainingSessionsController < ApplicationController
  include I18nSupport
  include PatientSupport
  before_action :set_patient_allow_roles
  before_action :set_training_session, only: [:show]

  # GET /patient/:patient_id/training_sessions
  def index
    sessions = @patient.training_sessions

    if params.has_key?(:type)
      sessions = sessions.where(type: params[:type])
    end

    sessions = order_direction_filter(sessions)

    paginate json: sessions, each_serializer: Api::V1::Patients::TrainingSessionListSerializer, status: :ok, per_page: 25
  end

  # GET /patient/:patient_id/training_sessions/:id
  def show
    case @session
    when CognitiveSession
      return render json: @session, serializer: Api::V1::Patients::CognitiveSessionSerializer, status: :ok
    else
      if params.has_key?(:detailed) && params[:detailed] == "true"
        return render json: @session, serializer: Api::V1::Patients::TrainingSessionDetailedSerializer, status: :ok
      else
        return render json: @session, serializer: Api::V1::Patients::TrainingSessionSerializer, status: :ok
      end

    end
  end

  protected

    # Use order and direction params to sort the list
    def order_direction_filter(sessions)
      if params.has_key?(:order)
        case params[:order]
        when "start_time"
          case params[:direction]
          when "ASC"
            sessions = sessions.reorder(start_time: :asc)
          when "DESC"
            sessions = sessions.reorder(start_time: :desc)
          else
            sessions = sessions.reorder(start_time: :asc)
          end
        when "duration"
          case params[:direction]
          when "ASC"
            sessions = sessions.reorder(duration: :asc)
          when "DESC"
            sessions = sessions.reorder(duration: :desc)
          else
            sessions = sessions.reorder(duration: :asc)
          end
        end
      end
      return sessions
    end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_training_session
      # Check session existence and if belongs to patient
      unless @patient.training_sessions.exists?(params[:id])
        render json: {errors: [I18n.t(:error), "id: #{params[:id]}"]}, status: :unauthorized
        return
      end
      @session = TrainingSession.find(params[:id])
      if params.has_key?(:type) && @session.type != params[:type]
        return render json: {errors: [I18n.t(:error), "id: #{params[:id]}", "type: #{params[:type]}"]}, status: :not_found
      end
    end

end
