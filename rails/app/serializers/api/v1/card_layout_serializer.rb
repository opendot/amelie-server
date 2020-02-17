class Api::V1::CardLayoutSerializer < ActiveModel::Serializer
  def attributes(arg1, arg2)
    data = ActiveModelSerializers::SerializableResource.new(object.card, serializer: Api::V1::CardSerializer).serializable_hash
    data[:x_pos] = object.x_pos
    data[:y_pos] = object.y_pos
    data[:scale] = object.scale
    data[:correct] = object.correct
    data[:next_page_id] = object.next_page_id
    data[:selectable] = object.selectable
    data[:hidden_link] = object.hidden_link
    return data
  end
end
