class Api::V1::Patients::CognitiveSessionSerializer < Api::V1::Patients::TrainingSessionSerializer
  attributes :success, :steps

  def success
    object.completed_session? && object.all_answers_are_correct?
  end

  def steps
    obj = object.session_events.patient_choices.left_outer_joins(:card => [:page_layouts])
      .select(:id, :type, :page_id).select("page_layouts.correct AS correct").map do |step|
        {
          id: step.id,
          page_id: step.page_id,
          correct: (step.correct == 1),
        }
    end

    return obj.uniq
  end

end
