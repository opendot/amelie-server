class Api::V1::SoundAlertEventsController < Api::V1::SessionEventsController
  def create
    if params.has_key?(:training_session_id)
      super
    else
      broadcast_event_message
      event = SoundAlertEvent.new
      render_event(event)
    end
  end

  def broadcast_event_message
    ActionCable.server.broadcast("cable_#{ENV['SERVER_TO_DESKTOP_SOCKET_CHANNEL_NAME']}", {type: "PLAY_SOUND", data: {group: params[:sound][:group], id: params[:sound][:id]}}.to_json)
  end

  protected

  def session_event_params
    params.permit(:id, :type, :page_id, :training_session_id, sound: [:group, :id])
  end

  def filter_parameters
    parameters = session_event_params.deep_dup
    parameters.delete(:sound)
    return parameters
  end
end
