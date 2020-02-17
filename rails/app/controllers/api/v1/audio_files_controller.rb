class Api::V1::AudioFilesController < ApplicationController

  def create
    @audio_file = AudioFile.new(audio_file_params)
    @audio_file[:id] = SecureRandom.uuid()
    unless Rails.env.test? || Rails.env.development? || Rails.env.ends_with?("local")
      @uploader = @audio_file.audio_file
      @uploader.success_action_redirect = on_audio_uploaded
    end
    @audio_file.audio_file = params[:audio_file]
    if @audio_file.save
      render json: @audio_file, status: :accepted
    else
      render json: { errors: @audio_file.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update

    # Cipher initialization
    cipher = OpenSSL::Cipher.new('aes-256-cbc')
    cipher.decrypt
    cipher.key = ENV["SYNC_ENCRYPTION_KEY"]
    cipher.iv = params[:iv]

    files = ActiveSupport::Gzip.decompress(cipher.update(params[:audio_files]) << cipher.final)
    files = JSON.parse(files, :symbolize_names => true)

    ok = true
    files.each do |audio|
      saved_audio = AudioFile.find(audio[:id])
      ok = ok && saved_audio.update(audio)
    end
    
    if ok
      render json: {success: true}, status: :accepted
    else
      render json: {success: false}, status: :ok
    end
  end

  private

  def on_audio_uploaded
    @audio_file.update_attribute(:audio_file, params[:key])
  end

  def audio_file_params
    params.permit(:id, :name, :training_session_id, :audio_file, :iv, :audio_files)
  end
end
