class ConcludePreviousSynchJob < ApplicationJob
  # Job used to upload all files that weren't uploaded in a previous failed synch
  # If the files are all corectly updated, a new synchronization is started
  queue_as :default

  def perform(current_user, patient_id, headers, direction=nil)
    synchronized = false
    response_code = 200
    last_created_at = DateTime.parse("1-01-1970")

    begin

      syncUtils = Synchronization.new(user_id: current_user.id, patient_id: patient_id)

      # Cipher initialization
      cipher = OpenSSL::Cipher.new('aes-256-cbc')
      cipher.encrypt
      cipher.key = ENV["SYNC_ENCRYPTION_KEY"]

      # Get files from checklist
      audio_files = AudioFile.where( :id => QueuedSynchronizable.where(patient_id: patient_id, synchronizable_type: "AudioFile").select_ids )
      new_contents = Content.where( :id => QueuedSynchronizable.where(patient_id: patient_id, synchronizable_type: Content::ALL_TYPES).select_ids )
      cards_play_sound = Card.where( :id => QueuedSynchronizable.where(patient_id: patient_id, synchronizable_type: Card::ALL_TYPES).select_ids )

      last_created_at = QueuedSynchronizable.where(patient_id: patient_id).maximum(:created_at)

      response_code = syncUtils.upload_files(headers, response_code, cipher, audio_files, new_contents, cards_play_sound)

      if response_code < 300
        # Create a new Synchronization that sets the conclusion of the previous synch
        synch = Synchronization.create!(user_id: current_user.id, patient_id: patient_id, direction: "up", started_at: last_created_at)

        synchronized = true
        synch.complete(synchronized)
      end
      
    rescue RestClient::Unauthorized => exception
      logger.error "RestClient::Unauthorized Error in conclude previous synchronization: #{exception.inspect}"
      response_code = 401
    rescue RestClient::Exceptions::ReadTimeout => exception
      logger.error "RestClient::Exceptions::ReadTimeout Error in conclude previous synchronization: #{exception.inspect}"
      response_code = 504
    rescue => exception
      logger.error "Generic error in conclude previous synchronization: #{exception.inspect}"
      response_code = 500
    end

    # Now that is complete, notify the mobile client.
    # ActionCable.server.broadcast("cable_#{ENV['SERVER_TO_MOBILE_SOCKET_CHANNEL_NAME']}", {type: "SYNCHRONIZATION_RESULT", direction: "previous", success: synchronized, code: response_code})

    # Now start the synchronization
    if response_code < 300
      if direction.nil? || direction == "up"
        UploadModifiedRecordsJob.perform_now(current_user, patient_id, headers, direction.nil?)
      elsif direction == "down"
        DownloadModifiedRecordsJob.perform_now(current_user, patient_id, headers)
      end
    end

  end
end
