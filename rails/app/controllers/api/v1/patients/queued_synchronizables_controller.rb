class Api::V1::Patients::QueuedSynchronizablesController < ApplicationController
  include I18nSupport
  include PatientSupport
  before_action :set_patient_allow_roles

  # GET /patient/:patient_id/queued_synchronizables
  def index
    queued_synchronizables = @patient.queued_synchronizables
  
    paginate json: queued_synchronizables, adapter: nil, status: :ok
  end

end
  