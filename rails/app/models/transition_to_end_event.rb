class TransitionToEndEvent < SystemEvent
  # This attr_accessor means that we want to disable the websocket message. Used by the sync functionality.
  # Normally il would not be set.
  attr_accessor :skip_broadcast_callback

  after_create :broadcast_transition_message

  def skip_broadcast_callback
    @skip_broadcast_callback || false
  end

  protected

  def broadcast_transition_message
    if skip_broadcast_callback
      return
    end
    ActionCable.server.broadcast("cable_#{ENV['SERVER_TO_DESKTOP_SOCKET_CHANNEL_NAME']}", {type: "TRANSITION_TO_END", data: {page_id: self.page_id, training_session_id: self.training_session_id}}.to_json)
  end
end
