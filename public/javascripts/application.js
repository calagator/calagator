// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

$(document).ready(function(){
    $('.date_picker').datepicker({ dateFormat: 'yy-mm-dd' });
		$('.time_picker').timePicker({
		  show24Hours:false,
		  separator:':',
		  step: 15});
});