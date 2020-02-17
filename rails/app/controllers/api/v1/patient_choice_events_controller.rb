class Api::V1::PatientChoiceEventsController < Api::V1::SessionEventsController
  def broadcast_event_message
    # Send nothing. The necessary informations has already been sent.
  end

  protected

  def session_event_params
    params.permit(:id, :type, :page_id, :training_session_id, :card_id)
  end

  def on_event_created
    @layout = PageLayout.find_by(page_id: params[:page_id], card_id: params[:card_id])
    if @layout.nil?
      return false
    end

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
    
    # Need to anticipate the broadcasting of the event.
    ActionCable.server.broadcast("cable_#{ENV['SERVER_TO_DESKTOP_SOCKET_CHANNEL_NAME']}", {type: "PATIENT_CHOICE", data: {page_id: params[:page_id], card_id: params[:card_id], training_session_id: params[:training_session_id], event_type: params[:type]}}.to_json)
    card = @layout.card
    if card.content[:type] == "Video"
      unless params[:force_transition]
        broadcast_video_event
        return true
      end
    end
    if @layout.next_page_id.blank?
      broadcast_no_more_pages_to_mobile
    else
      # Block the execution if the requested page doesn't exist.
      unless Page.exists?(id: @layout.next_page_id)
        return false
      end
      TransitionToPageEvent.create(next_page_id: @layout.next_page_id, training_session_id: params[:training_session_id], page_id: params[:page_id])
    end
    return true
  end

  # Behaviour for CognitiveSession
  def on_cognitive_event_created
    # Check how much time took to answer
    open_page_event = TransitionToPageEvent.where(training_session_id: params[:training_session_id], next_page_id: params[:page_id])
      .order(:created_at).last

    if !open_page_event.nil? && open_page_event.created_at < 3.minutes.ago
      # Too much time has passed, show the presentation
      exercise = @session.exercise_tree
      unless exercise.nil? || exercise.presentation_page_id.nil?
        presentation = exercise.presentation_page.get_a_clone_with_next_page(@layout.page_id)
        transition_event = TransitionToPresentationPageEvent.create!(next_page_id: presentation.id, training_session_id: params[:training_session_id])
        transition_event.broadcast_transition_to_page_message(@layout.page_id)
        return true
      end
    end
    
    # Need to anticipate the broadcasting of the event.
    ActionCable.server.broadcast("cable_#{ENV['SERVER_TO_DESKTOP_SOCKET_CHANNEL_NAME']}", {type: "PATIENT_CHOICE", data: {page_id: params[:page_id], card_id: params[:card_id], training_session_id: params[:training_session_id], event_type: params[:type]}}.to_json)
    card = @layout.card
    if card.content[:type] == "Video"
      unless params[:force_transition]
        broadcast_video_event
        return true
      end
    end
    if @layout.next_page_id.blank?
      if @layout.correct
        feedback_page = nil
        exercise = @session.exercise_tree
        
        if @session.answered_page_with_highest_depth? &&
          @session.all_answers_are_correct? && 
          @session.is_exercise_completed_for_last_time? &&
          !exercise.strong_feedback_page_id.nil?

          feedback_page = exercise.strong_feedback_page
        else
          feedback_page = FeedbackPage.positive_random.first
        end

        show_feedback_page(feedback_page)
        # broadcast_no_more_pages_to_mobile this will be done when the EndVideoEvent is received
      else
        broadcast_no_more_pages_to_mobile
      end
    else
      # Block the execution if the requested page doesn't exist.
      unless Page.exists?(id: @layout.next_page_id)
        return false
      end

      # Show feedback page if answer is correct
      if @layout.correct
        feedback_page = FeedbackPage.positive_random.first
        show_feedback_page(feedback_page)
      else
        TransitionToPageEvent.create!(next_page_id: @layout.next_page_id, training_session_id: params[:training_session_id], page_id: params[:page_id])
      end
      
    end
    return true
  end

  def broadcast_video_event
    PlayVideoEvent.create(training_session_id: params[:training_session_id], card_id: params[:card_id], page_id: params[:page_id])
    ActionCable.server.broadcast("cable_#{ENV['SERVER_TO_DESKTOP_SOCKET_CHANNEL_NAME']}", {type: "PLAY_VIDEO", data: {card_id: session_event_params[:card_id]}}.to_json)
    ActionCable.server.broadcast("cable_#{ENV['SERVER_TO_MOBILE_SOCKET_CHANNEL_NAME']}", {type: "PLAY_VIDEO", data: {card_id: session_event_params[:card_id]}})
  end

  def broadcast_no_more_pages_to_mobile
    ActionCable.server.broadcast("cable_#{ENV['SERVER_TO_MOBILE_SOCKET_CHANNEL_NAME']}", {type: "NO_MORE_PAGES", data: nil})
  end

  def show_feedback_page original_feedback_page
    feedback_page = original_feedback_page.get_a_clone_with_next_page(@layout.next_page_id)
    transition_to_feedback_page_event = TransitionToFeedbackPageEvent.create!(next_page_id: feedback_page.id, training_session_id: params[:training_session_id], page_id: params[:page_id])
    transition_to_feedback_page_event.broadcast_transition_to_page_message(@layout.next_page_id)
  end

end
