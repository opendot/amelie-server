require 'rails_helper'
require 'shared/signin.rb'

RSpec.describe Api::V1::PatientsController, type: :request do
  include_context "signin"
  before(:all) do
    @another_user = GuestUser.first
    @another_patient = @another_user.patients.first
  end

  context "create" do

    before(:all) do
      signin_superadmin
    end

    context "correct patient" do
      before(:each) do
        @id = SecureRandom.uuid()
        @name = "New Test"
        @region = "Piemonte"
        patient = {
          id: @id,
          name: @name,
          surname: "Patient",
          birthdate: "01/01/2010",
          region: @region,
        }
        post "/patients", params: patient.to_json, headers: @headers
      end

      it "return 201 CREATED" do
        expect(response).to have_http_status(:created)
      end

      it "return the patient" do
        patient = JSON.parse(response.body)
        expect(patient["name"]).to eq(@name)
      end

      it "created the patient" do
        patient = JSON.parse(response.body)
        expect(Patient.exists?(patient["id"])).to be true
      end

      it "didn't assigned the patient to the user" do
        patient = JSON.parse(response.body)
        expect(@current_user.patients.exists?(patient["id"])).to be false
      end

      it "has the birthdate" do
        patient = JSON.parse(response.body)
        expect(Patient.find(patient["id"]).birthdate).to_not be nil
      end

      it "has the region" do
        patient = JSON.parse(response.body)
        expect(Patient.find(patient["id"]).region).to eq(@region)
      end

    end

    context "wrong patient" do
      before(:each) do
        @id = SecureRandom.uuid()
        @name = "New Test"
        @patient_hash = {
          id: @id,
          name: @name,
          surname: "Patient",
          birthdate: "01/01/2010",
        }
      end

      it "require id, raise error if not defined" do
        @patient_hash.delete(:id)

        expect {
          post "/patients", params: @patient_hash.to_json, headers: @headers
        }.to raise_error ActiveRecord::NotNullViolation
      end

      it "require name" do
        @patient_hash.delete(:name)

        post "/patients", params: @patient_hash.to_json, headers: @headers
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "require birthdate" do
        @patient_hash.delete(:birthdate)

        post "/patients", params: @patient_hash.to_json, headers: @headers
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "from Parent" do
      before(:each) do
        @id = SecureRandom.uuid()
        @name = "New Test"
        patient = {
          id: @id,
          name: @name,
          surname: "Patient",
          birthdate: "01/01/2010",
        }

        # Convert the user into a parent
        User.find(@current_user.id).update!(type: "Parent")

        post "/patients", params: patient.to_json, headers: @headers
      end

      it "assigned the patient to the user" do
        patient = JSON.parse(response.body)
        expect(@current_user.patients.exists?(patient["id"])).to be true
      end

      it "has disabled param" do
        patient = JSON.parse(response.body)
        expect(patient["disabled"]).to be  Patient.find(@id).disabled
      end

    end

  end

  context "update" do

    before(:all) do
      signin_parent
    end

    context "my patient" do
      before(:each) do
        @patient = Patient.where.not(id: @another_patient.id).first
        @current_user.add_patient(@patient)
        @name = "Updated Test"
        patient = {
          name: @name,
        }
        put "/patients/#{@patient.id}", params: patient.to_json, headers: @headers
      end

      it "return 202 ACCEPTED" do
        expect(response).to have_http_status(:accepted)
      end

      it "updated the patient" do
        expect(Patient.find(@patient.id).name).to eq(@name)
      end

    end

    context "another patient" do
      before(:each) do
        @patient = GuestUser.last.patients.first
        @name = "Updated Test"
        patient = {
          name: @name,
        }
        put "/patients/#{@patient.id}", params: patient.to_json, headers: @headers
      end

      it "return 401 UNAUTHORIZED" do
        expect(response).to have_http_status(:unauthorized)
      end

    end

  end

  context "show" do
    before(:all) do
      signin_parent
    end

    context "my patient" do
      before(:each) do
        @patient = Patient.where.not(id: @another_patient.id).first
        @current_user.add_patient(@patient)

        get "/patients/#{@patient.id}", headers: @headers
      end

      it "return 200 OK" do
        expect(response).to have_http_status(:ok)
      end

      it "return the patient" do
        patient = JSON.parse(response.body)
        expect(patient["id"]).to eq(@patient.id)
      end

    end

    context "another patient" do
      before(:each) do
        @patient = GuestUser.last.patients.first
        get "/patients/#{@patient.id}", headers: @headers
      end

      it "return 401 UNAUTHORIZED" do
        expect(response).to have_http_status(:unauthorized)
      end

    end

  end

end
