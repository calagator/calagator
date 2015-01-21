module Calagator

module MappingHelper
  def map_provider
    Calagator.mapping_provider || 'stamen'
  end

  def leaflet_js
    Rails.env.production? ? ["http://cdnjs.cloudflare.com/ajax/libs/leaflet/0.7.3/leaflet.js"] : ["leaflet"]
  end

  def map_provider_dependencies
    {
      "stamen" => ["http://maps.stamen.com/js/tile.stamen.js?v1.2.3"],
      "mapbox" => ["https://api.tiles.mapbox.com/mapbox.js/v1.3.1/mapbox.standalone.js"],
      "esri"   => ["http://cdn-geoweb.s3.amazonaws.com/esri-leaflet/0.0.1-beta.5/esri-leaflet.js"],
      "google" => [
        "https://maps.googleapis.com/maps/api/js?key=#{Calagator.mapping_google_maps_api_key}&sensor=false",
        "leaflet_google_layer"
      ]
    }[map_provider] || []
  end

  def mapping_js_includes
    leaflet_js + map_provider_dependencies
  end

  def map(items, options = {})
    options.symbolize_keys!
    Map.new(items, self, options).render
  end

  class Map < Struct.new(:items, :context, :options)
    def render
      return if locatable_items.empty?
      script = <<-JS
        var layer = new #{layer_constructor}("#{map_tiles}");
        var map = new L.Map("#{div_id}", {
            center: new L.LatLng(#{center}),
            zoom: #{zoom},
            attributionControl: false
        });
        L.control.attribution ({
          position: 'bottomright',
          prefix: false
        }).addTo(map);

        map.addLayer(layer);

        var venueIcon = L.AwesomeMarkers.icon({
          icon: 'star',
          prefix: 'fa',
          markerColor: '#{marker_color}'
        })

        var markers = [
          #{markers.map do |m|
            "L.marker([#{m.latitude}, #{m.longitude}], {title: '#{context.j m.title}', icon: venueIcon}).bindPopup('#{context.j m.popup}')"
          end.join(",\n") }
        ];
        var markerGroup = L.featureGroup(markers);
        markerGroup.addTo(map);

        if(#{should_fit_bounds}) {
          map.fitBounds(markerGroup.getBounds());
        }
      JS

      map_div + context.javascript_tag(script)
    end

    private

    def map_div
      context.content_tag(:div, "", id: div_id)
    end

    def div_id
      options[:id] || 'map'
    end

    def zoom
      options[:zoom] || 14
    end

    def center
      (options[:center] || locatable_items.first.location).join(", ")
    end

    def should_fit_bounds
      locatable_items.count > 1 && options[:center].blank?
    end

    def markers
      Array(locatable_items).map { |locatable_item|
        location = locatable_item.location

        if location
          latitude = location[0]
          longitude = location[1]
          title = locatable_item.title
          popup = context.link_to(locatable_item.title, locatable_item)

          Marker.new(latitude, longitude, title, popup)
        end
      }.compact
    end

    def marker_color
      Calagator.mapping_marker_color
    end

    def locatable_items
      @locatable_items ||= Array(items).select {|i| i.location.present? }
    end

    def layer_constructor
      constructor_map = {
        "stamen"  => "L.StamenTileLayer",
        "mapbox"  => "L.mapbox.tileLayer",
        "esri"    => "L.esri.basemapLayer",
        "google"  => "L.Google",
        "leaflet" => "L.tileLayer",
      }
      constructor_map[context.map_provider]
    end

    def map_tiles
      Calagator.mapping_tiles || 'terrain'
    end
  end

  class Marker < Struct.new(:latitude, :longitude, :title, :popup)
  end

  alias_method :google_map, :map
end

end
