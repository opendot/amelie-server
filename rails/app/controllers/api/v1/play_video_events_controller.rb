class Api::V1::PlayVideoEventsController < Api::V1::SessionEventsController
  def create
    if session_event_params[:card_id].blank?
      render json: {errors: ["#{I18n.t :error_card_id_needed}"]}, status: :bad_request
      return
    end
    super
  end

  def broadcast_event_message
    ActionCable.server.broadcast("cable_#{ENV['SERVER_TO_DESKTOP_SOCKET_CHANNEL_NAME']}", {type: "PLAY_VIDEO", data: {card_id: session_event_params[:card_id]}}.to_json)
  end

  def render_event(event)
    render json: event, serializer: Api::V1::VideoEventSerializer, status: :created
  end

  protected

  def session_event_params
    params.permit(:id, :type, :card_id, :page_id, :training_session_id)
  end
end
