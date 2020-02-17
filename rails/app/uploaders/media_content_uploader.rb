class MediaContentUploader < CarrierWave::Uploader::Base
  # Uploader for content of type Medium
  
  alias_method :extension_white_list, :extension_whitelist

  after :store, :set_model_filename

  # Include RMagick or MiniMagick support:
  # include CarrierWave::RMagick
  # include CarrierWave::MiniMagick

  # Choose what kind of storage to use for this uploader:
  if Rails.env.ends_with?("local") || Rails.env.test? || Rails.env.development_remote?
    storage :file
    # Override the directory where uploaded files will be stored.
    # This is a sensible default for uploaders that are meant to be mounted:
    # def store_dir
    #   "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
    # end
  else
    include CarrierWaveDirect::Uploader
  end

  process :save_content_metadata_in_model

  def save_content_metadata_in_model
    model.size = file.size
  end
  
  def store_dir
    "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{dirname}"
  end

  def dirname
    return model.id
  end

  # Override the filename of the uploaded files:
  # Avoid using model.id or version_name here, see uploader/store.rb for details.
  def filename
    if original_filename.nil?
      # This happens when the uploader is empty, no file uploaded
      @name = nil
    else
      @name = "#{model.id}#{File.extname(original_filename)}"
    end
    return @name
  end

  # Provide a default URL as a default if there hasn't been a file uploaded:
  def default_url(*args)
    # For Rails 3.1+ asset pipeline compatibility:
    # ActionController::Base.helpers.asset_path("fallback/" + [version_name, "default.png"].compact.join('_'))
  
    "#{ENV['SERVER_IP']}/icons/media_icon.png"
  end

  private
  
  def set_model_filename(file)
    # Carrierwave automatically set the filename param, override it
    model.update!(filename: @name)
  end

  def size_range
    # 1 Byte to 50 MB
    1..50.megabytes
  end

  # Process files as they are uploaded:
  # process scale: [200, 300]
  #
  # def scale(width, height)
  #   # do something
  # end

  # Create different versions of your uploaded files:
  # version :thumb do
  #   process resize_to_fit: [50, 50]
  # end

  # Add a white list of extensions which are allowed to be uploaded.
  # For images you might use something like this:
  # def extension_whitelist
  #   %w(jpg jpeg gif png)
  # end

end
