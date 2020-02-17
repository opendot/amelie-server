class Package < ActiveModelSerializers::Model
  extend CarrierWave::Mount
  extend CarrierWaveDirect::Mount
  include TimeSpan
  # Class used to let researchers download recorded data of sessions

  attr_accessor :num_patients, :integer
  attr_accessor :num_sessions, :integer
  attr_accessor :patient_region, :string
  attr_accessor :session_type, :array
  attr_accessor :with_eyetracker_data, :boolean

  mount_uploader :zip_uploader, PackageUploader

  def initialize(num_patients, num_sessions, patient_region = nil, session_type = nil, with_eyetracker_data = false)
    self.num_patients = num_patients
    self.num_sessions = num_sessions
    self.patient_region = patient_region
    self.session_type = session_type
    self.with_eyetracker_data = with_eyetracker_data
  end

  def <=>(other)
    self_attrs = [num_patients, num_sessions, patient_region, session_type, with_eyetracker_data]
    other_attrs = [other.num_patients, other.num_sessions, other.patient_region, other.session_type, other.with_eyetracker_data]
    self_attrs <=> other_attrs
  end

  def self.objects_filename
    "package.rb"
  end

  def self.objects_path
    "private/#{Package.objects_filename}"
  end

  # Download a file and return a TempFile object
  def self.download_to_file(uri)
    stream = nil
    num_retry = 5
    num_retry.times do |i|
      begin
        stream = open(uri, "rb")
        break
      rescue OpenURI::HTTPError => ex
        # Sometimes, S3 return 404 not found, wait and retry
        if ex.message == "404 Not Found" && i < num_retry-1
          sleep(5)
        else
          raise ex
        end
      end
    end
    # open() can return a TempFile or a StringIO, see https://stackoverflow.com/a/31527533
    return stream if stream.respond_to?(:path) # Already file-like
  
    # Create a file
    Tempfile.new.tap do |file|
      file.binmode
      IO.copy_stream(stream, file)
      stream.close
      file.rewind
    end
  end

  def get_sessions
    patient_sample = Patient.all

    if self.patient_region
      patient_sample = patient_sample.where(region: self.patient_region)
    end

    patient_sample = patient_sample.pluck(:id).sample(self.num_patients)

    patient_ids = Patient.where(id: patient_sample).ids
    sessions = Package.random_sessions(patient_ids, self.num_sessions, self.session_type, self.with_eyetracker_data)
                   .includes(:session_events, :audio_file, :tracker_raw_data, :tracker_calibration_parameter)

    return sessions
  end

  def self.random_sessions( patient_ids, num_sessions = 5, session_type = nil, with_eyetracker_data = false )
    sessions = TrainingSession.where(:patient_id => patient_ids)

    if session_type and session_type.any?
      sessions = sessions.where(type: session_type)
    end

    if with_eyetracker_data
      sessions = sessions.joins(:tracker_raw_data).distinct
    end

    # Select N random sessions
    return sessions.where(id: sessions.pluck(:id).sample(num_sessions))
  end

  # Given a list of sessions, get all objects related to those sessions
  # and write all them in a file, in the same format used for Synchronization.
  # Return all objects related to the sessions
  def self.write_on_file( sessions )
    Dir.mkdir("private") unless Dir.exist?("private")
    File.open(Rails.root.join(Package.objects_path), "w") do |file|
      # Write all objects in the correct order
      file.puts "# Random Sessions"
      file.puts "<TrainingSession>"
      file.puts sessions.to_json
      file.puts ""

      # Find all elements related to the sessions
      sessions_session_events = SessionEvent.where(:training_session_id => sessions.select(:id))
      sessions_tracker_calibration_params = TrackerCalibrationParameter.where(:training_session_id => sessions.select(:id))
      sessions_tracker_raw_data = TrackerRawDatum.where(:training_session_id => sessions.select(:id))
      sessions_audio_files = AudioFile.where(:training_session_id => sessions.select(:id))
      sessions_pages = Page.where(:id =>sessions_session_events.select(:page_id)).or(Page.where(:id =>sessions_session_events.select(:next_page_id))).includes(:page_tags)
      sessions_page_layouts = PageLayout.where(:page_id => sessions_pages.select(:id))
      sessions_cards = Card.where(:id => sessions_page_layouts.select(:card_id)).includes(:card_tags, :content)
      sessions_tags = Tag.where(:id => sessions_pages.joins(:page_tags).select("tags.id")).or( Tag.where(:id => sessions_cards.joins(:card_tags).select("tags.id")))
      
      # tags
      sessions_tags.find_in_batches do |tags|
        file.puts "<Tag>"
        file.puts tags.to_json
      end
      file.puts ""

      # cards and contents
      content_ids = []
      cards_play_sound_ids = []
      Card.write_on_file(file, sessions_cards, content_ids, cards_play_sound_ids, true)
      file.puts ""

      # Write all elements on file, the order must respect dependencies
      classes = %w(
        Page PageLayout
        SessionEvent TrackerCalibrationParameter TrackerRawDatum AudioFile
      )

      sessions_object = {
        pages: sessions_pages, page_layouts: sessions_page_layouts,
        session_events: sessions_session_events, tracker_calibration_parameters: sessions_tracker_calibration_params, tracker_raw_data: sessions_tracker_raw_data, audio_files: sessions_audio_files,
      }

      sessions_object.each_with_index do |all_elements, index|
        # all_elements = [:page, sessions_pages]
        all_elements[1].find_in_batches do |elements|
          file.puts "<#{classes[index]}>"
          file.puts elements.to_json
        end
        file.puts ""
      end

      sessions_object[:tags] = sessions_tags
      sessions_object[:cards] = sessions_cards
      return sessions_object, content_ids, cards_play_sound_ids

    end
  end

  # Given a list of sessions generated with write_on_file,
  # create a zip file with all objects and files related to sessions
  def self.create_zip_with_sessions(current_user, sessions_objects, content_ids, cards_play_sound_ids)
    folder = Rails.root.join("private")
    input_filenames = [Package.objects_filename]

    zipfile_name = Rails.root.join("private/archive_#{current_user.id}_#{DateTime.now.to_time.to_i}.zip")
    if File.exists?(zipfile_name)
      File.delete(zipfile_name)
    end
    
    # Save the ids of the files that failed
    download_errors = {contents: [], cards: [], audio_file: []}

    Zip::File.open(zipfile_name, Zip::File::CREATE) do |zipfile|
      input_filenames.each do |filename|
        # Two arguments:
        # - The name of the file as it will appear in the archive
        # - The original file, including the path to find it
        zipfile.add(filename, File.join(folder, filename))
      end
      zipfile.mkdir "contents"
      
      # Download all contents
      Content.where(:id => content_ids).each do |content|
        # Download file, add to zip, delete from filesystem
        begin
          folder_name = "contents/#{content.type.underscore}"
          # url is nil for Text
          unless content.content.nil?
            
            data_content = Package.download_to_file(content.content_url)
            zipfile.add( "#{folder_name}/content/#{content.id}/#{content.filename}", data_content)
            data_content.close()
            unless content.content.thumb.nil? || content.content.thumb.url.nil?
              data_content_thumb = Package.download_to_file(content.content.thumb.url)
              zipfile.add( "#{folder_name}/content/#{content.id}/#{content.content.thumb.path.split("/")[-1]}", data_content_thumb)
              data_content_thumb.close()
            end

          end

          unless content.content_thumbnail.nil? || content.content_thumbnail.url.nil?
            data_content_thumbnail = Package.download_to_file(content.content_thumbnail.url)
            zipfile.add( "#{folder_name}/content_thumbnail/#{content.id}/content_thumbnail/#{content.content_thumbnail.path.split("/")[-1]}", data_content_thumbnail)
            data_content_thumbnail.close()
          end
        rescue OpenURI::HTTPError => ex
          puts "\nContent: #{content.id} - #{ex.message}"
          download_errors[:contents].push(content.id)
        end
      end

      # Download all selection sounds
      Card.where(:id => cards_play_sound_ids).each do |card|
        
        begin
          folder_name = "contents/#{card.type.underscore}"

          unless card.selection_sound.nil?
            
            data_sound = Package.download_to_file(card.selection_sound_url)
            zipfile.add( "#{folder_name}/selection_sound/#{card.id}/#{card.selection_sound.path.split("/")[-1]}", data_sound)
            data_sound.close()
          end
        rescue OpenURI::HTTPError => ex
          puts "\nCard: #{card.id} - #{ex.message}"
          download_errors[:cards].push(card.id)
        end
      end

      # Download all AudioFile
      sessions_objects[:audio_files].each do |audio_file|
        begin
          folder_name = "contents/audio_file"
          unless audio_file.audio_file.nil? || audio_file.audio_file.url.nil?
            data_audio = Package.download_to_file(audio_file.audio_file.url)
            zipfile.add( "#{folder_name}/audio_file/#{audio_file.id}/#{audio_file.audio_file.path.split("/")[-1]}", data_audio)
            data_audio.close()
          end
        rescue OpenURI::HTTPError => ex
          puts "\nAudioFile: #{audio_file.id} - #{ex.message}"
          download_errors[:audio_files].push(audio_file.id)
        end
      end
    end

    return zipfile_name, download_errors
  end

  # Upload the zip file
  def upload_zip(zipfile_name)
    self.zip_uploader.store!(File.open(zipfile_name))
  end

  # Generate an url valid only for few days
  def temporary_url
    self.zip_uploader.url
  end

end