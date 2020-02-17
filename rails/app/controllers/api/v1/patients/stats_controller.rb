class Api::V1::Patients::StatsController < ApplicationController
  include I18nSupport
  include PatientSupport
  before_action :set_patient_allow_roles

  # GET /patient/:patient_id/stats
  def index
    to_date = DateTime.now.in_time_zone.at_beginning_of_day.to_datetime
    days = 10
    if params.has_key?(:days)
      days = params[:days].to_i
    end
    from_date = to_date - days + 1

    stat = Stat.new(@patient.id, from_date, to_date)

    response = nil
    if params.has_key?(:type)
      case params[:type]
      when "cognitive_sessions"
        response = {cognitive_sessions: stat.cognitive_sessions}
      when "communication_sessions"
        response = {communication_sessions: stat.communication_sessions}
      else
        response = {cognitive_sessions: stat.cognitive_sessions, communication_sessions: stat.communication_sessions}
      end
    else
      response = {cognitive_sessions: stat.cognitive_sessions, communication_sessions: stat.communication_sessions}
    end
    
    render json: response, status: :ok
  end

end
  