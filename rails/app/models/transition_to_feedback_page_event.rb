class TransitionToFeedbackPageEvent < TransitionToPageEvent
  require_dependency 'transition_to_page_event'    

  # Event of showing a feedback page before showing the next page

  # Send the message manually, since we have to add the page after the feedback
  skip_callback :create, :after, :broadcast_transition_message, raise: false

  def broadcast_transition_to_page_message(next_page_id)
    ActionCable.server.broadcast("cable_#{ENV['SERVER_TO_DESKTOP_SOCKET_CHANNEL_NAME']}", {
      type: "TRANSITION_TO_FEEDBACK_PAGE",
      data: {page_id: self.next_page_id, next_page_id: next_page_id, training_session_id: self.training_session_id, type: TrainingSession.find(self.training_session_id).type}
    }.to_json)
  end

  protected

  def broadcast_transition_message
    # Do nothing
  end

end