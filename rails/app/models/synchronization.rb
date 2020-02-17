class Synchronization < ApplicationRecord
  extend ModelStringConverter
  include Retryable
  
  belongs_to :user
  default_scope { order(:created_at) }

  scope :completed, -> {where(ongoing: false)}
  scope :successful, -> {where(success: true)}
  scope :up, -> {where(direction: "up")}
  scope :down, -> {where(direction: "down")}

  scope :last_completed, -> (direction){where(direction: direction).where(start)}
  scope :failed, -> (patient_iddirection){where(success: false, direction: direction).where(start)}

  def new
    @patient_id = nil
    @content_ids = []
    @training_sessions_ids = []
    @pages_ids = []
    @cards_ids = []
  end

  def complete(result)
    self.update!(success: result, ongoing: false, completed_at: DateTime.now)
  end

  def self.last_completed(patient_id, direction)
    where(success: true, ongoing: false, direction: direction, patient_id: patient_id).order(completed_at: :asc).last
  end

  # Return the last failed synch after the last successful synch
  def self.failed(patient_id, direction)
    last_completed = Synchronization.last_completed(patient_id, direction)
    failed_synch = Synchronization.where(success: false, ongoing: false, direction: direction, patient_id: patient_id)
    unless last_completed.nil?
      failed_synch = failed_synch.where("started_at > ?", last_completed.started_at)
    end
    failed_synch.last
  end

  # Create a file containing all the changes
  def collect_changes(last_sync_date, current_user, patient_id, insert_files_urls = false)

    # This keeps track of the contents that in a second time needs to be synced
    @content_ids = []
    @cards_play_sound_ids = []
    @training_sessions_ids = []
    @trees_ids = []
    @pages_ids = []
    @cards_ids = []
    @patient_id = patient_id
    
    # Write everything in a file
    Dir.mkdir("private") unless Dir.exist?("private")
    File.open(Rails.root.join("private/upload_#{current_user[:id]}.rb"), "w") do |file|
    
      # Don't need to sync tags having overridden the create method of cards and tags.
      # Just need to send tags as a vector of strings inside cards.

      # # Create tags
      # file.puts "# New tags"
      # Tag.where("DATE(updated_at) > ?", last_sync_date).find_in_batches do |tags|
      #   file.puts "<Tag>"
      #   file.puts tags.to_json
      # end
      # file.puts ""

      # Create tags
      file.puts "# New tags"
      Tag.where.not(type: "CardTag").not_sync(last_sync_date).find_in_batches do |tags|
        file.puts "<Tag>"
        file.puts tags.to_json
      end
      file.puts ""

      # Create training sessions
      file.puts "# New training sessions"
      TrainingSession.not_sync(last_sync_date).for_patient(patient_id).find_in_batches do |training_sessions|
        @training_sessions_ids.push(*training_sessions.collect{|session| session[:id]})
        file.puts "<TrainingSession>"
        file.puts training_sessions.to_json
      end
      file.puts ""

      # Create audio files
      file.puts "# New audio files"
      AudioFile.where(training_session_id: @training_sessions_ids).find_in_batches do |audio_files|
        file.puts "<AudioFile>"
        audios = []
        audio_files.each do |a|
          audio = a.attributes
          audio.delete(:audio_file)
          if insert_files_urls
            audio[:remote_audio_file_url] = a.audio_file.url
          end
          audios.push(audio)
        end
        file.puts "#{audios.to_json}"
      end
      file.puts ""

      # Create calibrations
      file.puts "# New tracker calibration parameters"
      TrackerCalibrationParameter.not_sync(last_sync_date).for_patient(patient_id).find_in_batches do |calibrations|
        file.puts "<TrackerCalibrationParameter>"
        file.puts calibrations.to_json
      end
      file.puts ""

      # Create custom cards
      file.puts "# New cards and contents"
      Card.write_on_file(file, Card.not_sync(last_sync_date).where(type: %w(ArchivedCard CustomCard)).for_patient(patient_id), @content_ids, @cards_play_sound_ids, insert_files_urls)
      file.puts ""

      # Other cards with patient_id nil
      card_types = %w(PresetCard)
      # Create custom cards
      file.puts "# New cards with patient_id nil and contents"
      Card.write_on_file(file, Card.not_sync(last_sync_date).where(:type => card_types).for_patient(nil), @content_ids, @cards_play_sound_ids, insert_files_urls)
      file.puts ""

      # Create pages
      file.puts "# New pages"
      Page.where.not(type: "FeedbackPage").not_sync(last_sync_date).for_patient([patient_id, nil]).find_in_batches do |pages|
        @pages_ids.push(*pages.collect{|p| p[:id]})
        file.puts "<Page>"
        file.puts pages.to_json
      end
      file.puts ""

      # Create feedback pages
      file.puts "# New feedback pages"
      FeedbackPage.not_sync(last_sync_date).for_patient([patient_id, nil]).find_in_batches do |feedback_pages|
        @pages_ids.push(*feedback_pages.collect{|p| p[:id]})
        file.puts "<FeedbackPage>"
        file.puts feedback_pages.to_json
      end
      file.puts ""

      # Create page layouts
      
      PageLayout.where(page_id: @pages_ids).find_in_batches do |page_layouts|
        @cards_ids.push(*page_layouts.collect{|p| p[:card_id]})

        # Create cards belonging to trees. Ideally these are all ArchivedCards.
        file.puts "# Cards of trees"
        Card.write_on_file(file, Card.where(id: @cards_ids), @content_ids, @cards_play_sound_ids, insert_files_urls)
        file.puts ""
        
        file.puts "# New page layouts"
        file.puts "<PageLayout>"
        file.puts page_layouts.to_json
        file.puts ""
      end
      

      # Create trees
      file.puts "# New trees"
      Tree.not_sync(last_sync_date).for_patient(patient_id).where.not(type: "PreviewTree").find_in_batches do |trees|
        @trees_ids.push(*trees.collect{|p| p[:id]})
        file.puts "<Tree>"
        file.puts trees.to_json
      end
      file.puts ""

      # Create UserTrees
      file.puts "# New user_trees"
      UserTree.where(user_id: current_user[:id]).where(:tree_id => @trees_ids).find_in_batches do |user_trees|
        file.puts "<UserTree>"
        file.puts user_trees.to_json
      end
      file.puts ""

      # Create session events
      file.puts "# New session events"
      SessionEvent.where(training_session_id: @training_sessions_ids).find_in_batches do |events|
        file.puts "<SessionEvent>"
        file.puts events.to_json
      end
      file.puts ""

      # Cognitive Session objects
      synchronizables = %w(Level Box Target)
      synchronizables.each do |synchronizable|
        file.puts "# New #{synchronizable}"
        query = synchronizable.constantize.not_sync(last_sync_date)
        query.find_in_batches do |object_array|
          file.puts "<#{synchronizable}>"
          file.puts object_array.to_json
        end
        file.puts ""
      end

      file.puts "# New exercise trees and archived exercise trees"
      query = Tree.not_sync(last_sync_date).for_patient(nil)
      query.find_in_batches do |object_array|
        file.puts "<#{Tree}>"
        file.puts object_array.to_json
      end
      file.puts ""

      # Availables
      synchronizables_cognitive_availables = %w(AvailableBox AvailableExerciseTree AvailableLevel AvailableTarget)
      synchronizables_cognitive_availables.each do |synchronizable|
        file.puts "# New #{synchronizable}"
        query = synchronizable.constantize.not_sync(last_sync_date).for_patient(nil)

        query.find_in_batches do |object_array|
          file.puts "<#{synchronizable}>"
          file.puts object_array.to_json
        end
        file.puts ""
      end

      synchronizables_cognitive_availables.each do |synchronizable|
        file.puts "# New #{synchronizable}"
        query = synchronizable.constantize.not_sync(last_sync_date).for_patient(patient_id)

        query.find_in_batches do |object_array|
          file.puts "<#{synchronizable}>"
          file.puts object_array.to_json
        end
        file.puts ""
      end

      # Other Synchronizable objects, that have a patient_id nil
      synchronizables_without_patient = %w()
      synchronizables_without_patient.each do |synchronizable|
        file.puts "# New #{synchronizable}"
        query = synchronizable.constantize.not_sync(last_sync_date).for_patient(nil)

        query.find_in_batches do |object_array|
          file.puts "<#{synchronizable}>"
          file.puts object_array.to_json
        end
        file.puts ""
      end

      # Other Synchronizable objects, listed in order of creation
      # WARNING, don't put in the list objects that have a patient_id but it can be null, like Tree and ExerciseTree
      synchronizables = %w(BoxLayout TargetLayout Badge TrackerRawDatum)
      synchronizables.each do |synchronizable|
        file.puts "# New #{synchronizable}"
        query = synchronizable.constantize.not_sync(last_sync_date)
        if synchronizable.constantize.column_names.include? "patient_id"
          query = query.for_patient(patient_id)
        end
        query.find_in_batches do |object_array|
          file.puts "<#{synchronizable}>"
          file.puts object_array.to_json
        end
        file.puts ""
      end
      
    end
  end

  def self.apply_edits(data)
    what = nil
    objects = nil
    # count = 0
    # Delete UserTree entries related to ArchivedTrees
    UserTree.joins(:tree).where(trees: {type: "ArchivedTree"}).destroy_all

    data.lines.each do |line|
      line = line.strip

      # Ignore comments
      next if line.start_with?('#')
      # Ignore empty lines
      next if line.empty?
      # If starts with "<" and ends with ">" is a class type. Just need to set the type we are working with.
      if line.start_with?('<') && line.ends_with?('>')
        what = line[1..-2]
        next
      end

      logger.debug "Applying edits for line: #{line}"

      # A single line contains a whole array of objects
      objects, ids = extract_array_from(line)

      # Find objects that already exist
      existent, non_existent = split_existent_and_non(what, objects, ids)

      # Actually used only by UserTree entries. Update what already exists.
      what.constantize.update_from_array(existent)

      non_existent.each do |record|
        # puts "*********************************************************************"
        if %w(TransitionToPageEvent TransitionToEndEvent TransitionToPresentationPageEvent TransitionToFeedbackPageEvent TransitionToIdleEvent).include? record[:type]
          record.merge!({skip_broadcast_callback: true})
        end
        if what == "Tree" && record[:type] == "ExerciseTree"
          record.merge!({:skip_default_available => true})
        end
        # obj = what.constantize.create(record)
        # obj.save!
        # puts created.inspect
        # puts "*********************************************************************"
        # puts ""
        # count += 1
      end
      what.constantize.create_from_array(non_existent)

    end
    # puts ""
    # puts ""
    # puts ""
    # puts "----------------------------------    COUNT    ---------------------------------"
    # puts count
  end

  # Returns new audio files
  # NOTE: this method works only if called after collect_changes
  def get_new_audio_files
    return AudioFile.where(training_session_id: @training_sessions_ids)
  end

  # Returns new contents
  # NOTE: this method works only if called after collect_changes
  def get_new_contents
    return Content.where(id: @content_ids)
  end

  # Returns new cards with a selection sound (selection_action: :play_sound)
  # NOTE: this method works only if called after collect_changes
  def get_new_cards_play_sound
    return Card.where(id: @cards_play_sound_ids)
  end

  def created_at_string
    self.created_at.utc.strftime("%Y-%m-%dT%H:%M:%S%:z")
  end

  def started_at_string
    self.started_at.utc.strftime("%Y-%m-%dT%H:%M:%S%:z")
  end

  def completed_at_string
    self.completed_at.utc.strftime("%Y-%m-%dT%H:%M:%S%:z")
  end

  def upload_files(headers, response_code, cipher, audio_files, new_contents, cards_play_sound)
    patient_id = self.patient_id
    iv = nil
    debug = true

    logger.debug "Start audio..." if debug
    # Now send contents and audios, 5 at a time
    audio_files.find_in_batches(batch_size: 3) do |group|

      # Cipher initialization
      cipher = cipher.reset
      cipher.encrypt
      cipher.key = ENV["SYNC_ENCRYPTION_KEY"]
      iv = cipher.random_iv

      audios = []
      group.each do |a|
        audio64 = nil
        unless a.audio_file.nil? || !a.audio_file || !a.audio_file.url || a.audio_file.url.nil?
          audio64 = Base64.encode64(a.audio_file.read)
          mime_type = a.audio_file.url.ends_with?(".weba") ? "audio/webm" : Rack::Mime.mime_type(File.extname(a.audio_file.url))
          audio64 = "data:#{mime_type};base64," + audio64
        end
        audio = {}
        audio[:id] = a[:id]
        audio[:audio_file] = audio64
        audios.push(audio)
      end
      audios = cipher.update(ActiveSupport::Gzip.compress(audios.to_json)) << cipher.final
      begin
        response = nil
        retry_with(delay: 2, delay_sleep: true, delay_inc: true, debug: debug) do
          response = RestClient.put(ENV['ONLINE_SERVER_ADDRESS'] + "/audio_files", {:multipart => true, :audio_files => audios, :iv => iv}, headers)
        end
        if response.code >= 300
          logger.error "Error in synchronization up: AudioFile update, Response\n#{response.inspect}\n Audios:\n#{group.inspect}"
        end
      rescue RestClient::ExceptionWithResponse => err
        logger.error "Error in synchronization up: AudioFile update\n#{err.inspect}\n Audios:\n#{group.inspect}"
        logger.error err.response
      end

      group.each { |a| QueuedSynchronizable.destroy_for(patient_id, a) }
    end

    new_contents.find_in_batches(batch_size: 3) do |group|
      contents = []
      logger.debug "- start group" if debug
      group.each do |c|
        logger.debug "    content #{c[:id]}: #{(c[:size] || 0)/(1024*1024)}MB" if debug
        # Cipher initialization
        cipher = cipher.reset
        cipher.encrypt
        cipher.key = ENV["SYNC_ENCRYPTION_KEY"]
        iv = cipher.random_iv
        content64 = nil
        unless c.content.nil? || !c.content || !c.content.url || c.content.url.nil?
          content64 = Base64.encode64(c.content.read)
          mime_type = Rack::Mime.mime_type(File.extname(c.content.url))
          content64 = "data:#{mime_type};base64," + content64
        end
        thumbnail64 = nil
        unless c.content_thumbnail.nil? || !c.content_thumbnail || !c.content_thumbnail.url || c.content_thumbnail.url.nil?
          thumbnail64 = Base64.encode64(c.content_thumbnail.read)
          mime_type = Rack::Mime.mime_type(File.extname(c.content_thumbnail.url))
          thumbnail64 = "data:#{mime_type};base64," + thumbnail64
        end
        content = {}
        content[:id] = c[:id]
        content[:content] = content64
        content[:content_thumbnail] = thumbnail64
        contents.push(content)
      end
      logger.debug "- end group" if debug
      contents = cipher.update(ActiveSupport::Gzip.compress(contents.to_json)) << cipher.final
      response = nil
      retry_with(delay: 2, delay_sleep: true, delay_inc: true, debug: debug) do
        response = RestClient::Request.execute(method: :put,
          url: ENV['ONLINE_SERVER_ADDRESS'] + "/contents",
          timeout: 1800, 
          headers: headers,
          payload: {:multipart => true, :contents => contents, :iv => iv},
        )
      end
      if response.code >= 300
        logger.error "Error in synchronization up: Content update, Response\n#{response.inspect}\n Contents:\n#{group.inspect}"
      end
      response_code = [response.code, response_code].max

      group.each { |c| QueuedSynchronizable.destroy_for(patient_id, c) }
    end

    logger.debug "Start selection sound..." if debug
    # Send selection sounds to cards
    cards_play_sound.find_in_batches(batch_size: 5) do |group|
      cards = []
      group.each do |c|
        # Cipher initialization
        cipher = cipher.reset
        cipher.encrypt
        cipher.key = ENV["SYNC_ENCRYPTION_KEY"]
        iv = cipher.random_iv
        sound64 = nil
        unless c.selection_sound.nil? || !c.selection_sound || !c.selection_sound.url || c.selection_sound.url.nil?
          sound64 = Base64.encode64(c.selection_sound.read)
          mime_type = c.selection_sound.url.ends_with?(".weba") ? "audio/webm" : Rack::Mime.mime_type(File.extname(c.selection_sound.url))
          sound64 = "data:#{mime_type};base64," + sound64
        end
        card = {}
        card[:id] = c[:id]
        card[:selection_sound] = sound64
        cards.push(card)
      end
      cards = cipher.update(ActiveSupport::Gzip.compress(cards.to_json)) << cipher.final
      response = nil
      retry_with(delay: 2, delay_sleep: true, delay_inc: true, debug: debug) do
        response = RestClient.put(ENV['ONLINE_SERVER_ADDRESS'] + "/cards/selection_sounds", {:multipart => true, :cards => cards, :iv => iv}, headers)
      end
      response_code = [response.code, response_code].max

      group.each { |c| QueuedSynchronizable.destroy_for(patient_id, c) }

    end

    return response_code
    
  end
  
end
