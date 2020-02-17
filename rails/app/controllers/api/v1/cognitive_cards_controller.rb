class Api::V1::CognitiveCardsController < Api::V1::CardsController

  # GET /cognitive_cards?search=LabelOrTag&content=ContentType
  def index
    cards = CognitiveCard.left_outer_joins(:content, :card_tags).group(:id)

    # Search from tag or label
    if params.has_key?(:search)
      cards = cards.where("label LIKE :query", query: "#{params[:search]}%")
        .or(cards.where("tag LIKE :query", query: "#{params[:search]}%"))
    end

    # Search based on content type
    if params.has_key?(:content)
      cards = filter_by_content_type(cards)
    end

    paginate json: cards, each_serializer: Api::V1::CardSerializer, status: :ok, per_page: 25
  end

  # PUT /cognitive_cards/:id
  def update
    card = nil
    original_card = CognitiveCard.includes(:content, :card_tags).find(params[:id])
    CognitiveCard.transaction do
      card = create_clone_hash(original_card, "CognitiveCard", false)
      return if card.nil?
      card = Card.create(card)
      if original_card[:type] == "CognitiveCard" && !(params[:force_archived] == "true")
        original_card.update(type: "ArchivedCard")
      end
      parameters = card_params
      # Create the content. Will be nil if a new content has not been supplied.
      content = create_card_content(parameters)
      if content.nil?
        # There wasn't a new content. Clone the old one.
        content = clone_previous_content(original_card, card)
        return if content.nil?
      end
      parameters = process_audio_file(parameters)
      parameters.delete(:content)
      parameters.delete(:id)
      parameters.delete(:force_archived)
      if params[:force_archived] == "true"
        parameters.delete(:type)
      end
      parameters[:content_id] = content[:id]
      if params.has_key?(:card_tags)
        parameters[:card_tags] = []
      end
      card.update_attributes(parameters)
      card.content = content
      set_card_tags_and_render(card)
    end
  end
  
end
