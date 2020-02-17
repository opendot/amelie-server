class Api::V1::InvitesController < ApplicationController

  def index
    @invites = current_user.invites
    render json: @invites, status: :ok
  end

  def create
    puts current_user.invites.count
    puts params['mails'].length
    puts Preference.get_num_invites
    if current_user.invites.count + params['mails'].length >= Preference.get_num_invites
      left_invites = Preference.get_num_invites - current_user.invites.count
      render json: {error:"user only has #{left_invites} left"}, status: :unprocessable_entity
    else
      invites = []
      failed = []
      duplicates = []
      params["mails"].each do |mail|
        if Invite.exists?(mail: mail, user:current_user, patient_id:params[:patient])
          duplicates << mail
          next
        end
        @invite = Invite.new
        @invite.mail = mail
        @invite.id = SecureRandom.uuid()
        @invite.patient_id = params["patient"]
        @invite.user = current_user
        if @invite.save
          invites << mail
          # render json: @invite, status: :accepted
        else
          failed << mail
        end
      end
      render json: {ok:invites, duplicates:duplicates, ko:failed, patient:params["patient"]}, status: :accepted
    end
  end

  private

  def invites_params
    params.permit(:mails, :patient).require(:mails,:patient)
  end

end
