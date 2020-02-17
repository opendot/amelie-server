require 'rails_helper'

RSpec.describe Level, type: :model do
  context "create" do
    before(:each) do
      @name = "Test Level"
      @value = 1
    end

    it "receive value and name" do
      level = Level.new(value: @value, name: @name)
      expect(level.save).to be true
      expect(Level.find(level.id).name).to eq(@name)
    end

    it "require value" do
      level = Level.new(name: @name)
      expect(level.save).to be false
    end

    it "doesn't require name" do
      level = Level.new(value: @value)
      expect(level.save).to be true
      expect(Level.find(level.id).name).to be_nil
    end
  end

  context "available?" do
    before(:each) do
      @patient0 = Patient.find_by(id: "patient0")
      1.upto(5) do |i|
        Level.create!(value: i, name: "Level Available #{i}")
      end
    end

    it "return true for first level" do
      expect( Level.find_by(name: "Level Available 1").available?(@patient0.id) ).to be true
    end

    it "return false for other levels" do
      2.upto(5).each do |i|
        expect( Level.find_by(name: "Level Available #{i}").available?(@patient0.id) ).to be false
      end
    end

    it "return true for all completed levels" do
      completed_levels_count = 3
      1.upto(completed_levels_count).each do |i|
        Level.find_by(name: "Level Available #{i}").available_level_for(@patient0.id).update(status: 1)
      end

      1.upto(completed_levels_count).each do |i|
        expect( Level.find_by(name: "Level Available #{i}").available?(@patient0.id) ).to be true
      end
    end

    it "return true for first not available level" do
      current_level = Level.find_by(name: "Level Available 4")
      # Set all previous levels as completed
      Level.where("value < ?", current_level.value).each do |l|
        l.available_level_for(@patient0.id).update(status: 1)
      end

      expect( current_level.available?(@patient0.id) ).to be true
    end

    it "return different values for different patient" do
      current_level = Level.find_by(name: "Level Available 4")
      # Set all previous levels as Pessed
      Level.where("value < ?", current_level.value).each do |l|
        l.available_level_for(@patient0.id).update(status: 1)
      end

      expect( current_level.available?(@patient0.id) ).to be true
      expect( current_level.available?("patient1") ).to be false
    end

  end

  context "conclude_for patient" do

    before(:each) do
      @patient = Patient.first
      # reset previous levels
      Level.where("levels.value <= ?", 1).each do |l|
        l.available_level_for(@patient.id).update!(status: :complete)
      end

      @level1 = Level.create!(value: 1, name: "Level Available 1")
      @level2 = Level.create!(value: 2, name: "Level Available 2")
      @level3 = Level.create!(value: 3, name: "Level Available 3")

      @level1.conclude_for @patient
      @available_level1 = @level1.available_level_for(@patient.id)
    end

    it "has status complete" do
      expect( @available_level1.status).to eq("complete")
    end

    it "next level has status available" do
      available_level2 = @level2.available_level_for(@patient.id)
      expect( available_level2.status).to eq("available")
    end

    it "last level has status unavailable" do
      available_level3 = @level3.available_level_for(@patient.id)
      expect( available_level3.status).to eq("unavailable")
    end

  end

  context "concluded_box_for patient" do

    before(:each) do
      @level = Level.create!(value: 1, name: "Level Available 1")
      @box1 = Box.create!(name: "Test Box 1", level: @level)
      @box2 = Box.create!(name: "Test Box 2", level: @level)

      @patient = Patient.first

      @available_box1 = @box1.available_box_for(@patient.id)
      @available_box1.update!(status: :complete)
      @level.concluded_box_for @patient, @box1

      @available_level = @level.available_level_for(@patient.id)
    end

    it "has status available" do
      expect( @available_level.status).to eq("available")
    end

    it "is completed after concluding box2" do
      @box2.available_box_for(@patient.id).update!(status: :complete)
      @level.concluded_box_for @patient, @box
      expect( @patient.available_levels.where(level: @level).first.status).to eq("complete")
    end

  end

  context "published" do
    before(:each) do
      @level = Level.create!(value: 1, name: "Level Available 1")

      # Assign some default values
      @level.update!(published: false)

    end

    it "has scope that founds all published Levels" do
      levels = Level.published

      expect(levels.count).to eq(Level.count-1)
      expect(levels.include?@level).to be false
    end

    it "has scope that founds all unpublished Levels" do
      levels = Level.unpublished

      expect(levels.count).to eq(1)
      expect(levels.first.id).to eq(@level.id)
    end

  end

  context "soft-delete" do
    before(:each) do
      @level = Level.create!(value: 1, name: "Level Soft Delete 1")

      @level.destroy!
    end

    it "doesn't find the level with normal calls" do
      expect(Level.exists?(@level.id)).to be false
    end

    it "find the level if deleted are included" do
      expect(Level.with_deleted.exists?(@level.id)).to be true
    end

    it "find the deleted level for synchronization" do
      expect(Level.not_sync(1.day.ago).exists?(@level.id)).to be true
    end

    it "deleted all availables" do
      expect(AvailableLevel.where(level_id: @level.id).count).to eq(0)
    end

    it "soft-deleted all availables" do
      expect(AvailableLevel.with_deleted.where(level_id: @level.id).count).to eq(Patient.count +1)
    end

  end

  context "destroy" do
    before(:each) do
      @patient = Patient.first

      # This is the only available level for the patient
      @level = Level.find(2)

      # Complete previous levels
      @patient.available_levels.where( :level_id => Level.where("value < ?", @level.value))
      .update_all(status: :complete)

      @level.destroy!
    end

    it "set the next level as available" do
      next_level = Level.where("value > ?", @level.value).reorder(value: :asc).first
      expect( AvailableLevel.with_deleted.where(level_id: @level.id, patient_id: @patient.id).first.status).to eq("available")
    end

    it "set the boxes of the next level as available" do
      next_level = Level.where("value > ?", @level.value).reorder(value: :asc).first
      next_level.boxes.each do |b|
        expect( b.available_box_for(@patient.id).status).to eq("available")
      end
    end

    it "soft-delete the available level and keep him as available" do
      expect( AvailableLevel.with_deleted.where(level_id: @level.id, patient_id: @patient.id).where.not(status: "available").count).to eq(0)
    end

  end

end
