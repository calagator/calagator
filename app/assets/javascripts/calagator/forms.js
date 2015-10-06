//= require jquery-ui/datepicker
//= require jquery-ui/autocomplete
//= require jquery.timepicker

$(document).on('page:load ready',function(){
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
  $('.time_picker_filter').timepicker({
    'step': 60,
  });

  // Set oldTime to allow time offset functionality
  oldTime = $("#time_start").timepicker('getTime');
});

// Update "time_end" to maintain the same offset from "time_start" if "time_start" changes, and display a highlight to alert the user.
$(document).on('change', '#time_start', function() {
  var duration = ($("#time_end").timepicker('getTime') - oldTime);
  // if the duration is less than 30 minutes, use default duration of an hour
  if (duration < 1800000) duration = 3600000;
  var newTime = $("#time_start").timepicker('getTime');
  // Calculate and update the time in the second input.
  $("#time_end").timepicker('setTime', new Date(newTime.getTime() + duration));
  $('#time_end').effect('highlight', {}, 3000);
  oldTime = newTime;
});

// Update "date_end" so that it is the same as "date_start" if "date_start" is changed to after "date_end", and displays a highlight to alert the user.
$(document).on('change', '#date_start, #date_end',function() {
  // Only update when end value is before start value.
  var startDate = $.datepicker.parseDate('yy-mm-dd', $('#date_start').val());
  var endDate = $.datepicker.parseDate('yy-mm-dd', $('#date_end').val());
  if (endDate < startDate) {
    $('#date_end').val($('#date_start').val());
    $('#date_end').effect('highlight', {}, 3000);
  }
});
