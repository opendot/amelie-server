class Api::V1::ArchivedCardsController < Api::V1::CardsController
  def get_viewable_cards
    if params.has_key?(:card_tag_id)
      cards = Tag.find(params[:card_tag_id]).cards
    else
      cards = Card.all
    end
    if params.has_key?(:type)
      cards = cards.where(type: params[:type])
    end
    return cards
  end
end
