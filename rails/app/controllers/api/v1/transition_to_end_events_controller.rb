class Api::V1::TransitionToEndEventsController < Api::V1::SessionEventsController
  def broadcast_event_message
    # Do nothing. Already sent as an after_action.
  end

  protected

  def session_event_params
    params.permit(:id, :type, :page_id, :training_session_id)
  end

  def on_event_created
    @session = TrainingSession.find(params[:training_session_id])
    @session.calculate_duration
    
    case @session.type
    when "CommunicationSession"
      return on_generic_event_created
    when "CognitiveSession"
      return on_cognitive_event_created
    else
      return on_generic_event_created
    end
  end

  # Generic behaviour
  def on_generic_event_created
    return true
  end

  # Behaviour for CognitiveSession
  def on_cognitive_event_created
    @session.check_results_and_conclude

    return on_generic_event_created
  end

end
