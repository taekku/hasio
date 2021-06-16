(function($){

	
	$.fn.pieframe = function(data,options){
		var settings = {
				"legend_show":true,
				"background_color":"#fffdf6",
				"draw_border":true,
				"shadow_show":true,
				"width":"300",
				"height":"200",
				"title":"",
				"event":false,
				"color1":"yellow",
				"color2":"yellow",
				"color3":"yellow",
				"color4":"yellow",
				"color5":"yellow",
				"color_default":true
			};
		if(options){
			$.extend(settings,options);
			
		}
		
		var bindData={};
		var dataObj=data['chart_data'];
		bindData['Title']=data['title'];
		bindData['rate']=[];
		
		$.each(dataObj,function(index,object){
			var Object=[];
			
			Object[Object.length]=object['legend_name'];
			Object[Object.length]=object['value'];
//			alert(JSON.stringify(Object));	
			bindData.rate[bindData.rate.length]=Object;
		});
		
//		alert("data:::::::::::::::::::::"+JSON.stringify(data));
//		alert(JSON.stringify(bindData));
		
		var show_div = $(this).attr("id");

		
		$('#'+show_div).css("width",settings['width']+"px");
		$('#'+show_div).css("height",settings['height']+"px");
		pieframe_draw(show_div, bindData,settings);
		
	};
})(jQuery);

function pieframe_draw(show_div, bindData,settings){
	

	
	var rate = bindData.rate;

	var seriesColor;

	seriesColor = [];
	if ( settings['color1'] != 'black'){
		
		seriesColor.push(settings['color1']);
	}
	if ( settings['color2'] != 'black'){
		
		seriesColor.push(settings['color2']);
	}
	if ( settings['color3'] != 'black'){
		
		seriesColor.push(settings['color3']);
	}
	if ( settings['color4'] != 'black'){
		
		seriesColor.push(settings['color4']);
	}
	if ( settings['color5'] != 'black'){
		
		seriesColor.push(settings['color5']);
	}
		
	
	if  ( show_div == "in_content1_6781"){
//		console.log("show_div : " + show_div + " / "+JSON.stringify(bindData));
//		console.log("rate : " + show_div + " / "+JSON.stringify(bindData.rate));
//		console.log("seriesColor : " + show_div + " / "+JSON.stringify(seriesColor));
//		
//	
	}
	
	var plot1 = jQuery.jqplot(show_div, [ rate ], {		
		
		              
		seriesDefaults : {
			// Make this a pie chart.
			renderer : jQuery.jqplot.PieRenderer,
			fill:true,
			rendererOptions : {
				// Put data labels on the pie slices.
				// By default, labels show the percentage of the slice.
				shadow:settings['shadow_show'],
				
				showDataLabels : true,
				padding: 5,
			},
			seriesColors :seriesColor
		
		},
		


		
		title: settings['title'],
		legend : {
			show : settings['legend_show'],
			location : 'e'
		},
		grid:{
			background :settings['background_color'],
			shadowAlpha:'0',
			//drawGridlines:false
			drawBorder:settings['draw_border'],
			
		}
	});

}