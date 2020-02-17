require 'rails_helper'

RSpec.describe Box, type: :model do
  before(:each) do
    @level = Level.create!(value: 1, name: "Test Level")
  end

  context "create" do
    before(:each) do
      @box = Box.create!(name: "Test Box", level: @level)
    end

    it "has level" do
      expect(@box.level.id).to eq(@level.id)
    end

    it "has level delegates" do
      expect(@box.level_value).to eq(@level.value)
      expect(@box.level_name).to eq(@level.name)
    end

    it "require name" do
      box = Box.new(level: @level)
      expect(box.save).to be false
    end

  end

  context "add_target" do

    before(:each) do
      @box = Box.create!(name: "Test Box", level: @level)
      @patient = Patient.first
      @targets = []
      5.times do |i|
        @targets << Target.create!( name: "Test Target #{i+1}")
      end
    end

    it "has current_target_id nil at start" do
      expect(@box.available_box_for(@patient.id).current_target_id).to be_nil
    end

    it "update current_target_id" do
      @box.add_target(@targets[1], 1)
      expect(@box.available_box_for(@patient.id).current_target_id).to eq(@targets[1].id)
    end

    it "doesn't update by adding targets with higher position" do
      @box.add_target(@targets[1], 1)
      @box.add_target(@targets[2], 2)
      expect(@box.available_box_for(@patient.id).current_target_id).to eq(@targets[1].id)
    end

    it "doesn't update by adding targets with lower position" do
      @box.add_target(@targets[2], 2)
      expect(@box.available_box_for(@patient.id).current_target_id).to eq(@targets[2].id)

      @box.add_target(@targets[1], 1)
      expect(@box.available_box_for(@patient.id).current_target_id).to eq(@targets[2].id)
    end

    it "set the current_exercise_tree_id when adding a target" do
      target_with_exercise = Target.create!( name: "Test with Exercise")
      exercise = ExerciseTree.create!(id: SecureRandom.uuid(), name: "ExerciseTree AddTarget 1", root_page: Page.first)
      target_with_exercise.add_exercise_tree(exercise, 1)

      @box.add_target(target_with_exercise, 1)
      expect(@box.available_box_for(@patient.id).current_exercise_tree_id).to eq(exercise.id)
    end

    it "set the current_exercise_tree_id when adding an exercise to the target" do
      target_without_exercise = Target.create!( name: "Test with Exercise")

      @box.add_target(target_without_exercise, 1)

      exercise = ExerciseTree.create!(id: SecureRandom.uuid(), name: "ExerciseTree AddTarget 1", root_page: Page.first)
      target_without_exercise.add_exercise_tree(exercise, 1)

      expect(@box.available_box_for(@patient.id).current_exercise_tree_id).to eq(exercise.id)
    end

  end

  context "current_target" do

    before(:each) do
      @box = Box.create!(name: "Test Box", level: @level)
      @patient = Patient.first
      5.times do |i|
        target = Target.create!( name: "Test Target #{i+1}")
        @box.add_target(target, i)
      end
    end

    it "first_target return the first target" do
      expect(@box.first_target.name).to eq("Test Target 1")
    end

    it "return the first target not completed by the patient" do
      first = @box.current_target(@patient)
      expect(first.name).to eq("Test Target 1")
    end

    it "return the next target after the previous is completed" do
      first = @box.current_target(@patient)
      first.available_target_for(@patient.id).update(status: 1)

      second = @box.current_target(@patient)
      expect(second.name).to eq("Test Target 2")
      second.available_target_for(@patient.id).update(status: 1)

      third = @box.current_target(@patient)
      expect(third.name).to eq("Test Target 3")
    end

    it "return different targets for different patients" do
      patient0 = Patient.find("patient0")
      3.times do |i|
        @box.current_target(patient0).available_target_for(patient0.id).update(status: 1)
      end

      patient1 = Patient.find("patient1")
      2.times do |i|
        @box.current_target(patient1).available_target_for(patient1.id).update(status: 1)
      end

      patient2 = Patient.find("patient2")
      1.times do |i|
        @box.current_target(patient2).available_target_for(patient2.id).update(status: 1)
      end
      
      patient3 = Patient.find("patient3")

      expect(@box.current_target(patient0).name).to eq("Test Target 4")
      expect(@box.current_target(patient1).name).to eq("Test Target 3")
      expect(@box.current_target(patient2).name).to eq("Test Target 2")
      expect(@box.current_target(patient3).name).to eq("Test Target 1")
    end

  end

  context "calculate_progress" do

    before(:each) do
      @box = Box.create!(name: "Test Box", level: @level)
      @patient = Patient.first
      @num_targets = 5
      @num_targets.times do |i|
        target = Target.create!( name: "Test Target #{i+1}")
        @box.add_target(target, i)
      end
    end

    it "return 0 at the beginning" do
      expect(@box.calculate_progress(@patient)).to eq(0)
    end

    it "return 0 if patient is nil" do
      expect(@box.calculate_progress(nil)).to eq(0)
    end

    it "return 0 if box has no target" do
      empty_box = Box.create!(name: "Empty Box", level: @level)
      expect(empty_box.calculate_progress(@patient)).to eq(0)
    end

    it "return a new value when a target is completed" do
      first = @box.first_target
      first.available_target_for(@patient.id).update(status: 1)
      expect(@box.calculate_progress(@patient)).to eq(1.to_f/@num_targets)

      second = @box.current_target(@patient)
      second.available_target_for(@patient.id).update(status: 1)
      expect(@box.calculate_progress(@patient)).to eq(2.to_f/@num_targets)
    end

    it "return different progressions for different patients" do
      patient0 = Patient.find("patient0")
      3.times do |i|
        @box.current_target(patient0).available_target_for(patient0.id).update(status: 1)
      end

      patient1 = Patient.find("patient1")
      2.times do |i|
        @box.current_target(patient1).available_target_for(patient1.id).update(status: 1)
      end

      patient2 = Patient.find("patient2")
      1.times do |i|
        @box.current_target(patient2).available_target_for(patient2.id).update(status: 1)
      end
      
      patient3 = Patient.find("patient3")

      expect(@box.calculate_progress(patient0)).to eq(3.to_f/@num_targets)
      expect(@box.calculate_progress(patient1)).to eq(2.to_f/@num_targets)
      expect(@box.calculate_progress(patient2)).to eq(1.to_f/@num_targets)
      expect(@box.calculate_progress(patient3)).to eq(0)
    end

  end

  context "available?" do

    before(:each) do
      @box = Box.create!(name: "Test Box", level: @level)
      
      @level2 = Level.create!(value: 2, name: "Test Level 2" )
      @box2 = Box.create!(name: "Test Box 2", level: @level2)

      @level3 = Level.create!(value: 3, name: "Test Level 3")
      @box3 = Box.create!(name: "Test Box 3", level: @level3)
      
      @patient = Patient.order(:id).last
    end

    it "return true for boxes of Level 1" do
      expect(@box.available?@patient.id).to be true
    end

    it "return false for boxes above Level 1" do
      expect(@box2.available?@patient.id).to be false
      expect(@box3.available?@patient.id).to be false
    end

    it "return true after the previous Level is completed" do
      expect(@box2.available?@patient.id).to be false
      
      Level.where("value < ?", @level2.value).each do |l|
        l.available_level_for(@patient.id).update(status: :complete)
      end

      expect(@box2.available?@patient.id).to be true
      expect(@box3.available?@patient.id).to be false
    end

  end

  context "conclude_for patient" do

    before(:each) do
      @box1 = Box.create!(name: "Test Box 1", level: @level)
      @patient = Patient.first

      # Reset other levels
      AvailableLevel.where.not(level: @level).where(patient: @patient).update_all(status: :complete)
      
      @level2 = Level.create!(value: 2, name: "Test Level 2")
      @box2 = Box.create!(name: "Test Box 2", level: @level2)

      @box1.conclude_for @patient
      @available_box = @box1.available_box_for(@patient.id)
    end

    it "has status complete" do
      expect( @available_box.status).to eq("complete")
    end

    it "has progress 1" do
      expect( @available_box.progress).to eq(1)
    end

    it "has current_target_position equals to targets_count" do
      expect( @available_box.current_target_position).to eq(@available_box.targets_count)
    end

    it "has all targets complete" do
      expect( @available_box.current_target_position).to eq(@box1.targets.count)
    end

    it "has new boxes as available" do
      box2 = Box.create!(name: "Test Box 2", level: @level)
      expect(box2.available_box_for(@patient.id).status).to eq("available")
    end

    it "has next level available" do
      expect(@level2.available_level_for(@patient.id).status).to eq("available")
    end

    it "has first box of next level available" do
      expect(@box2.available_box_for(@patient.id).status).to eq("available")
    end

  end

  context "concluded_target_for patient" do

    before(:each) do
      @box = Box.create!(name: "Test Box 1", level: @level)
      @target1 = Target.create!(name: "Test Target 1")
      @box.add_target(@target1, 1)
      @target2 = Target.create!(name: "Test Target 2")
      @box.add_target(@target2, 2)
      @patient = Patient.first

      @available_target1 = @target1.available_target_for(@patient.id)
      @available_target1.update!(status: :complete)

      @box.concluded_target_for @patient, @target1
      @available_box = @box.available_box_for(@patient.id)
    end

    it "has status available" do
      expect( @available_box.status).to eq("available")
    end

    it "has progress 0.5" do
      expect( @available_box.progress).to eq(1.to_f/@box.targets.count)
    end

    it "has current_target_id of target2" do
      expect( @available_box.current_target_id).to eq(@target2.id)
    end

    it "has current_target_position equals to 2" do
      expect( @available_box.current_target_position).to eq(2)
    end

    it "is completed after concluding target2" do
      @target2.available_target_for(@patient.id).update!(status: :complete)
      @box.concluded_target_for @patient, @target2
      expect( @box.available_box_for(@patient.id).status).to eq("complete")
    end

  end

  context "concluded_exercise_tree_for patient" do

    before(:each) do
      @box = Box.create!(name: "Test Box 1", level: @level)
      @target = Target.create!(name: "Test Target 1")
      @box.add_target(@target, 1)
      @exercise1 = ExerciseTree.create!(id: "exercise1", name: "ExerciseTree Test 1", root_page: Page.first)
      @target.add_exercise_tree(@exercise1, 1)
      @exercise2 = ExerciseTree.create!(id: "exercise2", name: "ExerciseTree Test 2", root_page: Page.first)
      @target.add_exercise_tree(@exercise2, 2)

      @patient = Patient.first

      @available_exercise1 = @exercise1.available_exercise_tree_for(@patient.id)
      @available_exercise1.update!(status: :complete)

      @box.concluded_exercise_tree_for @patient, @target, @exercise1
      @available_box = @box.available_box_for(@patient.id)
    end

    it "has status available" do
      expect( @available_box.status).to eq("available")
    end

    it "has progress 0" do
      expect( @available_box.progress).to eq(0)
    end

    it "didn't change current_target_id" do
      expect( @available_box.current_target_id).to eq(@target.id)
    end

    it "has current_exercise_tree_id of exercise2" do
      expect( @available_box.current_exercise_tree_id).to eq(@exercise2.id)
    end

    it "has target_exercise_tree_position equals to 2" do
      expect( @available_box.target_exercise_tree_position).to eq(2)
    end

  end

  context "soft-delete" do
    before(:each) do
      @box = Box.create!(name: "Box Soft Delete 1", level: @level)

      @num_targets = 3
      @num_targets.times do |i|
        target = Target.create!( name: "Test Target #{i+1}")
        @box.add_target(target, i)
      end

      @box.destroy!
    end

    it "doesn't find the box with normal calls" do
      expect(Box.exists?(@box.id)).to be false
    end

    it "find the box if deleted are included" do
      expect(Box.with_deleted.exists?(@box.id)).to be true
    end

    it "find the deleted box for synchronization" do
      expect(Box.not_sync(1.day.ago).exists?(@box.id)).to be true
    end

    it "deleted all box_layouts" do
      expect(BoxLayout.where(box_id: @box.id).count).to eq(0)
    end

    it "soft-deleted all box_layouts" do
      expect(BoxLayout.with_deleted.where(box_id: @box.id).count).to eq(@num_targets)
    end

    it "deleted all availables" do
      expect(AvailableBox.where(box_id: @box.id).count).to eq(0)
    end

    it "soft-deleted all availables" do
      expect(AvailableBox.with_deleted.where(box_id: @box.id).count).to eq(Patient.count +1)
    end

  end

  context "destroy" do
    before(:each) do
      @patient = Patient.first

      # This is the only available box for the patient
      # This is the only box of the level
      @box = Box.find(3)
      @box_level = @box.level

      # Complete previous levels
      @patient.available_levels.where( :level_id => Level.where("value < ?", @box_level.value))
      .update_all(status: :complete)

      @box.destroy!
    end

    it "set the box level as completed" do
      expect( @box_level.available_level_for(@patient.id).status).to eq("complete")
    end

    it "set the next level as available" do
      next_level = Level.where("value > ?", @box_level.value).reorder(value: :asc).first
      expect( next_level.available_level_for(@patient.id).status).to eq("available")
    end

    it "set the boxes of the next level as available" do
      next_level = Level.where("value > ?", @box_level.value).reorder(value: :asc).first
      next_level.boxes.each do |b|
        expect( b.available_box_for(@patient.id).status).to eq("available")
      end
    end

    it "soft-delete the available box and keep him as available" do
      expect( AvailableBox.with_deleted.where(box_id: @box.id, patient_id: @patient.id).where.not(status: "available").count).to eq(0)
    end

  end

end
