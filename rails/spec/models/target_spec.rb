require 'rails_helper'
require 'shared/tree_utils.rb'

RSpec.describe Target, type: :model do
  include_context "tree_utils"

  before(:each) do
    @level = Level.create!(value: 1, name: "Test Level")
    @box = Box.create!(name: "Test Box", level: @level)
  end

  context "create" do

    it "require name" do
      target = Target.new
      expect(target.save).to be false
    end

  end

  context "get current_exercise_tree" do

    before(:each) do
      @target = Target.create!(name: "Test Target")
      @box.add_target(@target)
      @patient = Patient.first
      5.times do |i|
        exercise_tree = ExerciseTree.create!( id: SecureRandom.uuid(),
          name: "Test #{i+1}", root_page: Page.first, patient: @patient)
        @target.add_exercise_tree(exercise_tree, i)
      end
    end

    it "return the first exercise_tree" do
      expect(@target.first_exercise_tree.name).to eq("Test 1")
    end

    it "return the first exercise_tree not completed by the patient" do
      first = @target.current_exercise_tree(@patient)
      expect(first.name).to eq("Test 1")
    end

    it "return the next exercise_tree after the previous is completed" do
      first = @target.current_exercise_tree(@patient)
      first.conclude_for @patient

      second = @target.current_exercise_tree(@patient)
      expect(second.name).to eq("Test 2")
      second.conclude_for @patient

      third = @target.current_exercise_tree(@patient)
      expect(third.name).to eq("Test 3")
    end

  end

  context "conclude_for patient" do

    before(:each) do
      @target1 = Target.create!(name: "Test Target 1")
      @box.add_target(@target1, 1)
      @target2 = Target.create!(name: "Test Target 2")
      @box.add_target(@target2, 2)
      @patient = Patient.first

      @target1.conclude_for @patient
      @available_target1 = AvailableTarget.where(patient: @patient, target:@target1).first
      @available_box = @box.available_box_for(@patient.id)
    end

    it "has status complete" do
      expect( @available_target1.status).to eq("complete")
    end

    it "has box with current_target_id of target2" do
      expect( @available_box.current_target_id).to eq(@target2.id)
    end

    it "conclude box when last target is completed" do
      @target2.conclude_for @patient
      expect(@box.available_box_for(@patient.id).status).to eq("complete")
    end

    it "create a Badge when target is completed" do
      @target2.conclude_for @patient
      expect(Badge.where(patient: @patient, target: @target2).count).to eq(1)
    end

  end

  context "concluded_exercise_tree_for patient" do

    before(:each) do
      @target = Target.create!(name: "Test Target 1")
      @box.add_target(@target, 1)
      @patient = Patient.first

      @exercise1 = exercise_tree = ExerciseTree.create!( id: SecureRandom.uuid(),
        name: "Test 1", root_page: Page.first)
      @target.add_exercise_tree(@exercise1, 1)
      @exercise2 = exercise_tree = ExerciseTree.create!( id: SecureRandom.uuid(),
        name: "Test 2", root_page: Page.first)
      @target.add_exercise_tree(@exercise2, 2)
      
      @exercise1.available_exercise_tree_for(@patient.id).update(status: :complete)
      @target.concluded_exercise_tree_for @patient, @exercise1

      @available_target = @target.available_target_for(@patient.id)
      @available_box = @box.available_box_for(@patient.id)
    end

    it "has status available" do
      expect( @available_target.status).to eq("available")
    end

    it "has box with current_exercise_tree_id of exercise2" do
      expect( @available_box.current_exercise_tree_id).to eq(@exercise2.id)
    end

    it "conclude target when last exercise_tree is completed" do
      @exercise2.available_exercise_tree_for(@patient.id).update(status: :complete)
      @target.concluded_exercise_tree_for @patient, @exercise2
      available_target = AvailableTarget.where(patient: @patient, target:@target).first
      expect(available_target.status).to eq("complete")
    end

  end

  context "update_exercise_tree" do

    before(:each) do
      @target = Target.first
      @exercise_id = @target.exercise_tree_ids.first
      @exercise = ExerciseTree.find(@exercise_id)
    end

    it "update name value" do
      new_name = "New Exercise Name"
      expect( @exercise.name ).to_not eq(new_name)
      @target.update_exercise_tree( @exercise_id, {name: new_name})

      expect( ExerciseTree.find(@exercise_id).name ).to eq(new_name)
    end

    it "update published value" do
      new_unpublished = !@exercise.unpublished?

      # @target.update_exercise_tree( @exercise_id, {published: !new_unpublished})
      @exercise.set_published(!new_unpublished)

      expect( ExerciseTree.find(@exercise_id).unpublished? ).to eq(new_unpublished)
    end

    it "clone exercise_tree if pages value is defined" do
      updated_exercise = @target.update_exercise_tree( @exercise_id, {name: "Test Exercise", pages: [get_page_with_correct_hash("test_root")]})
      expect( updated_exercise.id ).to_not eq(@exercise_id)
    end

    it "archive previous exercise_tree if pages value is defined" do
      @target.update_exercise_tree( @exercise_id, {name: "Test Exercise", pages: [get_page_with_correct_hash("test_root")]})
      expect( Tree.find(@exercise_id).type ).to eq("ArchivedTree")
    end

    it "don't clone exercise_tree if pages value is not defined" do
      updated_exercise = @target.update_exercise_tree( @exercise_id, {name: "Test Exercise"})
      expect( updated_exercise.id ).to eq(@exercise_id)
    end

  end

  context "destroy" do
    before(:each) do
      @patient = Patient.find("patient4")

      @target = Target.first
      @target_box = @target.box
      @target_level = @target_box.level

      @target.destroy!
    end

    it "update the target informations in the available_box" do
      next_target = @target_box.targets.with_deleted.where.not(id: @target.id).first
      expect( @target_box.available_box_for(@patient.id).current_target_id).to eq(next_target.id)
    end

    it "set the next target as available" do
      next_target = @target_box.targets.with_deleted.where.not(id: @target.id).first
      expect( next_target.available_target_for(@patient.id).status).to eq("available")
    end

    it "soft-delete the available target and keep him as available" do
      expect( AvailableTarget.with_deleted.where(target_id: @target.id, patient_id: @patient.id).where.not(status: "available").count).to eq(0)
    end

  end

end
