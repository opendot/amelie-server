class Api::V1::Patients::AvailableExerciseTrees::CardSerializer < ActiveModel::Serializer
  attributes :id, :label, :level, :selection_action, :selection_sound
  has_one :content, serializer: Api::V1::ContentSerializer

  def selection_sound
    unless object.selection_sound.url.nil?
      object.selection_sound.url
    else
      nil
    end
  end
end
