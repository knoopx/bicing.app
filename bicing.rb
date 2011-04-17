require 'sinatra'
require 'geo-distance'
require 'open-uri'
require 'ap'
require 'json'
require 'haml'

get '/' do
  haml :index
end

get '/stations.json' do
  ap params

  current_location_longitude = params["longitude"].to_f
  current_location_latitude = params["latitude"].to_f

  JSON.parse(open("http://rocboronat.net/barcelonabicing/bcnJ?all=1").read).sort { |a, b|
    GeoDistance.distance(current_location_longitude, a["x"], current_location_latitude, a["y"]).distance <=>
        GeoDistance.distance(current_location_longitude, b["x"], current_location_latitude, b["y"]).distance
  }.map { |location| location["distance"] = GeoDistance.distance(current_location_longitude, location["x"], current_location_latitude, location["y"]).distance; location }.to_json
end

