require 'rails_helper'
require 'shared/signin.rb'

describe Api::V1::Users::PatientsController, :type => :request do
  include_context "signin"
  before(:all) do
      signin_parent
  end

  context "update" do
    before(:each) do
      password = "t34ch3r_t3st"
      @user = Teacher.create!(id: "test_teacher", email: "teacher@mail.it", password: password, password_confirmation: password, name: "Test", surname: "Teacher")
      @patient = Patient.first
      @current_user.add_patient(@patient)
    end

    context "add patient to user" do
      before(:each) do
        put "/users/#{@user.id}/patients/#{@patient.id}", headers: @headers
      end

      it "return 200 OK" do
        expect(response).to have_http_status(:ok)
      end
  
      it "return the patient" do
        patient = JSON.parse(response.body)
        expect(patient["id"]).to eq(@patient.id)
      end

      it "add the patient to the user list" do
        expect(@user.patients.exists?(@patient.id)).to be true
      end
    end

    context "add patient from disabled user" do
      before(:each) do
        @current_user.set_disabled(true)
        put "/users/#{@user.id}/patients/#{@patient.id}", headers: @headers
      end

      it "return 403 FORBIDDEN" do
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "non-parent user" do
      before(:all) do
        signin_superadmin
      end

      before(:each) do
        @patient = Patient.first
        @current_user.add_patient(@patient)

        put "/users/#{@user.id}/patients/#{@patient.id}", headers: @headers
      end

      it "return 403 FORBIDDEN" do
        expect(response).to have_http_status(:forbidden)
      end

    end
    
  end

  context "delete" do
    before(:each) do
      password = "t34ch3r_t3st"
      @user = Teacher.create!(id: "test_teacher", email: "teacher@mail.it", password: password, password_confirmation: password, name: "Test", surname: "Teacher")
      @patient = Patient.first
      @current_user.add_patient(@patient)

      @user.add_patient(@patient)
      expect(@user.patients.exists?(@patient.id)).to be true
    end

    context "parent" do
      before(:all) do
        signin_parent
      end

      context "a patient associated" do
        before(:each) do
          delete "/users/#{@user.id}/patients/#{@patient.id}", headers: @headers
        end

        it "return 200 OK" do
          expect(response).to have_http_status(:ok)
        end

        it "remove the patient from the user list" do
          expect(@user.patients.exists?(@patient.id)).to be false
        end

      end

      context "a patient not associated" do
        before(:each) do
          @current_user.patients.delete_all
          delete "/users/#{@user.id}/patients/#{@patient.id}", headers: @headers
        end

        it "return 401 UNAUTHORIZED" do
          expect(response).to have_http_status(:unauthorized)
        end

      end

    end

    context "superadmin" do
      before(:all) do
        signin_superadmin
      end

      context "a patient not associated" do
        before(:each) do
          @current_user.patients.delete_all
          delete "/users/#{@user.id}/patients/#{@patient.id}", headers: @headers
        end

        it "return 200 OK" do
          expect(response).to have_http_status(:ok)
        end

        it "remove the patient from the user list" do
          expect(@user.patients.exists?(@patient.id)).to be false
        end
      end

    end

    context "researcher" do
      before(:all) do
        signin_researcher
      end

      before(:each) do
        delete "/users/#{@user.id}/patients/#{@patient.id}", headers: @headers
      end

      it "return 403 FORBIDDEN" do
        expect(response).to have_http_status(:forbidden)
      end

    end

  end

end
