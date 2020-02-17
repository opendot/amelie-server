class Api::V1::CognitiveSessionsController < Api::V1::TrainingSessionsController
  before_action :set_cognitive_session, only: :results
  before_action :check_patient_enabled, only: :create

  def results
    render json: @cognitive_session.results, status: :ok
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_cognitive_session
      # Check patient existence
      unless CognitiveSession.exists?(params[:cognitive_session_id])
        render json: {errors: [I18n.t("error"), "id: #{params[:cognitive_session_id]}"]}, status: :unauthorized
        return
      end
      @cognitive_session = CognitiveSession.includes(:session_events).find(params[:cognitive_session_id])
    end

    # Prevent cognitive sessions for disabled patients
    def check_patient_enabled
      patient = Patient.find(params[:patient_id])
      if patient.disabled
        render json: {errors: [I18n.t("errors.patients.disabled", name: patient.name, surname: patient.surname)]}, status: :forbidden
        return
      end
    end

end
