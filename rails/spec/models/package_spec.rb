require 'rails_helper'
require 'shared/cognitive_session_utils.rb'

RSpec.describe Package, type: :model do
  include_context "cognitive_session_utils"

  context "write_on_file" do
    before(:each) do
      @patient = Patient.first
      @user = Researcher.first
      @exercise_tree1 = ExerciseTree.first
      @exercise_tree2 = ExerciseTree.last

      @session_ids = []
      @session_ids << create_and_conclude_session( SecureRandom.uuid(), @exercise_tree1, true).id
      @session_ids << create_and_conclude_session( SecureRandom.uuid(), @exercise_tree1, true).id
      @session_ids << create_and_conclude_session( SecureRandom.uuid(), @exercise_tree2, true).id

      @sessions = TrainingSession.where(:id => @session_ids)
      @file_path = Rails.root.join(Package.objects_path)

      Package.write_on_file(@sessions)
    end

    it "created file /private/package.rb" do
      expect(File.exist?(@file_path)).to be true
    end

    it "has data written" do
      data = File.read(@file_path)
      # puts "\n\ndata\n=========\n#{data}\n"
      expect(data).not_to be_empty
    end
  end

  context "session filters" do
    before(:each) do
      Patient.delete_all

      @user = Researcher.create!(id: SecureRandom.uuid(), name: "John", surname: "Doe", birthdate: FFaker::Time.date,
                                 email: "foobar@mail.it", password: "password", password_confirmation: "password")

      @patient = Patient.create!(id: SecureRandom.uuid(), name: "Sofia", surname: "Drera", birthdate: FFaker::Time.date,
                                 region: 'lazio')

      TobiiCalibrationParameter.create!(id: SecureRandom.uuid(), fixing_radius: 0.05, fixing_time_ms: 600, patient: @patient)

      @page1 = Page.create!( id: SecureRandom.uuid())

      @exercise_tree1 = ExerciseTree.create!( id: SecureRandom.uuid(), name: "Test 1", root_page: @page1)
    end

    it "filters by patient region" do
      session_id = create_and_conclude_session(SecureRandom.uuid(), @exercise_tree1, true).id

      package = Package.new(1, 1, 'piemonte')
      expect(package.get_sessions.pluck(:id)).to eq([])

      package = Package.new(1, 1, 'lazio')
      expect(package.get_sessions.distinct.pluck(:id)).to eq([session_id])
    end

    it "filters by session type" do
      session_id = create_and_conclude_session(SecureRandom.uuid(), @exercise_tree1, true).id

      package = Package.new(1, 1, nil, ['CommunicationSession'])
      expect(package.get_sessions.count).to eq(0)

      package = Package.new(1, 1, nil, ['CognitiveSession'])
      expect(package.get_sessions.distinct.pluck(:id)).to eq([session_id])
    end

    it "filters by multiple session type" do
      session_id = create_and_conclude_session(SecureRandom.uuid(), @exercise_tree1, true).id

      package = Package.new(1, 1, nil, ['CognitiveSession', 'CommunicationSession'])
      expect(package.get_sessions.distinct.pluck(:id)).to eq([session_id])
    end

    it "filters by sessions with eyetracking data" do
      session_id = create_and_conclude_session(SecureRandom.uuid(), @exercise_tree1, true).id

      package = Package.new(1, 1, nil, nil, true)
      expect(package.get_sessions.count).to eq(0)

      TrackerRawDatum.create!(id: SecureRandom.uuid(), x_position: 10, y_position: 10, training_session_id: session_id)

      package = Package.new(1, 1, nil, nil, true)
      expect(package.get_sessions.count).to eq(1)
      expect(package.get_sessions.distinct.pluck(:id)).to eq([session_id])
    end

  end

end