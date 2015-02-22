$(document).ready(function () {
	if (window.matchMedia("(min-width: 768px)").matches) {
		$('body').removeClass('agenda-view');
	}

	if (window.matchMedia("(max-width: 767px)").matches) {
		$('body').addClass('agenda-view');
	}

	$(window).resize(function (e) {
		if (window.matchMedia("(min-width: 768px)").matches) {
			$('body').removeClass('agenda-view');
		}

		if (window.matchMedia("(max-width: 767px)").matches) {
			$('body').addClass('agenda-view');
		}
	});

	$('.js-agenda-view').click(function (e) {
		$('body').addClass('agenda-view');
		e.preventDefault();
	});

	$('.js-month-view').click(function (e) {
		$('body').removeClass('agenda-view');
		e.preventDefault();
	});

	var eventItemLimit = 4;
	var extraEventItems = 0;
	var eventCount = 0;

	var $events = $('#calendar ul');

	$events.each(function (index, element) {
		var $ul = $(element);
		var amountCounter = 0;

		if ($ul.children().length >= 4) { // 0-indexed?
			$ul.children().each(function (index, element) {
				console.log(element);
				if ( index > 3) { // 0-indexed?
					$(element).addClass('truncate');
				}
			});

			if ($ul.children().length > 4) {
				var $moreEvents = $("<a></a>");
				amountCounter = $ul.children().length - 4;
				$moreEvents.html("Click here for " + amountCounter + " more events");
				$ul.append($moreEvents);

				$moreEvents.click(function (e) { 
					console.log("Working?");

					$('body').addClass('agenda-view');

					$('html, body').animate({
        				scrollTop: $(element).closest('.has-event').offset().top
    				}, 250);

				});
			}

		}


	});

	$('#calendar ul').parent().addClass('has-event');

	/* Properly format the time for each event */
	$('.event-start-time, .event-end-time').each(function (index, element) {
		var $element = $(element);

		$element.text( moment($element.text()).format("LT") );
	});

});