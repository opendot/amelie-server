class Api::V1::Targets::ListExerciseTreeSerializer < ActiveModel::Serializer
  attributes :id, :name, :type, :root_page_id, :updated_at, :strong_feedback_page_id, :position, :published, :number_of_pages

  def published
    !object.unpublished?
  end

  def number_of_pages
    object.root_page.subtree.count
  end

end
