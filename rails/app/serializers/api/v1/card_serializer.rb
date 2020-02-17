class Api::V1::CardSerializer < ActiveModel::Serializer
  attributes :id, :label, :level, :type, :patient_id, :selection_action, :selection_sound
  has_one :content, serializer: Api::V1::ContentSerializer
  has_many :card_tags, serializer: Api::V1::TagSerializer

  def selection_sound
    unless object.selection_sound.url.nil?
      object.selection_sound.url
    else
      nil
    end
  end
end
