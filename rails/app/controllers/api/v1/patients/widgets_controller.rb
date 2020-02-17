class Api::V1::Patients::WidgetsController < ApplicationController
  include I18nSupport
  include PatientSupport
  before_action :set_patient_allow_roles

  # GET /patient/:patient_id/widgets
  def index
    widget = Widget.new(@patient.id)

    response = nil
    if params.has_key?(:type)
      case params[:type]
      when "cognitive_sessions"
        response = {cognitive_sessions: widget.cognitive_sessions}
      when "communication_sessions"
        response = {communication_sessions: widget.communication_sessions}
      else
        response = {cognitive_sessions: widget.cognitive_sessions, communication_sessions: widget.communication_sessions}
      end
    else
      response = {cognitive_sessions: widget.cognitive_sessions, communication_sessions: widget.communication_sessions}
    end
    
    render json: response, status: :ok
  end

end
  