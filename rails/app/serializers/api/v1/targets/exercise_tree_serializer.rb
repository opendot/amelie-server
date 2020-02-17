class Api::V1::Targets::ExerciseTreeSerializer < Api::V1::TreeSerializer
  attributes :updated_at, :published, :position, :number_of_pages, :consecutive_conclusions_required, :strong_feedback_page_id
  belongs_to :presentation_page, serializer: Api::V1::PageSerializer

  def published
    !object.unpublished?
  end

  def position
    object.target_layout.position
  end
  
  def pages
    ActiveModelSerializers::SerializableResource.new(object.root_page.subtree.order(:ancestry_depth).includes(cards:[:card_tags], page_layouts:[card:[:card_tags]]), each_serializer: Api::V1::PageSerializer)
  end
  
  def consecutive_conclusions_required
    object.available_exercise_trees.where(patient_id: nil).first.consecutive_conclusions_required
  end

end
