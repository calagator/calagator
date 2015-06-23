// Adds a subject and cc to event mailto links.
$(function() {
  $('.single_event a[href^="mailto:"]').each(function() {
    var $el = $(this);
    var href = $el.attr('href');

    // Don't do this if it already has a query param.
    if (href.indexOf("?") === -1) {
      href = href + "?subject=Found%20through%20Volunteer%20Odyssey%20Calendar&cc=calendar@volunteerodyssey.com";
      $el.attr('href', href);
    }
  });
});
