require 'rails_helper'
require 'shared/cognitive_session_utils.rb'

RSpec.describe CognitiveSession, type: :model do
  include_context "cognitive_session_utils"
  
  before(:each) do
    @user = Researcher.first
    @patient = Patient.order(:id).last

    @exercise = ExerciseTree.first
    @session = create_cognitive_session "CognitiveSession1", @exercise

  end

  context "correct_answers" do

    it "return all answers if they're all correct" do
      # Answer all questions correctly
      answer_all_questions @session, @exercise, true

      expect(@session.correct_answers.length).to eq(@session.session_events.where(type: "PatientEyeChoiceEvent").count)

    end

    it "return 0 if they're all wrong" do
      # Answer all questions wrongly
      answer_all_questions @session, @exercise, false

      expect(@session.correct_answers.length).to eq(0)

    end

    it "return only correct answers" do
      n = 4
      # Answer to n questions correctly
      answer_n_questions @session, @exercise.root_page, n, true

      expect(@session.correct_answers.length).to eq(n)

    end

    it "return the correct number even if the card is used in another page" do
      n = 2
      # Answer to n questions correctly
      next_page = answer_n_questions @session, @exercise.root_page, n, true
      # Answer wrong to other
      answer_n_questions @session, next_page, @exercise.root_page.subtree.length, false

      # Use a card in another exercise
      last_page = @exercise.root_page.subtree.last
      wrong_card = last_page.page_layouts.where(correct: false).first.card

      new_page = CustomPage.create(id: "copy_#{last_page.id}", name: "Page with correct card", patient_id: @patient.id, page_tag_ids: [])
      CognitivePageLayout.create!(page: new_page, card: wrong_card, x_pos: 0.3, y_pos: 0.2, scale: 1, correct: true)
      another_exercise = ExerciseTree.create!(id: "another_exercise", name: "Another exercise", root_page: new_page, presentation_page_id: PresentationPage.first.id, strong_feedback_page: FeedbackPage.strong_random.first)

      expect(@session.correct_answers.length).to eq(n)
    end

  end

  context "wrong_answers" do
    it "return only wrong answers" do
      n = 2
      # Answer to n questions wrongly
      next_page = answer_n_questions @session, @exercise.root_page, n, false
      answer_n_questions @session, next_page, @exercise.max_page_depth, true

      expect(@session.wrong_answers.length).to eq(n)

    end

    it "return the correct number even if the card is used in another page" do
      n = 2
      # Answer to n questions wrongly
      next_page = answer_n_questions @session, @exercise.root_page, n, false
      answer_n_questions @session, next_page, @exercise.max_page_depth, true

      # Use a card in another exercise
      last_page = @exercise.root_page.subtree.last
      correct_card = last_page.page_layouts.where(correct: true).first.card

      new_page = CustomPage.create(id: "copy_#{last_page.id}", name: "Page with correct card", patient_id: @patient.id, page_tag_ids: [])
      CognitivePageLayout.create!(page: new_page, card: correct_card, x_pos: 0.3, y_pos: 0.2, scale: 1, correct: false)
      another_exercise = ExerciseTree.create!(id: "another_exercise", name: "Another exercise", root_page: new_page, presentation_page_id: PresentationPage.first.id, strong_feedback_page: FeedbackPage.strong_random.first)

      expect(@session.wrong_answers.length).to eq(n)
    end

  end

  context "exercise_tree" do
    it "return the correct exercise tree" do
      expect(@session.exercise_tree.id).to eq(@exercise.id)
    end

    it "return the first exercise tree" do
      ExerciseTree.where.not(id: @exercise.id).each do |exercise|
        LoadTreeEvent.create!(training_session: @session, tree_id: exercise.id)
      end
      expect(@session.exercise_tree.id).to eq(@exercise.id)
    end

    it "handle sessions with no LoadTreeEvent" do
      empty_session = create_only_cognitive_session "CognitiveSessionEmpty"

      expect(empty_session.exercise_tree).to be_nil
    end
  end

  context "results" do
    before(:each) do
      @session_correct = create_and_conclude_session "CognitiveSessionCorrect", @exercise, true
      @session_incorrect = create_and_conclude_session "CognitiveSessionInorrect", @exercise, false
      @session_interrupted = create_and_interrupt_session "CognitiveSessionInterrupted", @exercise, 2

      @session_partially_correct = create_cognitive_session "CognitiveSessionPartiallyCorrect", @exercise
      @n_incorrect = 2
      next_page = answer_n_questions @session_partially_correct, @exercise.root_page, @n_incorrect, false
      answer_n_questions @session_partially_correct, next_page, @exercise.max_page_depth, true
      conclude_session @session_partially_correct

    end

    it "return passed for completed cognitive session" do
      results = @session_correct.results
      expect(results["passed"]).to be true
    end

    it "return not passed for incompleted cognitive session" do
      results = @session_incorrect.results
      expect(results["passed"]).to be false
    end

    it "return not passed for interrupted cognitive session" do
      results = @session_interrupted.results
      expect(results["passed"]).to be false
    end

    it "return correct number of wrong answers" do
      results = @session_partially_correct.results
      expect(results["wrong_answers"]).to eq(@n_incorrect)
    end

    it "return correct number of correct answers" do
      results = @session_partially_correct.results
      expect(results["correct_answers"]).to eq(@exercise.max_page_depth+1 - @n_incorrect)
    end
  end

end