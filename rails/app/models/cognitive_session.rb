class CognitiveSession < TrainingSession

  def correct_answers
    page_layouts = PageLayout.where(page_id: self.session_events.patient_choices.select(:page_id))
    self.session_events.patient_choices
      .where(
        page_id: page_layouts.where(correct: true).select(:page_id),
        card_id: page_layouts.where(correct: true).select(:card_id)
      )
  end

  def wrong_answers
    page_layouts = PageLayout.where(page_id: self.session_events.patient_choices.select(:page_id))
    self.session_events.patient_choices
      .where(
        page_id: page_layouts.where(correct: false).select(:page_id),
        card_id: page_layouts.where(correct: false).select(:card_id)
      )
  end

  # The first tree loaded in the session
  def exercise_tree_id
    first_load_tree = self.session_events.where(type: "LoadTreeEvent").order(:created_at).first
    if first_load_tree
      return first_load_tree.tree_id
    end
  end

  # The first tree loaded in the session
  def exercise_tree
    ExerciseTree.find_by(id: self.exercise_tree_id)
  end

  def is_exercise_completed_for_last_time?
    exercise = self.exercise_tree
    return exercise.consecutive_times_left_for(self.patient_id) == 1
  end

  # True if the patient answered all questions of the exercise
  def completed_session?
    if self.session_events.where(type: "TransitionToEndEvent").count == 0
      # Session is not ended
      return false
    end

    exercise = self.exercise_tree
    if exercise.nil?
      return false
    end

    # Check if the patient answered a page with highest ancestry depth
    return self.answered_page_with_highest_depth?(exercise)
  end

  def answered_page_with_highest_depth?(exercise = self.exercise_tree)
    return false if exercise.nil?
    self.session_events.patient_choices.where(
      page_id: Page.where(ancestry_depth: exercise.max_page_depth)
    ).count > 0
  end

  # True if the patient answered all questions correctly
  # This doesn't check if the exercise was completed
  def all_answers_are_correct?
    self.wrong_answers.limit(1).count == 0
  end

  def check_results_and_conclude
    # Check if the session was completed by the patient
    if self.completed_session?
      # Check if all answers are correct
      success = self.all_answers_are_correct?
      self.exercise_tree.completed_by self.patient, success
    end
  end

  def results
    results = {passed: false, patient_id: self.patient_id}

    exercise_tree = ExerciseTree.where(id: self.exercise_tree_id).includes(:available_exercise_trees, target: [:box, :available_targets]).first

    return results if exercise_tree.nil?

    results["exercise_tree_id"] = exercise_tree.id
    results["exercise_tree_name"] = exercise_tree.name
    results["target_id"] = exercise_tree.target_id
    results["target_name"] = exercise_tree.target_name
    results["box_id"] = exercise_tree.target_box.id
    results["box_name"] = exercise_tree.target_box.name

    passed = self.completed_session? && self.all_answers_are_correct?

    results["passed"] = passed

    results["correct_answers"] = self.correct_answers.size
    results["wrong_answers"] = self.wrong_answers.size

    available_exercise_tree = exercise_tree.available_exercise_tree_for self.patient_id
    results["exercise_tree_status"] = available_exercise_tree.status
    results["conclusions_count"] = available_exercise_tree.conclusions_count
    results["consecutive_conclusions_required"] = available_exercise_tree.consecutive_conclusions_required

    available_target = exercise_tree.available_target_for self.patient_id
    target = self.exercise_tree.target
    results["target_status"] = available_target.status
    results["target_completed_exercise_trees_count"] = target.completed_exercise_trees(self.patient).count
    results["target_exercise_trees_count"] = target.exercise_trees.count
    
    return results
  end
end
