require 'rails_helper'

RSpec.describe TargetLayout, type: :model do

  before(:each) do
    @target = Target.create!(name: "Test Target")
    @exercise_tree = ExerciseTree.create!( id: SecureRandom.uuid(),
      name: "Test ExerciseTree", root_page: Page.first, patient: Patient.first)
  end

  context "create" do
    before(:each) do
      @target.add_exercise_tree(@exercise_tree, 1)
    end

    it "has one target" do
      expect(@target.exercise_trees.count).to eq(1)
    end

    it "link created" do
      expect(@target.exercise_trees.first.id).to eq(@exercise_tree.id)
    end

  end

  context "position" do
    before(:each) do
      @position = 1
      @target.add_exercise_tree(@exercise_tree, @position)
    end

    it "is assigned" do
      expect(@target.target_layouts.first.position).to eq(@position)
    end

    it "has default position to 0" do
      @target.add_exercise_tree(
        ExerciseTree.create!( id: SecureRandom.uuid(),
          name: "ExerciseTree with default position", root_page: Page.first, patient: Patient.first)
      )
      expect(@target.target_layouts.last.position).to eq(0)
    end

    it "has only positive positions" do
      tree = ExerciseTree.create!( id: SecureRandom.uuid(),
        name: "ExerciseTree with default position", root_page: Page.first, patient: Patient.first)
      expect {
        TargetLayout.create!(target: @target, exercise_tree: tree, position: -1)
      }.to raise_error(ActiveRecord::RecordInvalid)
    end

  end
end
