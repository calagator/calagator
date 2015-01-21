//= require leaflet.awesome-markers

var map = function(layer_constructor, map_tiles, div_id, center, zoom, marker_color, rawMarkers, should_fit_bounds) {
  klass = eval(layer_constructor)
  var layer = new klass(map_tiles);
  var map = new L.Map(div_id, {
      center: new L.LatLng(center[0], center[1]),
      zoom: zoom,
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
    markerColor: marker_color
  })

  var markers = rawMarkers.map(function(m) {
    return L.marker([m.latitude, m.longitude], { title: m.title, icon: venueIcon}).bindPopup(m.popup);
  });
  var markerGroup = L.featureGroup(markers);
  markerGroup.addTo(map);

  if(should_fit_bounds) {
    map.fitBounds(markerGroup.getBounds());
  }
};
