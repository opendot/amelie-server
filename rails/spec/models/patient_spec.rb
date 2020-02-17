require 'rails_helper'
require "cancan/matchers"

RSpec.describe Patient, type: :model do

  context "add user" do
    before(:each) do
      @patient = Patient.first
      @parent = Parent.first
      @parent.add_patient(@patient)
    end

    it "can insert with <<" do
      user = User.where.not(:id => @patient.users.ids).where.not(type: %w(Parent DesktopPc GuestUser)).first
      @patient.users << user
      expect(Patient.find(@patient.id).users.include?(user)).to be true
    end

    it "can have more users" do
      user = User.where.not(:id => @patient.users.ids).where.not(type: %w(Parent DesktopPc GuestUser)).first
      user.add_patient(@patient)
      expect(@patient.users.include?(user)).to be true
    end

    it "can have only 1 parent with <<" do
      another_parent = Parent.create!(id: "anotherParent", email: "another.parent@mail.it", password: "password", password_confirmation: "password", name: "Parent", surname: "Test")
      @patient.users << another_parent
      expect(@patient.users.include?(another_parent)).to be false
    end

    it "can have only 1 parent with add_patient" do
      another_parent = Parent.create!(id: "anotherParent", email: "another.parent@mail.it", password: "password", password_confirmation: "password", name: "Parent", surname: "Test")
      another_parent.add_patient(@patient)
      expect(@patient.users.include?(another_parent)).to be false
    end

  end

  context "parent" do
    before(:each) do
      @patient = Patient.first
      @parent = Parent.first
      @parent.add_patient(@patient)
    end

    it "has parent_id" do
      expect(@patient.parent_id).to eq(@parent.id)
    end

    it "has parent" do
      expect(@patient.parent.surname).to eq(@parent.surname)
    end

  end

  context "disabled" do
    before(:each) do
      @patient = Patient.first
      @parent = Parent.first
      @parent.add_patient(@patient)
    end

    it "is true if parent.disabled is true" do
      @patient.update!(disabled: true)
      expect(Patient.find(@patient.id).disabled).to be true
    end

    it "is false if parent.disabled is false" do
      @patient.update!(disabled: false)
      expect(Patient.find(@patient.id).disabled).to be false
    end

  end

  context "update from serializer" do
    before(:each) do
      @patient = Patient.first
      @another_patient = Patient.where.not(id: @patient.id).first

      @serialized_another = JSON.parse(Api::V1::PatientSerializer.new(@another_patient).to_json)
      @serialized_another["disabled"] = true

      @success = @patient.update_from_serialized(@serialized_another)
    end

    it "succed" do
      expect(@success).to be true
    end

    it "doesn't update the id" do
      expect(@patient.id).to_not eq(@another_patient.id)
    end

    it "update the name" do
      expect(@patient.name).to eq(@another_patient.name)
    end

    it "update the disabled" do
      expect(@patient.disabled).to eq(@serialized_another["disabled"])
    end

  end

end