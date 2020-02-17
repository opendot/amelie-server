class VideoContentUploader < MediaContentUploader
  include CarrierWave::Video  # for your video processing
  include CarrierWave::Video::Thumbnailer

  # Create a thumbnail version
  version :thumb do
    process thumbnail: [{format: 'jpg', quality: 9, size: 192, logger: Rails.logger}]
    def full_filename(for_file = model.content.file)
      "thumb_#{model.id}.jpg"
    end 
  end

  # Add a white list of extensions which are allowed to be uploaded.
  def extension_whitelist
    %w(mp4)
  end

  process :save_content_metadata_in_model

  def save_content_metadata_in_model
    super
    # This may cause problems while seeding test db
    unless Rails.env.starts_with?("test")
      movie = FFMPEG::Movie.new(file.path)
      model.duration = movie.duration
    end
  end

  # Provide a default URL as a default if there hasn't been a file uploaded:
  def default_url(*args)
    # For Rails 3.1+ asset pipeline compatibility:
    # ActionController::Base.helpers.asset_path("fallback/" + [version_name, "default.png"].compact.join('_'))
    nil
  end

end
