class Api::V1::Users::PatientsController < ApplicationController
  include PatientSupport
  # Allows to add and remove a patient to the selected user
  
  before_action :allow_only_parent_and_superadmin, only: [:update, :destroy]
  #before_action :allow_only_parent_and_superadmin, only: [:delete]
  before_action :set_user
  before_action :set_patient_from_id_allow_roles, only: [:update, :destroy]
  before_action :check_patient_enabled, only: [:update]

  # PUT /users/:user_id/patients/:id
  # Add the patient to the user
  def update
    @user.add_patient(@patient)
    if @user.save
      case current_user
      when Superadmin
        Notice.create(id:SecureRandom.uuid(), message:"L'amministratore ha associato #{@patient.name} a #{@user.name} #{@user.surname}", read:false, user:@patient.parent)
      end
      render json: @patient, status: :ok
    else
      render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /users/:user_id/patients/:id
  # Remove the patient from the user
  def destroy
    @user.patients.delete(@patient.id)
    case current_user
    when Superadmin
      Notice.create(id:SecureRandom.uuid(),message:"L'amministratore ha dissociato #{@patient.name} da #{@user.name} #{@user.surname}", read:false, user:@patient.parent)
    end
    render json: {success: true}, status: :ok
  end

  private
  
  def patient_params
    params.permit(:id)
  end

  def set_user
    # Check user existence
    unless User.exists?(params[:user_id])
      render json: {errors: [I18n.t(:error), "id: #{params[:user_id]}"]}, status: :not_found
      return
    end
    @user = User.find(params[:user_id])
  end

  def allow_user_types(valid_types)
    unless valid_types.include? current_user.type
      render json:{ errors: [ I18n.t(:error_user_unauthorized, user_type: current_user.type)] }, status: :forbidden
    end
  end

  def allow_only_parent
    allow_user_types %w(Parent)
  end

  def allow_only_parent_and_superadmin
    allow_user_types %w(Parent Superadmin)
  end

end
