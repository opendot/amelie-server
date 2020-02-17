class TransitionToPageEvent < SystemEvent
  require_dependency 'session_event'  

  # This attr_accessor means that we want to disable the websocket message. Used by the sync functionality.
  # Normally it would not be set.
  attr_writer :skip_broadcast_callback

  after_create :broadcast_transition_message

  skip_callback :save, :before, :ensure_next_page_id_is_nil

  has_one :immutable_page, :foreign_key => 'next_page_id'

  def skip_broadcast_callback
    @skip_broadcast_callback || false
  end

  protected
      
  def broadcast_transition_message
    # Stop this method if you have been requested to avoid broadcasting.
    if skip_broadcast_callback
      return
    end

    ActionCable.server.broadcast("cable_#{ENV['SERVER_TO_DESKTOP_SOCKET_CHANNEL_NAME']}", {
      type: "TRANSITION_TO_PAGE",
      data: {page_id: self.next_page_id, training_session_id: self.training_session_id, type: TrainingSession.find(self.training_session_id).type}
    }.to_json)
  end
end
