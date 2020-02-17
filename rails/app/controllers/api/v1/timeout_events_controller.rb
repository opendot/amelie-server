class Api::V1::TimeoutEventsController < Api::V1::SessionEventsController
  def broadcast_event_message
    # Nothing to send. A message will be sent by the TransitionToPresentationPageEvent.
  end

  protected

  def render_event(event)
    render json: event, serializer: Api::V1::SessionEventSerializer, status: :created
  end

  def session_event_params
    params.permit(:id, :type, :card_id, :page_id, :training_session_id )
  end

  def on_event_created
    @session = TrainingSession.find(params[:training_session_id])

    case @session.type
    when "CommunicationSession"
      return on_generic_event_created
    when "CognitiveSession"
      return on_cognitive_event_created
    else
      return on_generic_event_created
    end
  end

  private

  # Generic behaviour, send a message on socket
  def on_generic_event_created
    return true
  end

  # Behaviour for CognitiveSession
  def on_cognitive_event_created
    return false if params[:page_id].nil?

    # Show the presentation page
    exercise = @session.exercise_tree
    unless exercise.nil? || exercise.presentation_page_id.nil?
      presentation = exercise.presentation_page.get_a_clone_with_next_page(params[:page_id])
      transition_event = TransitionToPresentationPageEvent.create!(next_page_id: presentation.id, training_session_id: params[:training_session_id])
      transition_event.broadcast_transition_to_page_message(params[:page_id])
    end

    return true
  end
end