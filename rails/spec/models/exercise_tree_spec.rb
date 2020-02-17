require 'rails_helper'

RSpec.describe ExerciseTree, type: :model do

  before(:each) do
    @patient = Patient.create(id: SecureRandom.uuid(), name: "Sofia", surname: "Drera", birthdate: FFaker::Time.date)
    @page1 = Page.create!( id: SecureRandom.uuid())

    @level = Level.create!(value: 1, name: "Test Level")
    @box = Box.create!(name: "Test Box", level: @level)
    @target = Target.create!(name: "Test Target")
    @box.add_target(@target)
  end

  context "conclude_for patient" do

    before(:each) do
      @exercise1 = ExerciseTree.create!( id: SecureRandom.uuid(), name: "Test 1", root_page: @page1)
      @target.add_exercise_tree(@exercise1, 1)
      @exercise2 = ExerciseTree.create!( id: SecureRandom.uuid(), name: "Test 2", root_page: @page1)
      @target.add_exercise_tree(@exercise2, 2)

      @exercise1.conclude_for @patient
      @available_exercise1 = @exercise1.available_exercise_tree_for(@patient.id)
      @available_box = @box.available_box_for(@patient.id)
    end

    it "has status complete" do
      expect( @available_exercise1.status).to eq("complete")
    end

    it "has box with current_exercise_tree_id of exercise2" do
      expect( @available_box.current_exercise_tree_id).to eq(@exercise2.id)
    end

    it "conclude target when last exercise is completed" do
      @exercise2.conclude_for @patient
      expect(AvailableTarget.where(patient: @patient, target:@target).first.status).to eq("complete")
    end

    it "conclude box when last exercise is completed" do
      @exercise2.conclude_for @patient
      expect(@box.available_box_for(@patient.id).status).to eq("complete")
    end

    it "conclude level when last exercise is completed" do
      @exercise2.conclude_for @patient
      expect(@level.available_level_for(@patient.id).status).to eq("complete")
    end

  end

  context "force completion for patient" do

    before(:each) do
      @exercise1 = ExerciseTree.create!( id: SecureRandom.uuid(), name: "Test 1", root_page: @page1)
      @exercise2 = ExerciseTree.create!( id: SecureRandom.uuid(), name: "Test 2", root_page: @page1)

      @target.add_exercise_tree(@exercise1, 1)
      @target.add_exercise_tree(@exercise2, 2)

      @exercise1.conclude_for @patient

      @available_exercise1 = @exercise1.available_exercise_tree_for(@patient.id)
      @available_box = @box.available_box_for(@patient.id)
    end

    it "has status complete and is marked as force-completed" do
      @exercise1.completed_by @patient, true, true
      @available_exercise1.reload

      expect(@available_exercise1.status).to eq("complete")
      expect(@available_exercise1.force_completed).to be true
    end

  end

  context "mark as todo for patient" do

    before(:each) do
      @exercise1 = ExerciseTree.create!(id: SecureRandom.uuid(), name: "Test 1", root_page: @page1)

      @exercise1.available_exercise_tree_for(@patient.id).update!(consecutive_conclusions_required: 1)

      @target.add_exercise_tree(@exercise1, 1)

      @exercise1.completed_by @patient, true

      @available_exercise1 = @exercise1.available_exercise_tree_for(@patient.id)
      @available_box = @box.available_box_for(@patient.id)
    end

    it "resets hierarchy status to available" do
      expect(@available_exercise1.status).to eq("complete")
      expect(@target.available_target_for(@patient.id).status).to eq("complete")
      expect(@box.available_box_for(@patient.id).status).to eq("complete")
      expect(@level.available_level_for(@patient.id).status).to eq("complete")

      @exercise1.set_as_available_for @patient

      @available_exercise1 = @exercise1.available_exercise_tree_for(@patient.id)
      @available_box = @box.available_box_for(@patient.id)

      expect(@available_exercise1.status).to eq("available")
      expect(@available_exercise1.conclusions_count).to eq(0)
      expect(@target.available_target_for(@patient.id).status).to eq("available")

      expect(@box.available_box_for(@patient.id).status).to eq("available")
      expect(@level.available_level_for(@patient.id).status).to eq("available")
    end

  end

  context "move current target and current exercise tree after manual status change" do

    before(:each) do
      @exercise1 = ExerciseTree.create!(id: SecureRandom.uuid(), name: "Test 1", root_page: @page1)
      @exercise1.available_exercise_tree_for(@patient.id).update!(consecutive_conclusions_required: 1)

      @target.add_exercise_tree(@exercise1, 1)

      @target2 = Target.create!(name: "Test Target 2")
      @box.add_target(@target2, 2)

      @exercise2 = ExerciseTree.create!(id: SecureRandom.uuid(), name: "Test 2", root_page: @page1)
      @exercise2.available_exercise_tree_for(@patient.id).update!(consecutive_conclusions_required: 1)

      @target2.add_exercise_tree(@exercise2, 0)

      @available_box = @box.available_box_for(@patient.id)
    end

    it "sets target to next available target in box" do
      # Initial current target should be the first one
      expect(@available_box.current_target_id).to eq(@target.id)

      @exercise1.completed_by @patient, true
      @available_box.reload

      # Now that we completed the first exercise, the box current_target should point to the next incomplete target
      expect(@available_box.current_target_id).to eq(@target2.id)

      @exercise2.completed_by @patient, true
      @available_box.reload

      # Now that we also completed the second exercise, the box current_target should be left as it was (existing behaviour)
      expect(@available_box.current_target_id).to eq(@target2.id)

      # Now we mark the first exercise as available again, hence the first target becomes incomplete
      @exercise1.set_as_available_for @patient
      @available_box.reload

      # At this point, the box current target should be pointing again to target 1, that has become available again
      expect(@available_box.current_target_id).to eq(@target.id)
      expect(@available_box.current_target_name).to eq(@target.name)

      # ...and the available box current exercise tree should be updated accordingly
      expect(@available_box.current_exercise_tree_id).to eq(@exercise1.id)
      expect(@available_box.current_exercise_tree_name).to eq(@exercise1.name)
    end
  end

  context "automatic link between ExerciseTree and Patient" do
    it "is not created with ExerciseTree creation" do
      exercise1 = ExerciseTree.create!(id: "test_1", name: "ExerciseTree Test", root_page: @page1)
      expect(exercise1.available_exercise_trees.where.not(patient_id: nil).count).to eq(0)
    end

    it "is created for the first ExerciseTree of every Box with Patient creation" do
      patient = Patient.create!(id: "patient_test", name: "Andrea", surname: "Rossi", birthdate: 20.years.ago)

      all_boxes_with_exercise_trees = Box.joins(:targets => :exercise_trees).group('boxes.id').having('count(box_id) > 0').count
      # all_boxes_with_exercise_trees = {1=>9, 2=>6, 3=>6, 4=>9}
      expect(patient.available_exercise_trees.count).to eq(all_boxes_with_exercise_trees.count)
    end
  end

  context "default values" do
    before(:each) do
      @exercise_tree = ExerciseTree.create!(id: "test_1", name: "ExerciseTree Test", root_page: @page1)

      # Assign some default values
      @consecutive_conclusions_required = 4
      @default_available_exercise_tree = @exercise_tree.available_exercise_tree
      @default_available_exercise_tree.update!(consecutive_conclusions_required: @consecutive_conclusions_required)

      @target.add_exercise_tree(@exercise_tree, 1)
    end

    it "is assigned to all new AvailbleExerciseTree" do
      available_exercise_tree = @exercise_tree.available_exercise_tree_for(Patient.last.id)
      expect(available_exercise_tree.status).to eq(@default_available_exercise_tree.status)
      expect(available_exercise_tree.consecutive_conclusions_required).to eq(@consecutive_conclusions_required)
    end

    it "is assigned to AvailbleBox" do
      available_box = @exercise_tree.available_box_for(Patient.last.id)
      expect(available_box.current_exercise_tree_consecutive_conclusions_required).to eq(@consecutive_conclusions_required)
    end

    it "update all not completed AvailableExerciseTree when values are updated" do
      @exercise_tree.update_default_available_exercise_tree!(consecutive_conclusions_required: @consecutive_conclusions_required+1 )
      @default_available_exercise_tree = @exercise_tree.available_exercise_tree
      available_exercise_tree = @exercise_tree.available_exercise_tree_for(Patient.last.id)
      expect(available_exercise_tree.status).to eq(@default_available_exercise_tree.status)
      expect(available_exercise_tree.consecutive_conclusions_required).to eq(@default_available_exercise_tree.consecutive_conclusions_required)
    end

    it "update all not completed AvailableBox when values are updated" do
      @exercise_tree.update_default_available_exercise_tree!(consecutive_conclusions_required: @consecutive_conclusions_required+1 )
      @default_available_exercise_tree = @exercise_tree.available_exercise_tree
      available_box = @exercise_tree.available_box_for(Patient.last.id)

      expect(available_box.current_exercise_tree_consecutive_conclusions_required).to eq(@default_available_exercise_tree.consecutive_conclusions_required)
    end

  end

  context "published" do
    before(:each) do
      @exercise_tree = ExerciseTree.create!(id: "test_1", name: "ExerciseTree Test", root_page: @page1)

      # Assign some default values
      @consecutive_conclusions_required = 4
      @default_available_exercise_tree = @exercise_tree.available_exercise_tree
      @default_available_exercise_tree.update!(status: :unpublished, consecutive_conclusions_required: @consecutive_conclusions_required)

      @target.add_exercise_tree(@exercise_tree, 1)
    end

    it "has scope that founds all published ExerciseTrees" do
      exercises = ExerciseTree.published

      expect(exercises.count).to eq(ExerciseTree.count-1)
      expect(exercises.include?@exercise).to be false
    end

    it "has scope that founds all unpublished ExerciseTrees" do
      exercises = ExerciseTree.unpublished

      expect(exercises.count).to eq(1)
      expect(exercises.first.id).to eq(@exercise_tree.id)
    end

  end

  context "destroy" do
    before(:each) do
      @exercise = Target.first.exercise_trees.first
      @exercise_target = @exercise.target
      @exercise_box = @exercise_target.box
      @exercise_level = @exercise_box.level

      if @exercise.update(type: 'ArchivedTree')
        @exercise.archive
      end
    end

    it "update the exercise informations in the available_box" do
      next_exercise = @exercise_target.target_layouts.with_deleted.where.not(exercise_tree_id: @exercise.id).first.exercise_tree
      expect( @exercise_box.available_box_for(@patient.id).current_exercise_tree_id).to eq(next_exercise.id)
    end

    it "set the next exercise as available" do
      next_exercise = @exercise_target.target_layouts.with_deleted.where.not(exercise_tree_id: @exercise.id).first.exercise_tree
      expect( next_exercise.available_exercise_tree_for(@patient.id).status).to eq("available")
    end

    it "soft-delete the available exercise and keep him as available" do
      expect( AvailableExerciseTree.with_deleted.where(exercise_tree_id: @exercise.id, patient_id: @patient.id).where.not(status: "available").count).to eq(0)
    end

  end

end
