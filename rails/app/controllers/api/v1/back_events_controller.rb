class Api::V1::BackEventsController < Api::V1::SessionEventsController
  def broadcast_event_message
    # Nothing to send. A message will be sent by the TransitionToPageEvent.
  end

  protected

  def session_event_params
    params.permit(:id, :type, :page_id, :training_session_id)
  end

  def on_event_created
    # Block the event creation if a next page is not supplied.
    if params[:next_page_id].blank?
      return false
    end
    # Block the execution if the requested page doesn't exist.
    unless Page.exists?(id: params[:next_page_id])
      return false
    end
    TransitionToPageEvent.create(next_page_id: params[:next_page_id], training_session_id: params[:training_session_id], page_id: params[:page_id])
    return true
  end
end
