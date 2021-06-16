(function($) {	
	$.fn.timelineframe = function(data, options) {
		alert("22");
		var dataObj = data;
		
		var selectData = {};
		var bindData ={};
		
		selectData['TOTAL']="전체";
		selectData['other']="other";
//		bindData=
		
		var settings = {
			"title" : true,
			"width":"800",
			"height":"200"
		};

		if (options) { //
			$.extend(settings, options);
		}

		var show_div = $(this).attr('id');

		var view = "<div id='body'>"
				
				+ "<div id='timeline_"+show_div+"' class='timeline-default' style='height: "+settings['height']+"px; width:"+settings['width']+"px;'>"
				+ "</div>" + "</div>";
		$('#'+show_div).append(view);
		timelineframe_draw(show_div);
	};
})(jQuery);


function timelineframe_draw(show_div) {
	var timeline;
	var eventSource = new Timeline.DefaultEventSource(0);

	// Example of changing the theme from the defaults
	// The default theme is defined in 
	// http://simile-widgets.googlecode.com/svn/timeline/tags/latest/src/webapp/api/scripts/themes.js
	var theme = Timeline.ClassicTheme.create();
	theme.event.bubble.width = 350;
	theme.event.bubble.height = 300;

	var today = new Date();
	var year = today.getFullYear();
	var month = today.getMonth() + 1;
	var day = today.getDate();

	if (month < 10) {
		month = "0" + month;
	}
	if (day < 10) {
		day = "0" + day;
	}

	var d = Timeline.DateTime.parseIso8601DateTime(year + "-" + month + "-"
			+ day);
	var bandInfos = [ Timeline.createBandInfo({
		width : "80%",
		intervalUnit : Timeline.DateTime.WEEK, //
		intervalPixels : 200,
		eventSource : eventSource,
		date : d,
		theme : theme,
		layout : 'original' // original, overview, detailed
	}), Timeline.createBandInfo({
		width : "20%",
		intervalUnit : Timeline.DateTime.MONTH, //
		intervalPixels : 200,
		eventSource : eventSource,
		date : d,
		theme : theme,
		layout : 'overview' // original, overview, detailed
	}) ];
	bandInfos[1].syncWith = 0;
	bandInfos[1].highlight = true;
	
	///
	for (var i = 0; i < bandInfos.length; i++) {
        bandInfos[i].decorators = [
            new Timeline.SpanHighlightDecorator({
                startDate:  d,
                endDate:    d,
                color:      "#FFC080", // set color explicitly
                opacity:    50,
                startLabel: "Today",
                theme:      theme
            }),
            new Timeline.PointHighlightDecorator({
                date:       d,
                color:      "#FFC080",
                opacity:    50,
                theme:      theme
                // use the color from the css file
            }),
            new Timeline.PointHighlightDecorator({
                date:       "Sun Nov 24 2012 13:00:00 GMT-0600",
                opacity:    50,
                theme:      theme
                // use the color from the css file
            })
        ];
    }
	///
	

	timeline = Timeline.create(document.getElementById("timeline_"+show_div), bandInfos,
			Timeline.HORIZONTAL);
	// Adding the date to the url stops browser caching of data during testing or if
	// the data source is a dynamic query...
	timeline.loadJSON("/rem/web/schedule_data.jsp?" + (new Date().getTime()), function(json,
			url) {
	
		eventSource.loadJSON(json, url);
		
		
	});

	$('#timeline_'+show_div).slider();
};