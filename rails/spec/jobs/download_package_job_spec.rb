require 'rails_helper'
require 'shared/signin.rb'
include ActiveJob::TestHelper

describe DownloadPackageJob, :type => :job do
  include_context "signin"

  before(:all) do
    ActiveJob::Base.queue_adapter = :test
  end

  before(:each) do
    @current_user = User.find("testUser")
    @num_patients = 4
    @num_sessions= 3
  end

  context "#perform_later" do

    it "started once" do
      DownloadPackageJob.perform_later(@current_user, @num_patients, @num_sessions)
      expect(DownloadPackageJob).to have_been_enqueued.exactly(:once)
    end

    it "received all params" do
      expect{
        DownloadPackageJob.perform_later(@current_user, @num_patients, @num_sessions)
      }.to have_enqueued_job.with(@current_user, @num_patients, @num_sessions)
    end

    it "sends an email" do
      expect {
        # Since we use Job.perform_later and Mailer.deliver_later, we use ActiveJob::TestHelper
        perform_enqueued_jobs do
          DownloadPackageJob.perform_later(@current_user, @num_patients, @num_sessions)
        end
      }.to change { ActionMailer::Base.deliveries.size }.by(1)
    end

  end

end