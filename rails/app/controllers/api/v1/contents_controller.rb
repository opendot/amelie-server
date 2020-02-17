class Api::V1::ContentsController < ApplicationController
  def update
    # Cipher initialization
    cipher = OpenSSL::Cipher.new('aes-256-cbc')
    cipher.decrypt
    cipher.key = ENV["SYNC_ENCRYPTION_KEY"]
    cipher.iv = content_params[:iv]

    decrypted = cipher.update(content_params[:contents]) << cipher.final
    contents = ActiveSupport::Gzip.decompress(decrypted)
    contents = JSON.parse(contents, :symbolize_names => true)

    ok = true
    contents.each do |content|
      saved_content = Content.find(content[:id])
      tried_times = 0
      updated = nil
      loop do
        begin
          tried_times += 1
          updated = saved_content.update(content)
          # Update all cards related to content, since they must be included in the next synch
          saved_content.cards.update_all(updated_at: DateTime.now)
          break;
        rescue => err
          tried_times += 1
          logger.error "Can't update a content tried #{tried_times} times\n#{err.inspect}"
        end
        break if tried_times >= 5
      end
      unless updated
        logger.error saved_content.errors.full_messages
      end
      ok = ok && updated
    end
    
    if ok
      render json: {success: true}, status: :accepted
    else
      render json: {success: false}, status: :ok
    end
  end

  private

  def content_params
    params.permit(:iv, :contents)
  end
end
