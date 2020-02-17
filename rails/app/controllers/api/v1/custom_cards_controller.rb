class Api::V1::CustomCardsController < Api::V1::CardsController

  def get_viewable_cards
    if params.has_key?(:card_tag_id)
      cards = Tag.find(params[:card_tag_id]).cards
    else
      cards = Card.all
    end
    if params.has_key?(:type)
      cards = cards.where(type: params[:type])
    end
    if params.has_key?(:tag_query)
      cards = filter_by_query(cards, params[:tag_query])
    end
    if params.has_key?(:patient_id)
      cards = cards.where(patient_id: params[:patient_id])
    end
    return cards
  end

end
