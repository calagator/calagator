//= require 'recurring_select'

// For new events, or events without any recurrences show the
// schedule/rrule input. For existing events with recurrences, users
// can choose to update only this event (in which case the schedule/rrule
// input is hidden) or they may edit this event and all it's recurrences
// (where the rrule/schedule should be visible).
$(document).ready(function() {
  // Don't bother toggling if this is a new event or it doesn't have recurrences
  if ($("input:radio[name='update_all']").length) {
    // Ensure proper state on load.
    toggleScheduleVisibility();
    // Ensure proper state on change.
    $("input:radio[name='update_all']").change(toggleScheduleVisibility);
  }

  function toggleScheduleVisibility() {
    var update_all = $("input:radio[name='update_all']:checked").val() === 'true';
    if (update_all) {
      $("#event_rrule_input").show();
    } else {
      $("#event_rrule_input").hide();
    }
  }
});
