require 'rails_helper'
require 'shared/signin.rb'

describe Api::V1::PatientsController, :type => :request do
  include_context "signin"

  before(:all) do
    signin_parent
  end

  context "#index patients with no patients" do
    before(:each) do
      Patient.destroy_all
      get "/patients", headers: @headers
    end

    it "return 200 OK" do
      expect(response).to have_http_status(:ok)
    end

    it "return no patients" do
      patients = JSON.parse(response.body)
      expect(patients.length).to eq(0)
    end
  end

  context "#index 3 patients" do
    before(:each) do
      # Add patients to the user
      Patient.all.limit(3).each do |p|
        @current_user.add_patient(p)
      end

      get "/patients", headers: @headers
    end

    it "return 200 OK" do
      expect(response).to have_http_status(:ok)
    end

    it "return 3 elements" do
      patients = JSON.parse(response.body)
      expect(patients.length).to eq(3)
    end

    it "return existing patients" do
      patients = JSON.parse(response.body)
      patients.each do |p|
        expect(Patient.exists?(p["id"])).to be true
      end
    end
  end

  context "#show patient" do
    before(:each) do
      @patient = Patient.first
      @current_user.add_patient(@patient)

      get "/patients/#{@patient.id}", headers: @headers
    end

    it "return 200 OK" do
      expect(response).to have_http_status(:ok)
    end

    it "return a patient" do
      patient = JSON.parse(response.body)
      expect(patient["id"]).to eq(@patient.id)
    end
  end

  context "#show patient not exist" do
    before(:each) do
      get "/patients/fake_id", headers: @headers
    end

    it "return 401 UNAUTHORIZED" do
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context "#show patient not belonging to user" do
    before(:each) do
      @patient = Patient.create!(id: "patient_external", name: FFaker::NameIT.first_name, surname: FFaker::NameIT.last_name, birthdate: FFaker::Time.date)
      
      get "/patients/#{@patient.id}", headers: @headers
    end

    it "return 401 UNAUTHORIZED" do
      expect(response).to have_http_status(:unauthorized)
    end

  end

  context "roles" do

    context "researcher" do
      before(:all) do
        signin_researcher
      end

      context "index" do
        before(:each) do
          get "/patients?all=true", headers: @headers

          @patients = JSON.parse(response.body)
        end

        it "can see all patients" do
          expect(@patients.length).to eq(Patient.count)
        end

        it "can see only their id" do
          @patients.each do |patient|
            expect(patient.keys.length).to eq(1)
            expect(patient).to have_key("id")
          end
        end
      end

      context "show" do
        before(:each) do
          @another_patient = Patient.where.not(:id => @current_user.patient_ids).first
          get "/patients/#{@another_patient.id}", headers: @headers

          @patient_response = JSON.parse(response.body)
        end

        it "can see a patient not associated" do
          expect(response).to have_http_status(:ok)
        end

        it "see anonimized patient if not associated" do
          expect(@patient_response.keys.length).to eq(1)
          expect(@patient_response).to have_key("id")
        end
      end
    end

    context "superadmin" do
      before(:all) do
        signin_superadmin
      end

      context "index" do
        before(:each) do
          get "/patients?all=true", headers: @headers

          @patients = JSON.parse(response.body)
        end

        it "can see all patients" do
          expect(@patients.length).to eq(Patient.count)
        end

        it "can see all their info" do
          @patients.each do |patient|
            expect(patient).to have_key("name")
          end
        end
      end

      context "show" do
        before(:each) do
          @another_patient = Patient.where.not(:id => @current_user.patient_ids).first
          get "/patients/#{@another_patient.id}", headers: @headers

          @patient_response = JSON.parse(response.body)
        end

        it "can see a patient not associated" do
          expect(response).to have_http_status(:ok)
        end

        it "can see patient informations" do
          expect(@patient_response).to have_key("name")
        end
      end
    end

  end

end