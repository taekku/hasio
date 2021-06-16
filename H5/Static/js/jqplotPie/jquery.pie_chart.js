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
				"event":false
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
		
//		alert(JSON.stringify(data));
//		alert(JSON.stringify(bindData));
		
		var show_div = $(this).attr("id");
		
		$('#'+show_div).css("width",settings['width']+"px");
		$('#'+show_div).css("height",settings['height']+"px");
		pieframe_draw(show_div, bindData,settings);
		
	};
})(jQuery);

function pieframe_draw(show_div, bindData,settings){
	var rate = bindData.rate;
	
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
			}
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
	//event !!
//	if(settings['event']==true){
//		$('#'+show_div).bind('jqplotDataClick', 
//	            function (ev, seriesIndex, pointIndex, data) {
////						Pie_ChartClick(ev, seriesIndex, pointIndex, data);
//					alert("ev: "+ev+" seriesIndex: "+seriesIndex+" pointIndex: "+pointIndex+" data: "+data);
////	                $('#info1').html('series: '+seriesIndex+', point: '+pointIndex+', data: '+data);
//	            }
//	        );
//	}
	
	
}