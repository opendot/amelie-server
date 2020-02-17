require 'rails_helper'
require 'shared/signin.rb'

RSpec.describe Api::V1::UsersController, type: :request do
  include_context "signin"
  before(:all) do
    signin_researcher
  end

  context "index" do
    before(:each) do
      # Create fake users
      @psw = "password"
      Researcher.create!(id: "testResearcher1", email: "testResearcher1@mail.it", password: @psw, password_confirmation: @psw, name: "Researcher", surname: "Test")
      Researcher.create!(id: "testResearcher2", email: "testResearcher2@mail.it", password: @psw, password_confirmation: @psw, name: "Researcher", surname: "Test")

      Teacher.create!(id: "testTeacher1", email: "testTeacher1@mail.it", password: @psw, password_confirmation: @psw, name: "Teacher", surname: "Test")
      Therapist.create!(id: "testTherapist1", email: "testTherapist1@mail.it", password: @psw, password_confirmation: @psw, name: "Therapist", surname: "Test")

      Parent.create!(id: "testParent1", email: "testParent1@mail.it", password: @psw, password_confirmation: @psw, name: "Parent", surname: "Test")
    end

    context "from Superadmin" do
      before(:each) do
        User.find(@current_user.id).update!(type: "Superadmin")
      end

      it "return all users" do
        get "/users", headers: @headers

        users = JSON.parse(response.body)
        expect(users.length).to eq(User.count)
      end

      it "return all users of the given type" do
        type = "Researcher"
        get "/users?type=#{type}", headers: @headers

        users = JSON.parse(response.body)
        expect(users.length).to eq(User.where(type: type).count)
      end

      it "accept an array of types" do
        types = %w(Researcher Superadmin)
        get "/users?type[]=#{types[0]}&type[]=#{types[1]}", headers: @headers

        users = JSON.parse(response.body)
        expect(users.length).to eq(User.where(type: types).count)
      end
    end

    context "from Researcher" do
      before(:each) do
        User.find(@current_user.id).update!(type: "Researcher")

        get "/users", headers: @headers
      end

      it "return 403 FORBIDDEN" do
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "from Parent" do
      before(:each) do
        User.find(@current_user.id).update!(type: "Parent")
      end

      it "return all Teacher and Therapist" do
        get "/users", headers: @headers

        users = JSON.parse(response.body)
        expect(users.length).to eq(Therapist.count)
      end

      it "return all users of the given type" do
        type = "Teacher"
        get "/users?type=#{type}", headers: @headers

        users = JSON.parse(response.body)
        expect(users.length).to eq(User.where(type: type).count)
      end

      it "return an empty array if an invalid type is passed" do
        type = "Superadmin"
        get "/users?type=#{type}", headers: @headers

        users = JSON.parse(response.body)
        expect(users.length).to eq(0)
      end
    end
  end

  context "update" do

    context "self" do
      before(:each) do
        # This route is available only in _remote environment
        @new_name = "Tester"
        @original_surname = @current_user.surname
        user = {
          name: @new_name,
        }
        put "/users/#{@current_user.id}", params: user.to_json, headers: @headers
      end

      it "return 202 ACCEPTED" do
        expect(response).to have_http_status(:accepted)
      end

      it "return the user" do
        user = JSON.parse(response.body)
        expect(user["id"]).to eq(@current_user.id)
      end

      it "updated the user name" do
        expect(User.find(@current_user.id).name).to eq(@new_name)
      end

      it "didn't updated the other values" do
        expect(User.find(@current_user.id).surname).to eq(@original_surname)
      end

    end

    context "another user" do
      before(:each) do
        # This route is available only in _remote environment
        @another = User.where.not(id: @current_user.id).first
        @new_name = "Tester"
        @original_surname = @current_user.surname
        user = {
          name: @new_name,
        }
        put "/users/#{@another.id}", params: user.to_json, headers: @headers
      end

      it "return 401 UNAUTHORIZED" do
        expect(response).to have_http_status(:unauthorized)
      end

    end

  end

  context "disable users" do
    context "superadmin" do
      before(:each) do
        User.find(@current_user.id).update!(type: "Superadmin")

        @num = 4
        @num.times do |i|
          p = Parent.create!(id: "testParent#{i}", email: "p#{i}@mail.it", password: "password", password_confirmation: "password", name: "Parent #{i}", surname: "Test")
          patient = Patient.create!(id: "patient_parent_#{i}", name: FFaker::NameIT.first_name, surname: FFaker::NameIT.last_name, birthdate: FFaker::Time.date)
          p.add_patient(patient)
        end

        @users_enabled = Parent.where.not(id: @current_user.id).limit(@num/2)
        @users_disabled = Parent.where.not(id: @current_user.id).where.not(:id => @users_enabled.ids).limit(@num/2)

        users = {users: []}
        @users_enabled.each { |u| users[:users] << {id: u.id, disabled: false}}
        @users_disabled.each { |u| users[:users] << {id: u.id, disabled: true}}
        put "/users/disable", params: users.to_json, headers: @headers
      end

      it "return 202 ACCEPTED" do
        expect(response).to have_http_status(:accepted)
      end

      it "return the number of updated users" do
        body = JSON.parse(response.body)
        expect(body["updated"]).to eq(@users_enabled.count+@users_disabled.count)
      end

      it "updated all patients of enabled users" do
        @users_enabled.each do |u|
          expect(User.find(u.id).patients.where.not(disabled: true).count).to eq(User.find(u.id).patients.count)
        end
      end

      it "updated all patients of disabled users" do
        @users_disabled.each do |u|
          expect(User.find(u.id).patients.where(disabled: true).count).to eq(User.find(u.id).patients.count)
        end
      end

    end

    context "another user" do
      before(:each) do
        @num = 2
        @num.times do |i|
          p = Parent.create!(id: "testParent#{i}", email: "p#{i}@mail.it", password: "password", password_confirmation: "password", name: "Parent #{i}", surname: "Test")
          patient = Patient.create!(id: "patient_parent_#{i}", name: FFaker::NameIT.first_name, surname: FFaker::NameIT.last_name, birthdate: FFaker::Time.date)
          p.add_patient(patient)
        end

        @users_enabled = Parent.where.not(id: @current_user.id).limit(@num/2)
        @users_disabled = Parent.where.not(id: @current_user.id).where.not(:id => @users_enabled.ids).limit(@num/2)

        users = {users: []}
        @users_enabled.each { |u| users[:users] << {id: u.id, disabled: false}}
        @users_disabled.each { |u| users[:users] << {id: u.id, disabled: true}}
        put "/users/disable", params: users.to_json, headers: @headers
      end

      it "return 403 FORBIDDEN" do
        expect(response).to have_http_status(:forbidden)
      end

    end

  end

end
