class Api::V1::EyetrackerLockEventsController < Api::V1::SessionEventsController
  def broadcast_event_message
    ActionCable.server.broadcast("cable_#{ENV['SERVER_TO_DESKTOP_SOCKET_CHANNEL_NAME']}", {type: "LOCK_EYETRACKER", data: nil}.to_json)
  end

  protected

  def session_event_params
    params.permit(:id, :type, :page_id, :training_session_id)
  end
end
