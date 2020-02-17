class PersonalFile
  # Class used to store the methods to process files in the personal_files folder


  def self.video_thumbnails_path
    "#{ENV["PERSONAL_IMAGES_PATH"]}/video_thumbnails"
  end

  def self.video_thumbnails_temp_path
    "#{ENV["PERSONAL_IMAGES_PATH"]}/video_thumbnails/temp"
  end

  # Get the list of files in the personal images folder
  def self.files
    Dir.glob("#{ENV["PERSONAL_IMAGES_PATH"]}/*.{jpg,jpeg,png,bmp,gif}", File::FNM_CASEFOLD).select{|file| FileTest.file?(file)}.map{ |file| File.basename file }
  end

  def self.processed_files
    Dir.glob("#{ENV["PERSONAL_IMAGES_PATH"]}/processed/*.{jpg,jpeg,png,bmp,gif}", File::FNM_CASEFOLD).select{|file| FileTest.file?(file)}.map{ |file| File.basename file }
  end

  def self.thumbnails_files
    Dir.glob("#{ENV["PERSONAL_IMAGES_PATH"]}/processed/thumbnails/*.{jpg,jpeg,png,bmp,gif}", File::FNM_CASEFOLD).select{|file| FileTest.file?(file)}.map{ |file| File.basename file }
  end

  def self.videos
    Dir.glob("#{ENV["PERSONAL_IMAGES_PATH"]}/*.{mp4}", File::FNM_CASEFOLD).select{|file| FileTest.file?(file)}.map{ |file| File.basename file }
  end

  def self.video_thumbnails
    Dir.glob("#{video_thumbnails_path}/*.{jpg}", File::FNM_CASEFOLD).select{|file| FileTest.file?(file)}.map{ |file| File.basename file }
  end


  def self.delete_removed_files( files, processed_files, thumbnails_files)
    # Find files that were processed but then have been removed by the user.
    # Will be the ones left in processed_files and thumbnails_files arrays.
    files.each do |file|
      processed_files.delete(file)
      thumbnails_files.delete("thumb_#{file}")
    end
  
    # Now delete them
    processed_files.each do |file|
      File.delete("#{ENV["PERSONAL_IMAGES_PATH"]}/processed/#{file}")
    end
    thumbnails_files.each do |file|
      File.delete("#{ENV["PERSONAL_IMAGES_PATH"]}/processed/thumbnails/#{file}")
    end
  end

  def self.process_files( files )
    # If one of them hasn't been processed yet, process it
    uploader = PersonalImageUploader.new
    files.each do |file_name|
      original_path = File.join(Rails.root, "personal_files", file_name)
      full_path = File.join(Rails.root, "personal_files", "processed", file_name)
      unless File.file?(full_path)
        file = File.open(original_path)
        uploader.store_with_name!(file, file_name)
      end
    end
  end

  def self.delete_video_thumbanils_of_removed_files( videos, video_thumbnails, original_video_thumbnails)
    # Find video thumbnails whose video has been deleted
    # Will be the ones left in video_thumbnails array.
    videos.each do |file|
      video_thumbnails.delete("#{File.basename(file, File.extname(file))}.jpg")
    end

    # Now delete them
    video_thumbnails.each do |file|
      File.delete("#{ENV["PERSONAL_IMAGES_PATH"]}/video_thumbnails/#{file}")
    end

    # Find videos without a thumbnail
    original_video_thumbnails.each do |file|
      videos.delete("#{File.basename(file, File.extname(file))}.mp4")
    end
  end

  def self.create_video_thumbnails(videos, video_thumbnails)
    # Create a folder with various video thumbnails for each video
    # Consider the first 30 seconds of every video.
    # If a video is shorter, some images will not be generated
    video_thumbnails_path = self.video_thumbnails_path()
    video_thumbnails_temp_path = self.video_thumbnails_temp_path()

    FileUtils.mkdir_p(video_thumbnails_path) unless File.directory?(video_thumbnails_path)
    FileUtils.mkdir_p(video_thumbnails_temp_path) unless File.directory?(video_thumbnails_temp_path)
    videos.each do |file|
      system('ffmpeg -ss 1 -i "' + "#{ENV["PERSONAL_IMAGES_PATH"]}/#{file}" + '" -t 1 -vf scale=-1:192' + " '#{video_thumbnails_temp_path}/#{File.basename(file, File.extname(file))}%01d.jpg'")
      system('ffmpeg -ss 5 -i "' + "#{ENV["PERSONAL_IMAGES_PATH"]}/#{file}" + '" -t 1 -vf scale=-1:192' + " '#{video_thumbnails_temp_path}/#{File.basename(file, File.extname(file))}%02d.jpg'")
      system('ffmpeg -ss 10 -i "' + "#{ENV["PERSONAL_IMAGES_PATH"]}/#{file}" + '" -t 1 -vf scale=-1:192' + " '#{video_thumbnails_temp_path}/#{File.basename(file, File.extname(file))}%03d.jpg'")
      system('ffmpeg -ss 15 -i "' + "#{ENV["PERSONAL_IMAGES_PATH"]}/#{file}" + '" -t 1 -vf scale=-1:192' + " '#{video_thumbnails_temp_path}/#{File.basename(file, File.extname(file))}%04d.jpg'")
      system('ffmpeg -ss 20 -i "' + "#{ENV["PERSONAL_IMAGES_PATH"]}/#{file}" + '" -t 1 -vf scale=-1:192' + " '#{video_thumbnails_temp_path}/#{File.basename(file, File.extname(file))}%05d.jpg'")
      system('ffmpeg -ss 25 -i "' + "#{ENV["PERSONAL_IMAGES_PATH"]}/#{file}" + '" -t 1 -vf scale=-1:192' + " '#{video_thumbnails_temp_path}/#{File.basename(file, File.extname(file))}%06d.jpg'")

      created_files = []
      video_thumbs = Dir.glob("#{video_thumbnails_temp_path}/*.{jpg}", File::FNM_CASEFOLD).select{|single| FileTest.file?(single)}.map{ |single| File.basename single }

      # Get all the created thumbnails
      video_thumbs.each do |thumb|
        size = File.stat("#{video_thumbnails_temp_path}/#{thumb}").size
        name = thumb
        created_files.push({size: size, name: name})
      end

      # Find the biggest file
      biggest = created_files.first
      created_files.each do |temp|
        if temp[:size] > biggest[:size]
          biggest = temp
        end
      end

      # Remove the biggest from the list
      created_files.delete(biggest)

      # Delete the remaining files
      created_files.each do |temp|
        FileUtils.rm("#{video_thumbnails_temp_path}/#{temp[:name]}")
        video_thumbnails.delete(temp[:name])
      end

      # Rename the unique remained file like the video
      FileUtils.mv("#{video_thumbnails_temp_path}/#{biggest[:name]}", "#{video_thumbnails_path}/#{File.basename(file, File.extname(file))}.jpg")
    end
    FileUtils.remove_dir(video_thumbnails_temp_path)
  end

end