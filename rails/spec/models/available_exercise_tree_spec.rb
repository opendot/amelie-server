require 'rails_helper'
require 'shared/cognitive_session_utils.rb'

RSpec.describe AvailableExerciseTree, type: :model do
  include_context "cognitive_session_utils"

  context "total_attempts_count" do

    before(:each) do
      @patient = Patient.first
      @user = Researcher.first
      @exercise_tree = ExerciseTree.first
    end

    it "is 0 at first" do
      expect(@exercise_tree.available_exercise_tree_for(@patient.id).total_attempts_count).to eq 0
    end

    it "is 1 after first session" do
      create_and_conclude_session SecureRandom.uuid(), @exercise_tree, true
      expect(@exercise_tree.available_exercise_tree_for(@patient.id).total_attempts_count).to eq 1
    end

    it "is the count of sessions, no matter if correct or no" do
      num_correct = 3
      num_incorrect = 2
      num_incorrect.times do |i|
        create_and_conclude_session SecureRandom.uuid(), @exercise_tree, false
      end
      num_correct.times do |i|
        create_and_conclude_session SecureRandom.uuid(), @exercise_tree, false
      end
      expect(@exercise_tree.available_exercise_tree_for(@patient.id).total_attempts_count).to eq(num_correct + num_incorrect)
    end

  end
end
