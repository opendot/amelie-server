require 'rails_helper'

RSpec.describe AvailableBox, type: :model do

  context "automatic link between Box and Patient" do

    it "exist for all patients and boxes" do
      patients_count = Patient.count
      Box.includes(:available_boxes).each do |box|
        expect(box.available_boxes.where.not(patient_id: nil).count).to eq(patients_count)
      end
    end

    it "with Box creation" do
      box = Box.create!(name: "Test Box", level: Level.create!(value: 1, name: "Test Level"))

      Patient.all.each do |patient|
        expect(AvailableBox.where(patient_id: patient.id, box_id: box.id).count).to eq(1)
      end
    end

    it "with Patient creation" do
      patient = Patient.create!(id: "patientTest}", name: FFaker::NameIT.first_name, surname: FFaker::NameIT.last_name, birthdate: FFaker::Time.date)

      Box.all.each do |box|
        expect(AvailableBox.where(patient_id: patient.id, box_id: box.id).count).to eq(1)
      end
    end

    it "is created with default values" do
      box = Box.create!(name: "Test Box", level: Level.create!(value: 1, name: "Test Level"))
      patient = Patient.first

      available_box = box.available_box_for(patient.id)
      expect(available_box.progress).to eq(0)
      expect(available_box.current_target_id).to be_nil
      expect(available_box.current_target_position).to eq(0)
      expect(available_box.current_exercise_tree_id).to be_nil
      expect(available_box.target_exercise_tree_position).to eq(0)
      expect(available_box.target_exercise_trees_count).to eq(0)

    end

    it "is created with correct status" do
      high_level = Level.create!(value: 100, name: "High Level")
      expect(high_level.available_levels.where.not(status: :unavailable).size).to eq(0)

      box = Box.create!(name: "Test Box", level: high_level)
      patient = Patient.first

      available_box = box.available_box_for(patient.id)
      expect(available_box.status).to eq("unavailable")

    end

  end
end
