module MappingHelper
  def map_provider
    (SECRETS.mapping && SECRETS.mapping["provider"]) || 'stamen'
  end

  def map_tiles
    (SECRETS.mapping && SECRETS.mapping["tiles"]) || 'terrain'
  end

  def mapping_js_includes
    scripts = ["http://cdn.leafletjs.com/leaflet-0.6.4/leaflet.js"]
    case map_provider
      when "stamen"
        scripts << "http://maps.stamen.com/js/tile.stamen.js?v1.2.3"
      when "mapbox"
        scripts << "https://api.tiles.mapbox.com/mapbox.js/v1.3.1/mapbox.standalone.js"
      when "google"
        scripts << "https://maps.googleapis.com/maps/api/js?key=#{SECRETS.mapping["google_maps_api_key"]}&sensor=false"
        scripts << "leaflet_google_layer"
    end

    scripts
  end

  def map(locatable_items, options = {})
    options.symbolize_keys!
    locatable_items = Array(locatable_items).select{|i| i.location.present? }

    if locatable_items.present?
      div_id = options[:id] || 'map'
      map_div = content_tag(:div, "", :id => div_id)

      markers = map_markers(locatable_items)
      zoom = options[:zoom] || 14
      center = (options[:center] || locatable_items.first.location).join(", ")
      should_fit_bounds = locatable_items.count > 1 && options[:center].blank?

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
          color: 'green'
        })

        var markers = [#{markers.join(", ")}];
        var markerGroup = L.featureGroup(markers);
        markerGroup.addTo(map);
      JS
      script << "map.fitBounds(markerGroup.getBounds());" if should_fit_bounds

      map_div + javascript_tag(script)
    end
  end

  alias_method :google_map, :map

  def layer_constructor
    case map_provider
      when "stamen"
        "L.StamenTileLayer"
      when "mapbox"
        "L.mapbox.tileLayer"
      when "google"
        "L.Google"
      else
        "L.tileLayer"
    end
  end

  def map_markers(locatable_items)
    Array(locatable_items).map { |locatable_item|
      location = locatable_item.location

      if location
        latitude = location[0]
        longitude = location[1]
        title = locatable_item.title
        popup = link_to(locatable_item.title, locatable_item)

        "L.marker([#{latitude}, #{longitude}], {title: '#{j title}', icon: venueIcon}).bindPopup('#{j popup}')"
      end
    }.compact
  end
end
