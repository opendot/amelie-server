require 'rails_helper'

RSpec.describe Badge, type: :model do
  
  before(:each) do
    @patient = Patient.first
  end

  context "create" do
    before(:each) do
      @level = Level.first

      @badge = Badge.create!(
        id: SecureRandom.uuid(),
        patient: @patient, 
        achievement: "box",
        box: @level.boxes.first,
      )
    end

    it "created the badges" do
      expect(Badge.exists?(@badge.id)).to be true
    end

    it "filled level" do
      expect(@badge.level_id).to eq(@level.id)
    end

    it "filled level name" do
      expect(@badge.level_name).to eq(@level.name)
    end

    it "filled date" do
      expect(@badge.date).to_not be nil
    end

    context "with fake values" do
      before(:each) do
  
        @badge = Badge.create!(
          id: SecureRandom.uuid(),
          patient: @patient, 
          achievement: "box",
          box: @level.boxes.first,
          box_name: "fake",
          level_name: "fake_level",
        )
      end

      it "set correct box name" do
        expect(@badge.box_name).to eq(@level.boxes.first.name)
      end

      it "set correct level" do
        expect(@badge.level_id).to eq(@level.id)
      end
  
      it "set correct level name" do
        expect(@badge.level_name).to eq(@level.name)
      end

    end

    context "doesn't require id" do
      before(:each) do
        @level = Level.first
  
        @badge = Badge.create!(
          patient: @patient, 
          achievement: "box",
          box: @level.boxes.first,
        )
      end
  
      it "created the badges" do
        expect(Badge.exists?(@badge.id)).to be true
      end
    end

    context "with target" do
      before(:each) do
  
        @badge = Badge.create!(
          id: SecureRandom.uuid(),
          patient: @patient, 
          achievement: "target",
          target: @level.boxes.first.targets.first,
        )
      end

      it "set correct box name" do
        expect(@badge.box_name).to eq(@level.boxes.first.name)
      end

      it "set correct level" do
        expect(@badge.level_id).to eq(@level.id)
      end

    end

  end

  context "create_communication_count_badges?" do
    before(:each) do
      @valid = [10, 25, 50, 1000]
      @invalid = [-1, 0, 1, 30]
      @interval = 50
    end

    it "return true for valid values" do
      @valid.each do |count|
        expect(Badge.create_communication_count_badges?(count)).to be true
      end
    end

    it "return false for invalid values" do
      @invalid.each do |count|
        expect(Badge.create_communication_count_badges?(count)).to be false
      end
    end

    it "return true for values in the interval" do
      multiples = [1, 2, 4, 8, 16, 32]
      multiples.each do |multiple|
        expect(Badge.create_communication_count_badges?(@interval * multiple)).to be true
      end
    end

  end
end
