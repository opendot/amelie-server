class Api::V1::TransitionToPageEventDetailedSerializer < Api::V1::SessionEventSerializer
  attributes :next_page_id, :cards

  def cards
    layouts = PageLayout.where(page_id: object.next_page_id)
    data = []
    layouts.each do |layout|
      single_data = {}
      single_data[:id] = layout.card_id
      single_data[:content] = layout.card.content
      single_data[:selection_action] = layout.card.selection_action
      single_data[:selection_sound] = layout.card.selection_sound
      single_data[:selectable] = layout.selectable
      single_data[:x_pos] = layout.x_pos
      single_data[:y_pos] = layout.y_pos
      single_data[:scale] = layout.scale
      data.push(single_data)
    end
    return data
  end
end
