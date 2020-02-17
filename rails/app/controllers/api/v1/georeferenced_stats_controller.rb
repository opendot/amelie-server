# JSON.parse(File.read('app/assets/javascripts/flickr_feed.json'))
class Api::V1::GeoreferencedStatsController < ApplicationController

  skip_load_and_authorize_resource

  @@regions = JSON.parse(File.read(Rails.public_path.join('regioni.geojson')))
  @@provinces = JSON.parse(File.read(Rails.public_path.join('province.geojson')))

  def index

    # initialize params
    from = Time.zone.parse(params[:from_date]).to_datetime if params.has_key?(:from_date)
    to = Time.zone.parse(params[:to_date]).to_datetime if params.has_key?(:to_date)

    # check if regions or provinces
    collection = @@regions
    if params.has_key?(:scope) && params[:scope] == "provinces"
      collection = @@provinces
    end

    # initialize all zones with zeros
    collection['features'].each do |region|
      region['properties']['com_absolute'] = 0
      region['properties']['cog_absolute'] = 0
      region['properties']['tot_absolute'] = 0
      region['properties']['com_relative'] = 0
      region['properties']['cog_relative'] = 0
      region['properties']['tot_relative'] = 0
    end

    group = nil

    # grop by zone
    if params.has_key?(:scope) && params[:scope] == "provinces"
      group = Patient.all.group_by(&:province)
    else
      group = Patient.all.group_by(&:region)
    end

    #compute values
    group.each_pair do |region, patients|
      if region
        patient_count = patients.length
        com_absolute = 0
        cog_absolute = 0
        tot_absolute = 0
        com_relative = 0
        cog_relative = 0
        tot_relative = 0

        # get sessions
        patients.each do |patient|
          comses = patient.training_sessions.where(type:"CommunicationSession")
          cogses = patient.training_sessions.where(type:"CognitiveSession")

          # filter by date
          if from
            comses.where('start_time >= ?', from)
            cogses.where('start_time >= ?', from)
          end

          if to
            comses.where('start_time <= ?', to)
            cogses.where('start_time <= ?', to)
          end

          # compute absolute values
          comabs = comses.count
          cogabs = cogses.count
          totabs = comabs + cogabs
          com_absolute = com_absolute + comabs
          cog_absolute = cog_absolute + cogabs
          tot_absolute = tot_absolute + totabs
        end

        # get relative values
        com_relative = com_absolute.to_f / patient_count
        cog_relative = cog_absolute.to_f / patient_count
        tot_relative = tot_absolute.to_f / patient_count

        # update objcts in collections
        reg = collection['features'].detect {|r| r['properties']['id'] == region}

        reg['properties']['com_absolute'] = com_absolute
        reg['properties']['cog_absolute'] = cog_absolute
        reg['properties']['tot_absolute'] = tot_absolute
        reg['properties']['com_relative'] = com_relative
        reg['properties']['cog_relative'] = cog_relative
        reg['properties']['tot_relative'] = tot_relative
      end
    end

    # return values
    render :json => collection, status: :ok
  end

end

