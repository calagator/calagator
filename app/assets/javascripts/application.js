// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults
$(document).ready(function(){
  // Shows hidden section when a link is clicked, and hides the link.
  //
  // The link must have a DOM id that corresponds to the section to display,
  // e.g. a "foo_toggle" link relates to the "foo" section.
  $(".expander_toggle").click(function(event) {
    var id_to_hide = event.target.id;
    var id_to_show = id_to_hide.replace(/_toggle$/, "");
    $("#"+id_to_hide).hide(200);
    $("#"+id_to_show).show(200);
    $e = event;
  });
});
