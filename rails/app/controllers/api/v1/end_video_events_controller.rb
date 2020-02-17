class Api::V1::EndVideoEventsController < Api::V1::SessionEventsController
  def create
    if session_event_params[:card_id].blank?
      render json: {errors: ["#{I18n.t :error_card_id_needed}"]}, status: :bad_request
      return
    end
    super
  end
  
  def broadcast_event_message
    # Not here. Needs to be anticipated in on_event_created
  end

  def render_event(event)
    render json: event, serializer: Api::V1::VideoEventSerializer, status: :created
  end

  def on_event_created
    # End the video.
    ActionCable.server.broadcast("cable_#{ENV['SERVER_TO_DESKTOP_SOCKET_CHANNEL_NAME']}", {type: "END_VIDEO", data: {card_id: session_event_params[:card_id]}}.to_json)
    ActionCable.server.broadcast("cable_#{ENV['SERVER_TO_MOBILE_SOCKET_CHANNEL_NAME']}", {type: "END_VIDEO", data: {card_id: session_event_params[:card_id]}})
    layout = PageLayout.find_by(page_id: params[:page_id], card_id: params[:card_id])
    if layout.nil?
      return false
    end

    if layout.next_page_id.blank?
      ActionCable.server.broadcast("cable_#{ENV['SERVER_TO_MOBILE_SOCKET_CHANNEL_NAME']}", {type: "NO_MORE_PAGES", data: nil})
      #TransitionToEndEvent.create(training_session_id: params[:training_session_id], page_id: params[:page_id])
    else
      # Block the execution if the requested page doesn't exist.
      unless Page.exists?(id: layout.next_page_id)
        return false
      end
      TransitionToPageEvent.create(next_page_id: layout.next_page_id, training_session_id: params[:training_session_id], page_id: params[:page_id])
    end

    return true

  end

  protected

  def session_event_params
    params.permit(:id, :type, :card_id, :page_id, :training_session_id)
  end
end
