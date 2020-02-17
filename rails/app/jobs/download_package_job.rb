class DownloadPackageJob < ApplicationJob
  # Create a zip file holding all objects and files related to
  # some random sessions of some random patients, and send an email
  # with a link to download the zip
  # WARNING when using docker-compose.multiple.yml, this job will run in sidekiq_local
  queue_as :default

  rescue_from(Exception) do |exception|
    PackageMailer.with(
      current_user: @user,
      error_message: exception.message,
      error_full_message: exception.full_message,
    ).generic_error.deliver_later
  end

  def perform(current_user, num_patients, num_sessions, patient_region = nil, session_type = nil, with_eyetracker_data = false)
    num_patients = 5 if num_patients.nil?
    num_sessions = 5 if num_sessions.nil?
    @user = current_user # Define user variable for rescue_from

    package = Package.new(num_patients, num_sessions, patient_region, session_type, with_eyetracker_data)
    sessions = package.get_sessions

    # Write sessions on file
    sessions_objects, content_ids, cards_play_sound_ids = Package.write_on_file(sessions)

    # Create zip file
    zipfile_name, download_errors = Package.create_zip_with_sessions(current_user, sessions_objects, content_ids, cards_play_sound_ids)

    # Upload zip file to storage
    begin
      package.upload_zip(zipfile_name)
    rescue CarrierWave::UploadError => upload_error
      # Send an email with the message
      PackageMailer.with(
        current_user: current_user,
        error_message: upload_error.message,
        error_full_message: upload_error.full_message,
      ).carrierwave_upload_error.deliver_later
      return
    end

    # Generate link to download zip file, valid for 1 day
    # PackageUploader has a different expiration time from other uploaders
    temporary_url = package.temporary_url

    # Send email with link to zip file
    PackageMailer.with(
      current_user: current_user,
      temporary_url: temporary_url,
      expiration_days: package.zip_uploader.fog_authenticated_url_expiration.to_i/ActiveSupport::Duration::SECONDS_PER_DAY
    ).created_package.deliver_later

    check_download_errors(download_errors)

    # Delete zip
    if File.exists?(zipfile_name)
      File.delete(zipfile_name)
    end

  end

  # Notify if some files couldn't be downloaded
  def check_download_errors(download_errors)
    unless download_errors[:contents].empty? && download_errors[:cards].empty? && download_errors[:audio_file].empty?
      PackageMailer.with(
        current_user: @user,
        error_message: I18n.t("errors.packages.download_recources"),
        error_full_message: JSON.pretty_generate(download_errors),
      ).generic_error.deliver_later
    end
  end

end
