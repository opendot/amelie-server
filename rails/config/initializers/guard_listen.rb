Rails.application.config.after_initialize do
  # Listen to file edits on personal_files folder

  if Rails.env.ends_with?("local") && ENV["PROCESS_PERSONAL_FILES"]

    # check if personal_files folder exists
    needed_path = Rails.root.join("personal_files")
    unless File.directory?(needed_path)
      FileUtils.mkdir_p(needed_path)
    end

    # Listen on personal_files folder, ignore files inside the support folders
    listener = Listen.to("personal_files", force_polling: true, ignore: [%r{processed/}, %r{video_thumbnails/}]) do |modified, added, removed|
      # When files change, process all the personal files

      # Get the list of files in the personal images folder
      files = PersonalFile.files
      processed_files = PersonalFile.processed_files
      thumbnails_files = PersonalFile.thumbnails_files
      videos = PersonalFile.videos
      video_thumbnails = PersonalFile.video_thumbnails
      original_video_thumbnails = video_thumbnails.dup
    
      # Find files that were processed but then have been removed by the user.
      # Will be the ones left in processed_files and thumbnails_files arrays.
      PersonalFile.delete_removed_files( files, processed_files, thumbnails_files)
    
      # If one of them hasn't been processed yet, process it
      PersonalFile.process_files( files )

      # Find video thumbnails whose video has been deleted
      # Will be the ones left in video_thumbnails array.
      PersonalFile.delete_video_thumbanils_of_removed_files( videos, video_thumbnails, original_video_thumbnails)

      # Create a folder with various video thumbnails for each video
      # Consider the first 30 seconds of every video.
      # If a video is shorter, some images will not be generated
      PersonalFile.create_video_thumbnails(videos, video_thumbnails)

    end
    listener.start

  end
end