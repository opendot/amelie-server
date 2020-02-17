class PersonalImageUploader < CarrierWave::Uploader::Base
  alias_method :extension_white_list, :extension_whitelist

  # Include RMagick or MiniMagick support:
  # include CarrierWave::RMagick
  include CarrierWave::MiniMagick

  # Choose what kind of storage to use for this uploader:
  if Rails.env.starts_with?("test") || Rails.env.starts_with?("development") || Rails.env.ends_with?("local")
    storage :file
  else
    include CarrierWaveDirect::Uploader
  end
  # storage :fog

  # Provide a default URL as a default if there hasn't been a file uploaded:
  # def default_url(*args)
  #   # For Rails 3.1+ asset pipeline compatibility:
  #   # ActionController::Base.helpers.asset_path("fallback/" + [version_name, "default.png"].compact.join('_'))
  #
  #   "/images/fallback/" + [version_name, "default.png"].compact.join('_')
  # end

  process :save_content_metadata_in_model

  def save_content_metadata_in_model
    unless model.nil?
      # PersonalImageUploader is used also for airett.rake to process the personal_files
      # in that case the model is nil
      model.size = file.size
    end
  end

  # CarrierWave::SanitizedFile remove spaces from name,
  # for personal images I need the thumb version to have
  # the same name of the original file
  def store_with_name!(file, file_name)
    @personal_image_original_filename = file_name
    self.store!(file)
  end

  # Override the directory where uploaded files will be stored.
  # This is a sensible default for uploaders that are meant to be mounted:
  def store_dir
    File.join(Rails.root, "personal_files", "processed")
  end

  # Ensure the uploaded images are at max 1024 x 1024 px.
  process resize_to_fit: [1024, 1024]
  
  # Create a thumbnail version
  version :thumb do
    def store_dir
      File.join(Rails.root, "personal_files", "processed", "thumbnails")
    end

    def filename
      @parent_version.filename || super
    end

    process resize_to_fit: [192, 192]
  end

  def size_range
    1..10.megabytes
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

  # Override the filename of the uploaded files:
  # Avoid using model.id or version_name here, see uploader/store.rb for details.
  def filename
    @personal_image_original_filename || super
  end

end
