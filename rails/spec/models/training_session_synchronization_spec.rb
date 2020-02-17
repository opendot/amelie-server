require "rails_helper"

describe Synchronization, :type => :model do
  before(:each) do
    @current_user = Researcher.create(id: "testUser", email: "researcher@mail.it", password: "password", password_confirmation: "password", name: "Researcher", surname: "Test")
    @patient = Patient.create!(id: "patient1", name: "John", surname: "Doe", birthdate: "2018-04-05")
  end

  context "unit test" do
    it "collect changes and create new record" do
      session_id = SecureRandom.uuid()
      parameter = TobiiCalibrationParameter.create(id: SecureRandom.uuid(), fixing_radius: 0.05, fixing_time_ms: 600, patient_id: @patient.id)
      session = CommunicationSession.create!(id: session_id, start_time: "2019-01-01 10:00", user_id: @current_user.id,
                                             patient_id: @patient.id, tracker_calibration_parameter_id: parameter.id)

      expect(CommunicationSession.count).to eq(1)

      last_sync_date = DateTime.parse("2010-01-01")

      syncUtils = Synchronization.new
      syncUtils.collect_changes(last_sync_date, @current_user, @patient.id)

      session.destroy
      parameter.destroy

      expect(CommunicationSession.count).to eq(0)

      file_path = Rails.root.join("private/upload_#{@current_user.id}.rb")
      file_data = File.read(file_path)
      Synchronization.apply_edits(file_data)

      expect(CommunicationSession.count).to eq(1)
    end

    it "ignores entries with missing relationship" do
      data = [{
          id: SecureRandom.uuid(),
          timestamp: "2019-01-01T10:00:00.000+01:00",
          x_position: 100,
          y_position: 100,
          training_session_id: SecureRandom.uuid(),
          created_at: "2019-07-07T13:35:32.000+02:00",
          updated_at: "2019-07-07T13:35:32.000+02:00"
      }]

      diff = [
        '<TrackerRawDatum>',
        data.to_json
      ]

      file_data = diff.join("\n")

      # First run inserts a new record, no problems.
      Synchronization.apply_edits(file_data)

      expect(TrackerRawDatum.count).to eq(1)

      expect(Rails.logger).to receive(:warn).with(/Validation failed for TrackerRawDatum record/).and_call_original

      # Second run triggers an update, which in turns caused the issue.
      Synchronization.apply_edits(file_data)

      expect(TrackerRawDatum.count).to eq(1)
    end


  end
end