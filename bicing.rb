require 'sinatra'
require 'json'
require 'haml'

module Bicing
  require 'geo-distance'
  require 'open-uri'
  require 'hpricot'
  require 'active_support/memoizable'
  require 'iconv'
  class Placemark
    extend ActiveSupport::Memoizable
    attr_reader :name, :open, :closed, :latitude, :longitude

    def initialize(element)
      @element = element
    end

    def open
      description_text_nodes.first.inner_text.to_i
    end

    def closed
      description_text_nodes.last.inner_text.to_i
    end

    def name
      description_node.at("div div:first").inner_text.split(" - ", 2).last
    end

    def longitude
      point_node.inner_text.split(",", 2).first.to_f
    end

    def latitude
      point_node.inner_text.split(",", 2).last.to_f
    end

    def distance_to(location_latitude, location_longitude)
      GeoDistance.distance(location_latitude, location_longitude, latitude, longitude)
    end

    protected

    def point_node
      @element.at("point/coordinates")
    end

    def description_node
      Hpricot(@element.at("description").inner_text)
    end

    def description_text_nodes
      description_node.search("div div:last *").select { |e| e.text? }
    end

    memoize :name, :open, :closed, :latitude, :longitude
    memoize :description_node, :description_text_nodes
  end

  class Placemarks
    class << self
      extend ActiveSupport::Memoizable

      def near(latitude, longitude)
        all.sort { |a, b|
          b.distance_to(latitude, longitude).distance <=> a.distance_to(latitude, longitude).distance
        }.take(25)
      end

      def all
        kml.search("placemark").map { |element| Placemark.new(element) }
      end

      protected

      def html
        Iconv.new('UTF-8//IGNORE', 'UTF-8').iconv(open("http://bicing.cat/localizaciones/localizaciones.php").read)
      end

      def kml
        Hpricot(html[/<kml xmlns="http:\/\/earth\.google\.es\/kml\/2\.0">(.+?)<\/kml>/])
      end

      memoize :html, :kml, :all
    end
  end

  class Application
    get '/' do
      haml :index
    end

    get '/placemarks.json' do
      latitude = params["latitude"].to_f
      longitude = params["longitude"].to_f
      result = []
      Placemarks.near(latitude, longitude).each do |placemark|
        result << {
            :name => placemark.name,
            :longitude => placemark.longitude,
            :latitude => placemark.latitude,
            :distance => placemark.distance_to(latitude, longitude)[:km],
            :open => placemark.open,
            :closed => placemark.closed
        }
      end
      result.to_json
    end
  end
end
