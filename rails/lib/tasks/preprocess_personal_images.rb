# This isn't used. Check Airett.rake.

namespace :airett do
  
  desc "Preprocesses the personal images"
  task preprocess_personal_images: :environment do
    
    # Get the list of files in the personal images folder
    files = Dir.glob("#{ENV["PERSONAL_IMAGES_PATH"]}/*.{jpg,jpeg,png,bmp,gif}", File::FNM_CASEFOLD).select{|file| FileTest.file?(file)}.map{ |file| File.basename file }
    processed_files = Dir.glob("#{ENV["PERSONAL_IMAGES_PATH"]}/processed/*.{jpg,jpeg,png,bmp,gif}", File::FNM_CASEFOLD).select{|file| FileTest.file?(file)}.map{ |file| File.basename file }
    thumbnails_files = Dir.glob("#{ENV["PERSONAL_IMAGES_PATH"]}/processed/thumbnails/*.{jpg,jpeg,png,bmp,gif}", File::FNM_CASEFOLD).select{|file| FileTest.file?(file)}.map{ |file| File.basename file }
  
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

end
