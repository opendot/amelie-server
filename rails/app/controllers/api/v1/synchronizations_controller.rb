class Api::V1::SynchronizationsController < ApplicationController
  include PatientSupport
  include Retryable
  before_action :set_patient_allow_roles, only: [:index]

  def index
    synchronizations = Synchronization.where(patient_id: params[:patient_id]).reorder(started_at: :desc)

    if params.has_key?(:ongoing)
      synchronizations = synchronizations.where(ongoing: params[:ongoing])
    end
    if params.has_key?(:direction)
      synchronizations = synchronizations.where(direction: params[:direction])
    end
    if params.has_key?(:success)
      synchronizations = synchronizations.where(success: params[:success])
    end
    if params.has_key?(:started_after)
      synchronizations = synchronizations.where("started_at > ?", params[:success])
    end

    paginate json: synchronizations, adapter: nil, status: :ok
  end

  # Used to start an upload.
  def create
    # Need a patient_id
    if synchronization_params[:patient_id].blank?
      render json: {errors:["#{I18n.t :error_missing_patient_id}"]}, status: :bad_request
      return
    end

    # Check that the patient_id is valid
    unless Patient.exists?(synchronization_params[:patient_id])
      render json: {errors:["#{I18n.t :error_invalid_patient_id}"]}, status: :bad_request
      return
    end

    # Intercept user's headers. Sign_in has already ensured that online and offline
    # server use the same values.
    headers = {}
    headers['accept'] = 'application/airett.v1'
    headers['access-token'] = request.headers['access-token']
    headers['client'] = request.headers['client']
    headers['expiry'] = request.headers['expiry']
    headers['token-type'] = request.headers['token-type']
    headers['uid'] = request.headers['uid']

    # Check if the patient is allowed to synchronize, this also check if remote server is reachable
    return unless check_patient_can_synchronize(params[:patient_id], headers)

    # Just to inform the user that nothing has been done if he used wrong parameters.
    worked = false
    if QueuedSynchronizable.for_patient(params[:patient_id]).limit(1).count > 0
      # A previous Synchronization failed, first upload the residual synchronizables
      check_private_folder_exists
      ConcludePreviousSynchJob.perform_now(current_user, params[:patient_id], headers, params[:direction])
      worked = true
    else
      if synchronization_params.has_key?(:direction)
        case synchronization_params[:direction]
          when "up"
            check_private_folder_exists
            UploadModifiedRecordsJob.perform_now(current_user, params[:patient_id], headers)
            worked = true

          when "down"
            check_private_folder_exists
            DownloadModifiedRecordsJob.perform_now(current_user, params[:patient_id], headers)
            worked = true
        end
      else
        check_private_folder_exists
        UploadModifiedRecordsJob.perform_now(current_user, params[:patient_id], headers, true)
        worked = true
      end
    end

    render json: { success: worked }
  end

  # Used to receive data onto the online server
  def post_new_data
    file_data = decrypt_and_uncompress

    Synchronization.apply_edits(file_data)

    render json: { success: true }
  end

  # Used to start a download from the online server
  def get_new_data
    syncUtils = Synchronization.new
    last_sync_date = DateTime.parse(synchronization_params[:last_sync_date])
    syncUtils.collect_changes(last_sync_date, current_user, synchronization_params[:patient_id], true)

    # Configure cypher
    cipher = OpenSSL::Cipher.new('aes-256-cbc')
    cipher.reset
    cipher.encrypt
    cipher.key = ENV["SYNC_ENCRYPTION_KEY"]
    iv = cipher.random_iv

    file_path = Rails.root.join("private/upload_#{current_user[:id]}.rb")
    file_content = cipher.update(ActiveSupport::Gzip.compress(File.read(file_path))) << cipher.final

    File.delete(file_path) if File.exist?(file_path)

    render json: {file: Base64.encode64(file_content), iv: Base64.encode64(iv)}
  end

  protected

  def synchronization_params
    params.permit(:file, :iv, :direction, :last_sync_date, :patient_id)
  end

  # Check if the patient is allowed to synchronize
  def check_patient_can_synchronize(patient_id, headers)
    # skip for tests
    return true if Rails.env.test?

    # Get patient informations form remote server,
    # check if he has a parent and if the arent is disabled
    begin
      response = nil
      retry_with(delay: 2, delay_sleep: true, delay_inc: true, debug: false) do
        response = RestClient::Request.execute(method: :get,
          url: ENV['ONLINE_SERVER_ADDRESS'] + "/patients/#{patient_id}",
          timeout: 15,
          headers: headers,
        )
      end

      unless response.code == 200
        render json: { errors: I18n.t("errors.patients.not_found", patient_id: patient_id)}, status: response.code
        return false
      end
      patient_hash = JSON.parse(response.body)

      # Update patient
      Patient.find(patient_id).update_from_serialized(patient_hash)

      patient =  Patient.find(patient_id)
      if patient.disabled
        # The parent of this patient is disabled, user has limited access
        render json: {errors: [I18n.t("errors.patients.disabled", name: patient.name, surname: patient.surname)]}, status: :forbidden
        return false
      end

      # Remote server is reachable, headers are correct and user is allowed to synchronize
      return true

    rescue RestClient::Exceptions::Timeout  => err_timeout
      logger.error "Error in check_patient_can_synchronize: Timeout\n#{err_timeout.message}"
      logger.error err_timeout.message
      render json: {errors: [ I18n.t("errors.synch.remote_unreachable"), err_timeout.message]}, status: :gateway_timeout
      return false
    rescue Errno::EHOSTUNREACH  => err_host_unreachable
      logger.error "Error in check_patient_can_synchronize: Host unreachable \n#{err_host_unreachable.message}"
      logger.error err_host_unreachable.message
      render json: {errors: [ I18n.t("errors.synch.remote_unreachable"), err_host_unreachable.message]}, status: :service_unavailable
      return false
    rescue Exception => err
      logger.error "Error in check_patient_can_synchronize: \n#{err.inspect}"
      logger.error err.message
      render json: {errors: [err.message]}, status: :internal_server_error
      return false
    end
  end

  def decrypt_and_uncompress
    file_data = synchronization_params[:file]

    # decryption
    cipher = OpenSSL::Cipher.new('aes-256-cbc')
    cipher.decrypt
    cipher.key = ENV["SYNC_ENCRYPTION_KEY"]
    cipher.iv = synchronization_params[:iv]

    file_data = cipher.update(file_data) << cipher.final

    # Decompression 
    return ActiveSupport::Gzip.decompress(file_data)
  end

  def check_private_folder_exists
    needed_path = Rails.root.join("private")
    unless File.directory?(needed_path)
      FileUtils.mkdir_p(needed_path)
    end
  end
end
