require "rails_helper"

RSpec.describe PackageMailer, type: :mailer do

  context "created_package" do
    before(:each) do
      @user = Researcher.first
      @url = "http://www.airett.it"
      @expiration = 3
      @mail = PackageMailer.with(
        current_user: @user,
        temporary_url: @url,
        expiration_days: @expiration
      ).created_package
    end

    it "send to the given user" do
      expect(@mail.to).to eq([@user.email])
    end

    it "has the given link" do
      # Use regex to check if in the mail we have the url
      expect(@mail.body.encoded).to match(@url)
    end

    it "has correct number of expiration days" do
      expect(@mail.body.encoded).to match(@expiration.to_s)
    end

  end

  context "carrierwave_upload_error" do
    before(:each) do
      @user = Researcher.first
      @error_message = "Fail"
      @error_full_message = "Full explanation"
      @mail = PackageMailer.with(
        current_user: @user,
        error_message: @error_message,
        error_full_message: @error_full_message
      ).carrierwave_upload_error
    end

    it "send to the given user" do
      expect(@mail.to).to eq([@user.email])
    end

    it "has the error message" do
      # Use regex to check if in the mail we have the error message
      expect(@mail.body.encoded).to match(@error_message)
    end
  end

end
