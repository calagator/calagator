//= require jquery-ui
//= require jquery.timepicker

$(document).ready(function(){
  // Initialize autocompletion for venues
  $("input.autocomplete").each(function() {
    $(this).attr('autocomplete', 'off').autocomplete({
      source: "/venues/autocomplete.json",
      minLength: 2,
      search: function(event, ui) {
        //$("#event_venue_loading").show();
        $("#event_venue_id").val('');
      },
      select: function(event, ui) {
        $('input.autocomplete').val( ui.item.title );
        $("#event_venue_id").val( ui.item.id );

        return false;
      }
    }).data( "ui-autocomplete" )._renderItem = function( ul, item ) {
      var short_address = (item.street_address && item.street_address.length > 0)
                            ? item.street_address+", "+item.locality+" "+item.region
                            : item.address;
      return $( "<li><a href='javascript:void(0);'><strong>"+item.title+"</strong><br />"+short_address+"</a></li>" )
              .data( "item.autocomplete", item )
              .appendTo(ul);
    };
  });

  // Initialize date and time pickers
  $('.date_picker').datepicker({ dateFormat: 'yy-mm-dd' });
  $('.time_picker').timepicker({ 'timeFormat': 'g:i A' });

  // Update "time_end" to maintain the same offset from "time_start" if "time_start" changes, and display a highlight to alert the user.
  var oldTime = $("#time_start").timepicker('getTime');
  $("#time_start").change(function() {
    if ($("#time_end").val()) { // Only update when second input has a value.
      var duration = ($("#time_end").timepicker('getTime') - oldTime);
      var newTime = $("#time_start").timepicker('getTime');
      // Calculate and update the time in the second input.
      $("#time_end").timepicker('setTime', new Date(newTime.getTime() + duration));
      $('#time_end').effect('highlight', {}, 3000);
      oldTime = newTime;
    }
  });

  // Update "date_end" so that it is the same as "date_start" if "date_start" is changed to after "date_end", and displays a highlight to alert the user.
  $("#date_start").change(function() {
    // Only update when end value is defined.
    if ($("#date_end").val()) {
      // Only update when end value is before start value.
      var startDate = $.datepicker.parseDate('yy-mm-dd', $('#date_start').val());
      var endDate = $.datepicker.parseDate('yy-mm-dd', $('#date_end').val());
      if (endDate < startDate) {
        $('#date_end').val($('#date_start').val());
        $('#date_end').effect('highlight', {}, 3000);
      }
    }
  });
});
