require "rails_helper"

describe Synchronization, :type => :model do
  before(:each) do
    @current_user = User.find("testUser")
    @patient = Patient.find("patient0")
  end

  context "unit test" do
    it "collect_changes" do
      syncUtils = Synchronization.new

      last_sync = Synchronization.where(user_id: @current_user.id, patient_id: @patient.id, direction: "up").last
      last_sync_date = DateTime.parse("1-01-1970")
      unless last_sync.nil?
        last_sync_date = last_sync.created_at
      end

      # Create a temporary files with all the changes
      syncUtils.collect_changes(last_sync_date, @current_user, @patient.id)

      # Check if the file was written
      file_path = Rails.root.join("private/upload_#{@current_user.id}.rb")
      data = File.read(file_path)
      expect(data).not_to be_empty

      what = nil
      objects = nil
      total = -1
      data.lines.each do |line|
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
          total_other = ArchivedCard.count() +CognitiveCard.count() -(total - ArchivedCard.for_patient(@patient.id).count())
          total_presets = PresetCard.count()
          expect(objects.length).to eq(total).or eq(total_other).or eq(total_presets)#, "Not all Cards of the patient where retrieved: #{objects.length} != #{total}"
        when "Content"
          # Content are shared between many cards, so I use group_by, but it makes count return an array
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
    end

    it "apply_edits" do
      newId = "sync_page"
      newName = "Sync page n. 1"
      new_updated_at = 1.month.ago
      expect(Page.exists?(newId)).to eq(false)

      # Create a new page
      newObjects = "# New training sessions\n\n# New audio files\n\n# New tracker calibration parameters\n\n# New cards and contents\n\n# New pages\n<Page>\n[{\"id\":\"#{newId}\",\"name\":\"#{newName}\",\"session_event_id\":null,\"patient_id\":\"#{@patient.id}\",\"created_at\":\"#{nil}\",\"updated_at\":\"#{new_updated_at}\",\"ancestry\":null,\"ancestry_depth\":0,\"background_color\":null,\"type\":\"CustomPage\"}]\n\n# New trees\n\n# New user_trees\n\n# New session events\n\n"
      Synchronization.apply_edits(newObjects)

      expect(Page.exists?(newId)).to eq(true)

      created_page = Page.find(newId);
      expect(created_page).to_not be_nil
      expect(created_page).to be_a(CustomPage)
      expect(created_page.name).to eq(newName)
      expect(created_page.created_at).to_not be_nil
      expect(created_page.updated_at).to_not be_nil
      expect(created_page.updated_at).to_not eq(new_updated_at)

    end

  end

  context "with previous sync" do
    before(:each) do
      # Create a fake sync event
      Synchronization.create(user_id: @current_user.id, patient_id: @patient.id, direction: "up", created_at: 1.second.ago)
    end

    it "retrieve new cards" do
      # Create a fake card
      card_content = GenericImage.create(id: SecureRandom.uuid(), content: File.open(File.join(Rails.root, "/public/seed_images/image#{1}.png")))
      Card.create!(id: "cardTest", type: "CustomCard", label: "Card Test", level: 3, patient_id: @patient.id, card_tag_ids: [], content_id: card_content.id)

      # Create a fake text card, without a content
      Card.create!(id: "cardTestText", type: "CustomCard", label: "Card Test Text", level: 5, patient_id: @patient.id, card_tag_ids: [], content_id: card_content.id)

      syncUtils = Synchronization.new
      last_sync = Synchronization.where(user_id: @current_user.id, patient_id: @patient.id, direction: "up").last
      expect(last_sync).to_not be_nil
      last_sync_date = last_sync.created_at

      # Create a temporary files with all the changes
      syncUtils.collect_changes(last_sync_date, @current_user, @patient.id)

      # Check if the file was written
      file_path = Rails.root.join("private/upload_#{@current_user.id}.rb")
      data = File.read(file_path)
      expect(data).not_to be_empty

      what = nil
      objects = nil
      data.lines.each do |line|
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
        when "Card"
          expect(objects.length).to eq(2)
        when "Content"
          expect(objects.length).to eq(1)
        else
          expect(objects.length).to eq(0)
        end

      end

      expect(what).not_to be_nil, "No object to synchronize was found"

    end

    it "retrieve updated cards" do
      num_edited = 3
      # Update cards
      Card.where(type: "CustomCard").where(patient_id: @patient.id).limit(num_edited)
        .each { |c| c.update( label: "Updated #{c.label}") }

      syncUtils = Synchronization.new
      last_sync = Synchronization.where(user_id: @current_user.id, patient_id: @patient.id, direction: "up").last
      expect(last_sync).to_not be_nil
      last_sync_date = last_sync.created_at

      # Create a temporary files with all the changes
      syncUtils.collect_changes(last_sync_date, @current_user, @patient.id)

      # Check if the file was written
      file_path = Rails.root.join("private/upload_#{@current_user.id}.rb")
      data = File.read(file_path)
      expect(data).not_to be_empty

      what = nil
      objects = nil
      data.lines.each do |line|
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
        when "Card"
          expect(objects.length).to eq(num_edited)
          objects.each do |card_object|
            expect(card_object[:label]).to start_with("Updated ")
          end
        when "Content"
          expect(objects.length).to eq(num_edited)
        else
          expect(objects.length).to eq(0)
        end

      end

      expect(what).not_to be_nil, "No object to synchronize was found"

    end

  end

  context "with deleted objects" do

    before(:each) do
      # Create a fake sync event
      Synchronization.create(user_id: @current_user.id, patient_id: @patient.id, direction: "down", success: true, created_at: 1.second.ago)

      # Delete some objects
      @level = Level.first
      @level.destroy!

      @box = Level.first.boxes.first
      @box.destroy!

      @target = Level.last.boxes.first.targets.first
      @target.create_relation_for_patients
      @target.destroy!

      syncUtils = Synchronization.new
      last_sync = Synchronization.down.where(user_id: @current_user.id, patient_id: @patient.id).last
      last_sync_date = last_sync.created_at

      # Create a temporary files with all the changes
      syncUtils.collect_changes(last_sync_date, @current_user, @patient.id)

      # Check if the file was written
      file_path = Rails.root.join("private/upload_#{@current_user.id}.rb")
      @data = File.read(file_path)
    end

    it "retrieved deleted objects" do
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
          # The available for the patient of the sync and the available that replaced it
          expect(objects.length).to eq(2)
        when "AvailableExerciseTree"
          # The available of the first exercise of the target that became available
          expect(objects.length).to eq(1)
        when "AvailableLevel"
          # The available for the deleted level, a level completed by deleting all it's boxes and the new active level 
          expect(objects.length).to eq(3)
        when "AvailableTarget"
          # The available for the patient of the sync
          expect(objects.length).to eq(1)
        when "Badge"
          # A level was completed by deleting all it's boxes, so a Badge is created
          expect(objects.length).to eq(1)
        when "Box"
          expect(objects.length).to eq(1)
        when "BoxLayout"
          expect(objects.length).to eq(@box.box_layouts.with_deleted.count+1)
        when "Level"
          expect(objects.length).to eq(1)
        when "Target"
          expect(objects.length).to eq(1)
        when "TargetLayout"
          expect(objects.length).to eq(@target.target_layouts.with_deleted.count)
        else
          expect(objects.length).to eq(0)
        end

      end
    end

    it "retrieved all models" do
      what = nil
      objects = nil
      models = []
      @data.lines.each do |line|
        line = line.strip

        # Handle utility lines
        next if line.start_with?('#')
        next if line.empty?
        if line.start_with?('<') && line.ends_with?('>')
          what = line[1..-2]
          models << what
          next
        end
      end

      expected_models = %w(Level Box Target AvailableLevel AvailableBox AvailableTarget BoxLayout TargetLayout)
      expected_models.each do |m|
        expect(models.include?(m)).to eq(true)
      end

    end

  end

end