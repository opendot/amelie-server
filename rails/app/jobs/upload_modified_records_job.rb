require 'uri'
require 'net/http'
require 'rest_client'

class UploadModifiedRecordsJob < ApplicationJob
  include Retryable
  queue_as :default

  def perform(current_user, patient_id, headers, followed_by_download_sync=false)
    synchronized = false
    response_code = 200

    syncUtils = Synchronization.create!(user_id: current_user.id, patient_id: patient_id, direction: "up", ongoing: true, started_at: DateTime.now )

    begin
      last_sync = Synchronization.completed.successful.where(user_id: current_user.id, patient_id: patient_id, direction: "up").last
      last_sync_date = DateTime.parse("1-01-1970")
      unless last_sync.nil?
        last_sync_date = last_sync.completed_at
      end

      # Remove preview related data
      TrainingSession.delete_preview_sessions

      # Create a temporary files with all the changes
      syncUtils.collect_changes(last_sync_date, current_user, patient_id)

      file_path = Rails.root.join("private/upload_#{current_user[:id]}.rb")
      
      # Compress
      file_content = ActiveSupport::Gzip.compress(File.read(file_path))

      # Remove the temporary file
      File.delete(file_path) if File.exist?(file_path)

      # Cipher initialization
      cipher = OpenSSL::Cipher.new('aes-256-cbc')
      cipher.encrypt
      cipher.key = ENV["SYNC_ENCRYPTION_KEY"]
      iv = cipher.random_iv

      # Encryption
      file_content = cipher.update(file_content) << cipher.final

      # Send data to the online server
      response = nil
      retry_with(delay: 5, attempts: 5, delay_sleep: true, delay_inc: true) do
        response = RestClient::Request.execute(method: :post,
          url: ENV['ONLINE_SERVER_ADDRESS'] + "/new_data",
          timeout: 90000, 
          headers: headers,
          payload: {:file => file_content, :iv => iv, :direction => "up"},
        )
      end

      # Add files to checklist
      audio_files = syncUtils.get_new_audio_files
      QueuedSynchronizable.create_from_synchronizable_array(patient_id, current_user.id, audio_files)
      new_contents = syncUtils.get_new_contents
      QueuedSynchronizable.create_from_synchronizable_array(patient_id, current_user.id, new_contents)
      cards_play_sound = syncUtils.get_new_cards_play_sound
      QueuedSynchronizable.create_from_synchronizable_array(patient_id, current_user.id, cards_play_sound)

      response_code = syncUtils.upload_files(headers, response_code, cipher, audio_files, new_contents, cards_play_sound)

      synchronized = true
    rescue RestClient::Unauthorized => exception
      logger.error "RestClient::Unauthorized Error in synchronization up: #{exception.inspect}"
      response_code = 401
    rescue RestClient::Exceptions::ReadTimeout => exception
      logger.error "RestClient::Exceptions::ReadTimeout Error in synchronization up: #{exception.inspect}"
      response_code = 504
    rescue => err
      logger.error "Generic error in synchronization up: #{err.inspect}"
      response_code = 500
    ensure
      syncUtils.complete(synchronized)
    end

    # Now that upload is complete, notify the mobile client.
    # ActionCable.server.broadcast("cable_#{ENV['SERVER_TO_MOBILE_SOCKET_CHANNEL_NAME']}", {type: "SYNCHRONIZATION_RESULT", direction: "up", success: synchronized, code: response_code})

    # If requested, do the download part of the sync
    if followed_by_download_sync 
      if response_code < 300
        DownloadModifiedRecordsJob.perform_now(current_user, patient_id, headers)
      end
    end
  end
end