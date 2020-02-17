require 'rails_helper'
require 'sidekiq/testing'
require 'shared/signin.rb'

Sidekiq::Testing.fake!

describe Api::V1::SynchronizationsController, :type => :request do
  include_context "signin"

  before(:all) do
    @current_user = User.find("testUser")
    @patient = Patient.find("patient0")
    to_online_server = false
    signin_researcher(to_online_server)
  end

  context "GET new_data" do
    before(:each) do
      # Get all Synchronizable objects
      last_sync = Synchronization.create(user_id: @current_user.id, patient_id: @patient.id, direction: "down", created_at: 1.year.ago)

      get "/new_data?last_sync_date=#{last_sync.created_at_string}&patient_id=#{@patient.id}", headers: @headers

      expect(response).to have_http_status(:ok)

      body = JSON.parse(response.body)
      expect(body).to have_key("file")
      expect(body).to have_key("iv")
      
      # Decode list
      # Cipher initialization
      cipher = OpenSSL::Cipher.new('aes-256-cbc')
      cipher.decrypt
      cipher.key = ENV["SYNC_ENCRYPTION_KEY"]
      cipher.iv = Base64.decode64(body["iv"])

      # decryption and decompression
      @data = ActiveSupport::Gzip.decompress(cipher.update(Base64.decode64(body["file"])) << cipher.final)
    end

    it "is not empty" do
      expect(@data).not_to be_empty
    end

    it "retrieve all objects of the patient" do
      what = nil
      objects = nil
      @data.lines.each do |line|
        line = line.strip
  
        # Handle utility lines
        next if line.start_with?('#')
        next if line.empty?
        if line.start_with?('<') && line.ends_with?('>')
          what = line[1..-2]
          next
        end

        # Check the objects
        objects = Synchronization.extract_array_from(line)[0]
        case what
        when "AvailableBox"
          total = AvailableBox.updated_at_least_once.for_patient(nil).count
          total_other = AvailableBox.updated_at_least_once.for_patient(@patient.id).count()
          expect(objects.length).to eq(total).or eq(total_other)#, "Not all AvailableBox of the patient where retrieved: #{objects.length} != #{total}"
        when "AvailableExerciseTree"
          total = AvailableExerciseTree.updated_at_least_once.for_patient(nil).count
          total_other = AvailableExerciseTree.updated_at_least_once.for_patient(@patient.id).count()
          expect(objects.length).to eq(total).or eq(total_other)#, "Not all AvailableExerciseTree of the patient where retrieved: #{objects.length} != #{total}"
        when "AvailableLevel"
          total = AvailableLevel.updated_at_least_once.for_patient(nil).count
          total_other = AvailableLevel.updated_at_least_once.for_patient(@patient.id).count()
          expect(objects.length).to eq(total).or eq(total_other)#, "Not all AvailableLevels of the patient where retrieved: #{objects.length} != #{total}"
        when "AvailableTarget"
          total = AvailableTarget.updated_at_least_once.for_patient(nil).count
          total_other = AvailableTarget.updated_at_least_once.for_patient(@patient.id).count()
          expect(objects.length).to eq(total).or eq(total_other)#, "Not all AvailableTarget of the patient where retrieved: #{objects.length} != #{total}"
        when "Card"
          total = Card.where(type: %w(ArchivedCard CustomCard)).for_patient(@patient.id).count
          total_other = ArchivedCard.count()  +CognitiveCard.count() -(total - ArchivedCard.for_patient(@patient.id).count())
          total_presets = PresetCard.count()
          expect(objects.length).to eq(total).or eq(total_other).or eq(total_presets)#, "Not all Cards of the patient where retrieved: #{objects.length} != #{total}"
        when "Content"
          total = Card.where(type: %w(ArchivedCard CustomCard)).for_patient(@patient.id).group(:content_id).reorder(nil).count.count
          total_other = ArchivedCard.group(:content_id).reorder(nil).count.count() +CognitiveCard.group(:content_id).reorder(nil).count.count() -(total - ArchivedCard.for_patient(@patient.id).count())
          total_presets = PresetCard.group(:content_id).reorder(nil).count.count()
          expect(objects.length).to eq(total).or eq(total_other).or eq(total_presets)#, "Not all Contents of the patient where retrieved: #{objects.length} != #{total}"
        when "ExerciseTree"
          total = ExerciseTree.count
          expect(objects.length).to eq(total), "Not all ExerciseTrees where retrieved: #{objects.length} != #{total}"
        when "FeedbackPage"
          total = FeedbackPage.count
          expect(objects.length).to eq(total), "Not all FeedbackPages where retrieved: #{objects.length} != #{total}"
        when "Page"
          total = Page.where.not(type: "FeedbackPage").for_patient([@patient.id, nil]).count
          expect(objects.length).to eq(total), "Not all Pages where retrieved: #{objects.length} != #{total}"
        when "PresentationPage"
          total = PresentationPage.for_patient(@patient.id).count + PresentationPage.for_patient(nil).count
          expect(objects.length).to eq(total), "Not all PresentationPages where retrieved: #{objects.length} != #{total}"
        when "Tag"
          total = Tag.where.not(type: "CardTag").count
          expect(objects.length).to eq(total), "Not all Tags where retrieved: #{objects.length} != #{total}"
        when "Tree"
          total = Tree.for_patient(nil).count
          total_other = Tree.for_patient(@patient.id).count()
          expect(objects.length).to eq(total).or eq(total_other)#, "Not all Tree of the patient where retrieved: #{objects.length} != #{total}"
        else
          total = 0
          if what.constantize.column_names.include? "patient_id"
            total = what.constantize.where(patient_id: @patient.id).count
          else 
            total = what.constantize.count
          end
          expect(objects.length).to eq(total), "Not all #{what}s of the patient where retrieved: #{objects.length} != #{total}"
        end

      end

      expect(what).not_to be_nil, "No object to synchronize was found"
    end

    it "delete file /private/upload_.rb" do
      file_path = Rails.root.join("private/upload_#{@current_user.id}.rb")
      expect(File.exist?(file_path)).to be false
    end

  end

  context "POST new_data" do
    before(:each) do
      newId = "sync_page"
      newName = "Sync page n. 1"
      created_at = 1.minute.ago
      expect(Page.exists?(newId)).to eq(false)

      file_path = Rails.root.join("private/upload_#{@current_user.id}.rb")
      newObjects = "# New training sessions\n\n# New audio files\n\n# New tracker calibration parameters\n\n# New cards and contents\n\n# New pages\n<Page>\n[{\"id\":\"#{newId}\",\"name\":\"#{newName}\",\"session_event_id\":null,\"patient_id\":\"#{@patient.id}\",\"created_at\":\"#{created_at}\",\"updated_at\":\"#{created_at}\",\"ancestry\":null,\"ancestry_depth\":0,\"background_color\":null,\"type\":\"CustomPage\"}]\n\n# New trees\n\n# New user_trees\n\n# New session events\n\n"
      
      File.open(Rails.root.join(file_path), "w") do |file|
        file.puts newObjects
      end

      # Compress
      file_content = ActiveSupport::Gzip.compress(File.read(file_path))

      # Cipher initialization
      cipher = OpenSSL::Cipher.new('aes-256-cbc')
      cipher.encrypt
      cipher.key = ENV["SYNC_ENCRYPTION_KEY"]
      iv = cipher.random_iv

      # Encryption
      file_content = cipher.update(file_content) << cipher.final

      params = {:file => file_content, :iv => iv, :direction => "up"}

      # TODO conversion from Hash to Json has an error, Rspoec post doesn't work, I can only test by sending to the online server

      # Send data to the online server
      # post "/new_data", params: params.to_json, headers: @headers
      # @response = RestClient.post(ENV['ONLINE_SERVER_ADDRESS'] + "/new_data", params, @headers)
      # @body = eval(@response.body)
    end

    # it "is 200 OK" do
    #   expect(@response.code).to eq(200)
    # end

    # it "is success" do
    #   expect(@body[:success]).to eq(true)
    # end
  end

  context "#create" do
    before(:each) do
      ActiveJob::Base.queue_adapter = :test

      post "/synchronizations", params: {:patient_id => @patient.id}.to_json, headers: @headers
    end

    it "200 OK" do
      expect(response).to have_http_status(:ok)
    end

  end

end
