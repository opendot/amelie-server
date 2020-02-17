require 'rails_helper'
require 'shared/signin.rb'

describe UploadModifiedRecordsJob, :type => :job do
  include_context "signin"

  before(:all) do
    ActiveJob::Base.queue_adapter = :test
    @current_user = User.find("testUser")
    @patient = Patient.find("patient0")
    # to_online_server = false
    # signin_researcher(to_online_server)
  end

  context "#perform_later" do

    it "started once" do
      UploadModifiedRecordsJob.perform_later(@current_user, @patient.id, @headers)
      expect(UploadModifiedRecordsJob).to have_been_enqueued.exactly(:once)
    end

    it "received all params" do
      expect{
        UploadModifiedRecordsJob.perform_later(@current_user, @patient.id, @headers)
      }.to have_enqueued_job.with(@current_user, @patient.id, @headers)
    end

  end

end