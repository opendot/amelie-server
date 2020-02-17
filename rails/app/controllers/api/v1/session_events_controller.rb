class Api::V1::SessionEventsController < ApplicationController
  def create
    SessionEvent.transaction do
      parameters = filter_parameters
      event = SessionEvent.create(parameters)
      if event.persisted?
        begin
          unless on_event_created
            raise ActiveRecord::Rollback, ["#{I18n.t :error_event_parameters}"].to_json
          end
        rescue => exception
          logger.error "Error: exception in on_event_created"
          render_creation_aborted(JSON.parse(exception.message))
          raise ActiveRecord::Rollback, exception.message
        end
        broadcast_event_message
        render_event(event)
      else
        render json: {errors: event.errors.full_messages}, status: :unprocessable_entity
      end
    end
  end

  protected

  def session_event_params
    params.permit(:id, :type, :next_page_id, :card_id, :page_id, :training_session_id, page: [:id, :name, :level, :page_tags => [], cards:[:id, :x_pos, :y_pos, :scale, :next_page_id, :hidden_link]])
  end

  # A method that lets subclasses override in which form the session_events_params arrive to the create
  # command of the SessionEvent.
  def filter_parameters
    return session_event_params
  end

  # A method to be overridden in subclasses to broadcast the right message
  def broadcast_event_message
    ActionCable.server.broadcast("cable", "Created item of type: #{params[:type]}")
  end

  # A method to be overridden in subclasses to change the serializer
  def render_event(event)
    render json: event, serializer: Api::V1::SessionEventSerializer, status: :created
  end

  # A method called whenever the on_event_created returns false, invalidating all the created objects
  def render_creation_aborted(details)
    render json: {errors: details}, status: :unprocessable_entity
  end

  # A callback called when the event has been created. If this returns false an exception is generated.
  # The default version does nothing. It's meant to be overridden when needed.
  def on_event_created
    return true
  end
end
