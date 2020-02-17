class Api::V1::PersonalFilesController < ApplicationController
  require 'streamio-ffmpeg'

  # Since there isn't a PersonalFile model, Cancancan can't process this controller
  # Make it available to all users
  skip_authorize_resource

  # Here we are using the filename as an id. There cannot be collisions since we doesn't consider subdirectories.
  def show
    original_name = URI.decode(file_params[:id])
    # For videos and audios send the file.
    case File.extname(original_name)
      when ".mp4" || ".mp3" || ".wav"
        file_name = Rails.root.join(ENV["PERSONAL_IMAGES_PATH"], original_name)
        if File.exists?(file_name)
          mime_type = Rack::Mime.mime_type(File.extname(original_name))
          send_file file_name, :type => mime_type, :disposition => 'inline'
          return
        end
      else # For images send the base64.
        file_name = Rails.root.join(ENV["PERSONAL_IMAGES_PATH"], original_name)
        if File.exists?(file_name)
          mime_type = Rack::Mime.mime_type(File.extname(original_name))
          base64 = Base64.encode64(open(file_name) { |io| io.read })
          render json:{id: file_params[:id], data: base64, mime: mime_type}
          return
        end
    end
    
    render json: {errors: ["#{I18n.t :error_image_not_found}."]}, status: :not_found
  end

  # By default look for images and video only. If requested look for audio, images or video only.
  def index
    files = {}
    if file_params[:file_type].blank?
      files = get_images_and_video_files
    end
    if file_params[:file_type] == "audio"
      files = get_audio_files
    end
    if file_params[:file_type] == "video"
      files = get_video_files
    end
    if file_params[:file_type] == "image"
      files = get_image_files
    end
    # Pagination is done in get_images_and_video_files method.
    render json: files, adapter: nil, status: :ok
  end

  private

  # File::FNM_CASEFOLD is not well documented. It allows Ruby to look for files (and extensions) in a case-insensitive way.
  def get_images_and_video_files
    image_names = Dir.glob("#{ENV["PERSONAL_IMAGES_PATH"]}/processed/*.{jpg,jpeg,png,bmp,gif}", File::FNM_CASEFOLD).select{|file| FileTest.file?(file)}.map{ |file| File.basename file }
    video_names = Dir.glob("#{ENV["PERSONAL_IMAGES_PATH"]}/*.{mp4}", File::FNM_CASEFOLD).select{|file| FileTest.file?(file)}.map{ |file| File.basename file }
    file_names = []
    image_names.each do |image|
      file_names.push(image.dup)
    end
    video_names.each do |video|
      file_names.push(video.dup)
    end
    file_names = file_names.sort_by{|name| name}
    file_names = paginate file_names
    files = []

    file_names.each do |file_name|
      original_name = file_name
      only_name = File.basename(original_name, File.extname(original_name))
      case File.extname(file_name)
        when ".mp4"
          # Videos
          file_name = Rails.root.join(ENV["PERSONAL_IMAGES_PATH"], file_name)
          thumbnail_name = Rails.root.join(ENV["PERSONAL_IMAGES_PATH"],"video_thumbnails","#{only_name}.jpg")
          if File.exists?(file_name) && File.exists?(thumbnail_name)
            mime_type = Rack::Mime.mime_type(File.extname(file_name))
            base64 = Base64.encode64(open(thumbnail_name) { |io| io.read })
            movie = FFMPEG::Movie.new(file_name.to_s)
            duration = movie.duration.round
            minutes = duration / 60
            seconds = duration % 60
            duration = format("%02d:%02d", minutes, seconds)
            file = {id: URI.encode(original_name), name: original_name, data: base64, mime: mime_type, duration: duration}
            files.push(file)
          end
        else
          # Images
          file_name = Rails.root.join(ENV["PERSONAL_IMAGES_PATH"], "processed", "thumbnails", "thumb_#{file_name}")
          if File.exists?(file_name)
            mime_type = Rack::Mime.mime_type(File.extname(file_name))
            base64 = Base64.encode64(open(file_name) { |io| io.read })
            file = {id: URI.encode(original_name), name: original_name, data: base64, mime: mime_type}
            files.push(file)
          end
      end
    end
    return files
  end

  def get_video_files
    video_names = Dir.glob("#{ENV["PERSONAL_IMAGES_PATH"]}/*.{mp4}", File::FNM_CASEFOLD).select{|file| FileTest.file?(file)}.map{ |file| File.basename file }
    file_names = []
    video_names.each do |video|
      file_names.push(video.dup)
    end
    file_names = file_names.sort_by{|name| name}
    file_names = paginate file_names
    files = []

    file_names.each do |file_name|
      original_name = file_name
      only_name = File.basename(original_name, File.extname(original_name))
      file_name = Rails.root.join(ENV["PERSONAL_IMAGES_PATH"], file_name)
      thumbnail_name = Rails.root.join(ENV["PERSONAL_IMAGES_PATH"],"video_thumbnails","#{only_name}.jpg")
      if File.exists?(file_name) && File.exists?(thumbnail_name)
        mime_type = Rack::Mime.mime_type(File.extname(file_name))
        base64 = Base64.encode64(open(thumbnail_name) { |io| io.read })
        movie = FFMPEG::Movie.new(file_name.to_s)
        duration = movie.duration.round
        minutes = duration / 60
        seconds = duration % 60
        duration = format("%02d:%02d", minutes, seconds)
        file = {id: URI.encode(original_name), name: original_name, data: base64, mime: mime_type, duration: duration}
        files.push(file)
      end
    end
    return files
  end

  def get_image_files
    image_names = Dir.glob("#{ENV["PERSONAL_IMAGES_PATH"]}/processed/*.{jpg,jpeg,png,bmp,gif}", File::FNM_CASEFOLD).select{|file| FileTest.file?(file)}.map{ |file| File.basename file }
    file_names = []
    image_names.each do |image|
      file_names.push(image.dup)
    end
    file_names = file_names.sort_by{|name| name}
    file_names = paginate file_names
    files = []

    file_names.each do |file_name|
      original_name = file_name
      file_name = Rails.root.join(ENV["PERSONAL_IMAGES_PATH"], "processed", "thumbnails", "thumb_#{file_name}")
      if File.exists?(file_name)
        mime_type = Rack::Mime.mime_type(File.extname(file_name))
        base64 = Base64.encode64(open(file_name) { |io| io.read })
        file = {id: URI.encode(original_name), name: original_name, data: base64, mime: mime_type}
        files.push(file)
      end
    end
    return files
  end

  def get_audio_files
    audio_names = Dir.glob("#{ENV["PERSONAL_IMAGES_PATH"]}/*.{mp3,wav}", File::FNM_CASEFOLD).select{|file| FileTest.file?(file)}.map{ |file| File.basename file }
    audio_names = audio_names.sort_by{|name| name}
    file_names = paginate audio_names
    files = []
    
    file_names.each do |file_name|
      original_name = file_name
      only_name = File.basename(original_name, File.extname(original_name))
      file_name = Rails.root.join(ENV["PERSONAL_IMAGES_PATH"], file_name)
      if File.exists?(file_name)
        mime_type = Rack::Mime.mime_type(File.extname(file_name))
        file = {id: URI.encode(original_name), name: only_name, mime: mime_type}
        files.push(file)
      end
    end
    return files
  end

  def file_params
    params.permit(:id, :file_type)
  end
end
