class Api::V1::TransitionToPageEventsController < Api::V1::SessionEventsController
  def session_event_params
    params.permit(:type, :next_page_id, :card_id, :page_id, :training_session_id)
  end

  def render_event(event)
    render json: event, serializer: Api::V1::TransitionToPageEventSerializer, status: :created
  end
end
