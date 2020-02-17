require 'rails_helper'

RSpec.describe BoxLayout, type: :model do
  before(:each) do
    @level = Level.create!(value: 1, name: "Test Level")
    @box = Box.create!(name: "Test Box", level: @level)
  end

  context "create" do
    before(:each) do
      @target = Target.create!(name: "test Target")
      @box.add_target(@target, 1)
    end

    it "has one target" do
      expect(@box.targets.count).to eq(1)
    end

    it "link created" do
      expect(@box.targets.first.id).to eq(@target.id)
    end

  end

  context "position" do
    before(:each) do
      @target = Target.create!(name: "test Target")
      @position = 1
      @box.add_target(@target, @position)
    end

    it "is assigned" do
      expect(@box.box_layouts.first.position).to eq(@position)
    end

    it "has default position to 0" do
      @box.add_target(Target.create!(name: "Target with default position"))
      expect(@box.box_layouts.last.position).to eq(0)
    end

    it "has only positive positions" do
      target = Target.create!(name: "Target with default position")
      expect {
        BoxLayout.create!(box: @box, target: target, position: -1)
      }.to raise_error(ActiveRecord::RecordInvalid)
    end

  end
end
