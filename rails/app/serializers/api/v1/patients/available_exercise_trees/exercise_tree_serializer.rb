class Api::V1::Patients::AvailableExerciseTrees::ExerciseTreeSerializer < ActiveModel::Serializer
  attributes :id, :name, :type, :presentation_page, :strong_feedback_page, :pages,
    :consecutive_conclusions_required
  
  def presentation_page
    unless object.presentation_page_id.nil?
      Api::V1::Patients::AvailableExerciseTrees::PageSerializer.new(object.presentation_page)
    end
  end

  def strong_feedback_page
    unless object.strong_feedback_page_id.nil?
      Api::V1::Patients::AvailableExerciseTrees::PageSerializer.new(object.strong_feedback_page)
    end
  end

  def pages
    ActiveModelSerializers::SerializableResource.new(object.root_page.subtree.order(:ancestry_depth).includes(cards:[:card_tags], page_layouts:[card:[:card_tags]]), each_serializer: Api::V1::Patients::AvailableExerciseTrees::PageSerializer)
  end
  
  def consecutive_conclusions_required
    object.available_exercise_trees.where(patient_id: nil).first.consecutive_conclusions_required
  end

end
