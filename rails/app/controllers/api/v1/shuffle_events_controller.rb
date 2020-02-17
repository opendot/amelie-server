class Api::V1::ShuffleEventsController < Api::V1::SessionEventsController
  def create
    # session = TrainingSession.find(params[:training_session_id])
    # patient = session.patient
    event_params = session_event_params.deep_dup
    current_page = Page.find(params[:page_id])
    new_page = current_page.dup
    new_page.id = SecureRandom.uuid()
    new_page.ancestry = nil
    new_page.ancestry_depth = 0
    ShuffleEvent.transaction do
      unless new_page.save
        render json: { errors: new_page.errors.full_messages }, status: :unprocessable_entity
        raise ActiveRecord::Rollback, "Can't save the new page."
      end
      
      event_params.delete(:cards)
      event = ShuffleEvent.new(event_params)
      event.next_page_id = new_page.id

      session_event_params[:cards].each do |card|
        page_layout = PageLayout.new(card)
        page_layout.card_id = card[:id]
        page_layout.page_id = new_page.id
        page_layout.id = SecureRandom.uuid()
        unless page_layout.save
          render json: {errors: page_layout.errors.full_messages}, status: :unprocessable_entity
          raise ActiveRecord::Rollback, "Can't save a page layout."
        end
      end

      if event.save
        broadcast_event_message(params[:cards])
        render_event(event)
      else
        render json: {errors: event.errors.full_messages}, status: :unprocessable_entity
        raise ActiveRecord::Rollback, "Can't save the shuffle event."
      end
    end
  end

  protected

  def session_event_params
    params.permit(:id, :type, :page_id, :training_session_id, cards:[:id, :x_pos, :y_pos, :scale])
  end

  def broadcast_event_message(cards)
    ActionCable.server.broadcast("cable_#{ENV['SERVER_TO_DESKTOP_SOCKET_CHANNEL_NAME']}", {type:"SHUFFLE", cards: params[:cards]}.to_json)
  end

  def render_event(event)
    render json: event, serializer: Api::V1::ShuffleEventSerializer, status: :created
  end
end
