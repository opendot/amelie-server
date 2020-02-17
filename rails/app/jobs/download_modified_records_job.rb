class DownloadModifiedRecordsJob < ApplicationJob
  include Retryable
  queue_as :default

  def perform(current_user, patient_id, headers)
    synchronized = false
    response_code = 200
    synch = Synchronization.create!(user_id: current_user[:id], patient_id: patient_id, direction: "down", ongoing: true, started_at: DateTime.now )

    ActiveRecord::Base.transaction do
      begin
        last_sync = Synchronization.completed.successful.where(user_id: current_user.id, patient_id: patient_id, direction: "down").last
        last_sync_date = DateTime.parse("1-01-1970")
        unless last_sync.nil?
          last_sync_date = last_sync.started_at_string
        end

        response = nil
        retry_with(delay: 5, attempts: 5, delay_sleep: true, delay_inc: true, debug: true) do
          #response = RestClient.get(ENV['ONLINE_SERVER_ADDRESS'] + "/new_data?last_sync_date=#{last_sync_date}&patient_id=#{patient_id}", headers)
          response = RestClient::Request.execute(
              method: :get,
              url:ENV['ONLINE_SERVER_ADDRESS'] + "/new_data?last_sync_date=#{last_sync_date}&patient_id=#{patient_id}",
              timeout: 90000,
              headers:headers,
              )
        end
        response_code = [response.code, response_code].max

        data = JSON.parse(response.body, :symbolize_names => true)

        # Cipher initialization
        cipher = OpenSSL::Cipher.new('aes-256-cbc')
        cipher.decrypt
        cipher.key = ENV["SYNC_ENCRYPTION_KEY"]
        cipher.iv = Base64.decode64(data[:iv])

        # decryption and decompression
        file_content = ActiveSupport::Gzip.decompress(cipher.update(Base64.decode64(data[:file])) << cipher.final)

        Synchronization.apply_edits(file_content)

        synchronized = true

      rescue RestClient::Unauthorized => exception
        logger.error "Error in synchronization down: #{exception.inspect}"
        response_code = 401
        raise ActiveRecord::Rollback
      rescue => err
        logger.error "Generic error in synchronization down:: #{err.inspect}"
        response_code = 500
        raise ActiveRecord::Rollback
      end
    end

    synch.complete(synchronized)

    # Now that upload is complete, notify the mobile client.
    # ActionCable.server.broadcast("cable_#{ENV['SERVER_TO_MOBILE_SOCKET_CHANNEL_NAME']}", {type: "SYNCHRONIZATION_RESULT", direction: "down", success: synchronized, code: response_code})

  end
end
