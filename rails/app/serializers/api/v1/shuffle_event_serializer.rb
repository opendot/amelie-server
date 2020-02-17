class Api::V1::ShuffleEventSerializer < ActiveModel::Serializer
  def attributes(arg1, arg2)
    layouts = PageLayout.where(page_id: object.next_page_id)
    data = {}
    data[:id] = object.id
    data[:type] = object.type
    data[:timestamp] = object.timestamp
    data[:cards] = []
    layouts.each do |layout|
      single_data = {}
      single_data[:id] = layout.card_id
      single_data[:x_pos] = layout.x_pos
      single_data[:y_pos] = layout.y_pos
      single_data[:scale] = layout.scale
      data[:cards].push(single_data)
    end
    return data
  end
end
