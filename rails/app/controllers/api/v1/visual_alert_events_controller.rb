class Api::V1::VisualAlertEventsController < Api::V1::SessionEventsController
  def broadcast_event_message
    ActionCable.server.broadcast("cable_#{ENV['SERVER_TO_DESKTOP_SOCKET_CHANNEL_NAME']}", {type: "SHOW_VISUAL_ALERT", data: {id: params[:visual_alert_id]}}.to_json)
  end

  protected

  def session_event_params
    params.permit(:id, :type, :page_id, :training_session_id, :visual_alert_id)
  end

  def filter_parameters
    parameters = session_event_params.deep_dup
    parameters.delete(:visual_alert_id)
    return parameters
  end
end
