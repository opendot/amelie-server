class Api::V1::PatientsController < ApplicationController
  include PatientSupport
  before_action :set_patient_from_id_allow_roles, only: [:show, :update, :destroy]

  def create
    if !params.has_key?(:id)
      params[:id] = SecureRandom.uuid()
    end
    patient = Patient.new(patient_params)

    if patient.save
      TobiiCalibrationParameter.create(id: SecureRandom.uuid(), fixing_radius: 0.10, fixing_time_ms: 600, patient_id: patient.id)
      if current_user.is_a? Parent
        current_user.add_patient(patient)
      end
      
      render json: patient, status: :created
    else
      render json: { errors: patient.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    @patient.assign_attributes(patient_params)
    if @patient.save
      render json: @patient, status: :accepted
    else
      render json: { errors: @patient.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def show
    if current_user.show_anonymized_patient?(@patient.id)
      # Anonymize patient
      render json: {id: @patient.id}, adapter: nil, status: :ok
    else
      if params.has_key?(:users) && params[:users] == "true"
        render json: @patient, serializer: Api::V1::SinglePatientSerializer,status: :ok
      else
        render json: @patient, serializer: Api::V1::PatientSerializer,status: :ok
      end
    end
  end

  def index
    if Rails.env.ends_with?("local") and not current_user.is_guest?
      synchronize_patients
      unless @success
        # Render nothing. A message has already been rendered by synchronize_patients method.
        return
      end
    end
    
    # Allow some users to see patients not associated to them
    if current_user.can_access_all_patients? && params[:all] == "true"
      patients = Patient.all

      if params.has_key?(:search)
        patients = filter_by_query(patients,params[:search])
      end

      if current_user.can_access_all_anonymized_patients?
        # Anonymize patients
        patients = patients.select(:id)
      end

      if params.has_key?(:parents) && params[:parents] == "true"
        paginate json: patients, adapter: current_user.can_access_all_anonymized_patients? ? nil : :attributes, status: :ok, each_serializer: Api::V1::PatientWithParentSerializer
      else
        paginate json: patients, adapter: current_user.can_access_all_anonymized_patients? ? nil : :attributes, status: :ok
      end

      # paginate json: patients, adapter: current_user.can_access_all_anonymized_patients? ? nil : :attributes, status: :ok
    else
      if params.has_key?(:parents) && params[:parents] == "true"
        paginate json: current_user.patients, status: :ok, each_serializer: Api::V1::PatientWithParentSerializer
      else
        paginate json: current_user.patients, status: :ok
      end

    end
  end

  def destroy
    Patient.destroy(params[:id])
    render json: {success: true}, status: :ok
  end



  # Returns all the users whose name or surname contains the string specified in query parameter.
  def filter_by_query(patients, query)
    if query.nil? || query == ""
      return patients
    end
    return patients.where("name LIKE :query OR surname LIKE :query", query: "#{query}%")
  end


  private

  def patient_params
    params.permit(:id, :name, :surname, :birthdate, :region, :province, :city, :mutation)
  end

  def synchronize_patients
    @success = false
    headers = {}
    headers['access-token'] = request.headers['access-token']
    headers['client'] = request.headers[:client]
    headers['expiry'] = request.headers[:expiry]
    headers['uid'] = request.headers[:uid]
    headers['token-type'] = request.headers['token-type']
    begin
      RestClient.get(ENV['ONLINE_SERVER_ADDRESS'] + "/patients", headers) { |response, request, result|
        get_response = {}
        get_response[:headers] = response.headers
        get_response[:body] = response.body
        body = JSON.parse(response.body, :symbolize_names => true)
        if response.code < 300
          Patient.transaction do
            # Reset associations between current_user and patients
            current_user.patients.delete_all

            body.each do |single|
              # Can't use find because I need the method to return nil if the serched patient doesn't exist.
              patient = Patient.find_by(id: single[:id])
              unless patient.nil?
                patient.assign_attributes(single)
                if patient.changed?
                  unless patient.save
                    logger.error "synchronize_patients: Can't update a patient"
                    logger.error single.inspect
                    return render json: {errors:["#{I18n.t :error_updating_patient}"]}, status: :unprocessable_entity
                  end
                end
              else
                patient = Patient.new(id: single[:id], name: single[:name], surname: single[:surname], birthdate: single[:birthdate])
                unless patient.save
                  logger.error "synchronize_patients: Can't synchronize patient"
                  logger.error single.inspect
                  # Don't return render, try to retrieve all the patients that I can
                end
              end
              synchronize_tracker_calibration_parameters(patient, headers)
              current_user.patients << patient
            end
          end
          @success = true
        else
          render json: get_response[:body], status: response.code
          return
        end
      }
    rescue => exception # If we come here it means there is no internet connection.
      # Work with the offline patients only
      @success = true
    end
  end

  def synchronize_tracker_calibration_parameters( patient, headers )
    RestClient.get(ENV['ONLINE_SERVER_ADDRESS'] +
      "/patients/#{patient.id}/tracker_calibration_parameters/current", headers) { |response, request, result|

      if response.code == 200
        body = JSON.parse(response.body, :symbolize_names => true)
        unless TrackerCalibrationParameter.exists?(body[:id])
          param = TrackerCalibrationParameter.new(id: body[:id], type: body[:type],
            fixing_radius: body[:fixing_radius], fixing_time_ms: body[:fixing_time_ms],
            patient_id: patient.id)
          unless param.save
            logger.error "synchronize_tracker_calibration_parameters: Can't synchronize TrackerCalibrationParameter for patient_id:#{patient.id}"
            logger.error "response body #{body.inspect}"
          end
        end
      end

    }
  end

end
