module PatientSupport
  extend ActiveSupport::Concern

  def set_patient
    # Check patient existence
    unless Patient.exists?(params[:patient_id])
      render json: {errors: [I18n.t(:error_invalid_patient_id), "id: #{params[:patient_id]}"]}, status: :unauthorized
      return
    end
    @patient = Patient.find(params[:patient_id])
  end

  def set_patient_from_id
    # Check patient existence
    unless Patient.exists?(params[:id])
      render json: {errors: [I18n.t(:error_invalid_patient_id), "id: #{params[:id]}"]}, status: :unauthorized
      return
    end
    @patient = Patient.find(params[:id])
  end

  def set_patient_from_current_user
    # Check patient existence
    unless @current_user.patients.exists?(params[:patient_id])
      render json: {errors: [I18n.t("errors.patients.not_found_for_user", patient_id: params[:patient_id], user_email: @current_user.email)]}, status: :unauthorized
      return
    end
    @patient = Patient.find(params[:patient_id])
  end

  def set_patient_from_id_from_current_user
    # Check patient existence
    unless @current_user.patients.exists?(params[:id])
      render json: {errors: [I18n.t("errors.patients.not_found_for_user", patient_id: params[:id], user_email: @current_user.email)]}, status: :unauthorized
      return
    end
    @patient = Patient.find(params[:id])
  end

  # Allow researchers and superadmins to access all patients
  def set_patient_allow_roles
    if @current_user.can_access_all_patients?
      set_patient
    else
      set_patient_from_current_user
    end
  end

  # Allow researchers and superadmins to access all patients
  def set_patient_from_id_allow_roles
    if @current_user.can_access_all_patients?
      set_patient_from_id
    else
      set_patient_from_id_from_current_user
    end
  end

  def set_training_session
    # Check session existence and if belngs to patient
    unless @patient.training_sessions.exists?(params[:training_session_id])
      render json: {errors: [I18n.t(:error), "id: #{params[:training_session_id]}"]}, status: :unauthorized
      return
    end
    @session = TrainingSession.find(params[:training_session_id])
  end

  # Prevent action for disabled patients
  def check_patient_enabled
    if @patient.disabled
      render json: {errors: [I18n.t("errors.patients.disabled", name: @patient.name, surname: @patient.surname)]}, status: :forbidden
      return
    end
  end

end
