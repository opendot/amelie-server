class PackageUploader < CarrierWave::Uploader::Base
  # Uploader for package, a zip file holding all objects and contents related to some sessions
  
  alias_method :extension_white_list, :extension_whitelist

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
  
  def store_dir
    "uploads/package"
  end

  def fog_authenticated_url_expiration
    # On Amazon S3, files will be removed after 4 days
    # If you change this value, you must change the Expiration rule too
    # Use a small time to test if the link expires
    2.days
  end

  private

  def size_range
    # 1 Byte to 2048 MB
    1..2048.megabytes
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
  def extension_whitelist
    %w(zip)
  end

  # Override the filename of the uploaded files:
  # Avoid using model.id or version_name here, see uploader/store.rb for details.
  def filename
    original_filename
  end

end
