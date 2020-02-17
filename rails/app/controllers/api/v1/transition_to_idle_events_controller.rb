class Api::V1::TransitionToIdleEventsController < Api::V1::TransitionToPageEventsController
  def broadcast_event_message
    ActionCable.server.broadcast("cable_#{ENV['SERVER_TO_DESKTOP_SOCKET_CHANNEL_NAME']}", {type: "TRANSITION_TO_IDLE", data: nil}.to_json)
  end

  protected

  def render_event(event)
    render json: event, serializer: Api::V1::SessionEventSerializer, status: :created
  end
end
