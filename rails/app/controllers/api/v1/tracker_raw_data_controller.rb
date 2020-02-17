class Api::V1::TrackerRawDataController < ApplicationController
  def show
    trackerDatum = TrackerRawDatum.find(params[:id])
    render json: trackerDatum
  end

  def index
    paginate json: TrackerRawDatum.all
  end

  # If tracker_data param is present the create method will create every entry in the tracker_data array
  # otherwise it will use the other parameters to create a single tracker raw datum.
  # When working with the tracker_data array, by default the method will only return {success: true} as a confirmation.
  # If you want to receive the full array of created tracker raw data, send a :return_full_objects param
  # set to true. WARNING: can be very slow if there are hundreds of objects.
  def create
    if params.has_key?(:tracker_data)
      TrackerRawDatum.transaction do
        raw_params = tracker_raw_data_params

        raw_params[:tracker_data].each do |datum|
          datum[:training_session_id] = params[:training_session_id]
          if datum.has_key?(:timestamp)
            datum[:timestamp] = Time.at(datum[:timestamp].to_f/1000)
          end
        end

        data = TrackerRawDatum.create(raw_params[:tracker_data])
        i = 0
        data.each do |datum|
          unless datum.persisted?
            # datum.errors.add(:index, i)
            datum.errors[:index] << i
            render json: { errors: datum.errors.full_messages }, status: :unprocessable_entity
            raise ActiveRecord::Rollback
          end
          i += 1
        end
        if params[:return_full_objects] == "true"
          render json: data, status: :created
        else
          render json: {success: true}, status: :created
        end
      end
    else
      trackerDatum = TrackerRawDatum.new(tracker_raw_data_params)
      unless params.has_key?(:timestamp)
        trackerDatum.timestamp = DateTime.current
      end
      if trackerDatum.save
        render json: trackerDatum, status: :created
      else
        render json: { errors: trackerDatum.errors.full_messages }, status: :unprocessable_entity
      end
    end
  end

  def update
    trackerDatum = TrackerRawDatum.find(params[:id])
    trackerDatum.assign_attributes(tracker_raw_data_params)
    if trackerDatum.save
      render json: trackerDatum, status: :accepted
    else
      render json: { errors: trackerDatum.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private
  
  def tracker_raw_data_params
    params.permit(:id, :timestamp, :x_position, :y_position, :training_session_id, :return_full_objects, :tracker_data => [:x_position, :y_position, :timestamp])
  end
end
