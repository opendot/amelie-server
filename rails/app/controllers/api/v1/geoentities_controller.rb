# JSON.parse(File.read('app/assets/javascripts/flickr_feed.json'))
class Api::V1::GeoentitiesController < ApplicationController

  skip_load_and_authorize_resource

  @@regions = JSON.parse(File.read(Rails.public_path.join('italia.json')))


  def index
    if params.has_key?(:parent)
      puts params[:parent]
      render :json => @@regions.select{|x| x["id"] == params[:parent]}[0]['children'], status: :ok

    else
      render :json => @@regions.map {|h| h.slice("nome","id")}, status: :ok
    end
  end

end
