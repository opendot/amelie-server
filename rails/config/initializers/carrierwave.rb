CarrierWave.configure do |config|
  
  if Rails.env.production_remote? || Rails.env.staging_remote?
    config.fog_credentials = {
        provider:               "AWS",
        region:                 ENV['AWS_REGION'],
        use_iam_profile: true,
    }

    config.fog_directory  = ENV['AWS_BUCKET']
    config.fog_public     = false

    config.fog_authenticated_url_expiration = 7200
    config.validate_filename_format = false

  else
    # Development environment
    config.asset_host = proc do |file|
      $SERVER_IP
    end
  end

end