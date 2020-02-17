class Api::V1::Patients::DailyActivitiesController < ApplicationController
  include I18nSupport
  include PatientSupport
  before_action :set_patient_allow_roles

  # GET /patient/:patient_id/daily_activities?from_date=01-01-2001&to_date=31-12-2010
  def index
    from = Time.zone.parse(params[:from_date]).to_datetime if params.has_key?(:from_date)
    to = Time.zone.parse(params[:to_date]).to_datetime if params.has_key?(:to_date)
    daily_activities = DailyActivity.index( params[:patient_id], from, to )

    paginate json: daily_activities, status: :ok, per_page: 25
  end

  # GET /patient/:patient_id/daily_activities/:date
  def show
    daily_activity = DailyActivity.new( params[:patient_id], Time.zone.parse(params[:date]).to_datetime)
    render json: daily_activity, serializer: Api::V1::Patients::DailyActivitySerializer, status: :ok
  end

end