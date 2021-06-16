/**
 * JQuery Organisation Chart Plugin-in.
 * 
 * Author: Mark Lee.
 * 
 * Copyright (C)2010 Caprica Software Limited. http://www.capricasoftware.co.uk
 * 
 * This software is licensed under the Creative Commons Attribution-ShareAlike
 * 3.0 License.
 * 
 * See here for license terms:
 * 
 * http://creativecommons.org/licenses/by-sa/3.0
 */
(function($) {
	var bindData;
	var object = {}; //
	var stack_levels=2;

	function ch_find(domObj, obj) {
		//	alert(JSON.stringify(obj));
		//salert(obj);
		if (obj !== undefined && obj !== null) {
			var ulObj = $("<ul></ul>");
			$(domObj).append(ulObj);

			$.each(obj, function(i, obj) {
				var DataCh = obj;
				var orgtype = "";

				if (obj['type'] === null || obj['type'] === undefined || obj['type'] === 'null') { //5t  

					orgtype = "nomal 0 " + obj['lvl'] + " 0 " + obj['img'] + " " + obj['num'] + " " + obj['pos_emp'] + " "+ obj['haschildren'] + " " + obj['emp_id'] + " " + obj['budget'] + " " + obj['actual']; //3
						
				} else {

					orgtype = "staff " + obj['level'] + " " + obj['lvl'] + " 0 " + obj['img'] + " " + obj['num'] + " " + obj['pos_emp'] + " " + obj['haschildren'] + " " + obj['emp_id']+ " " + obj['budget']+ " " + obj['actual'] ; //3
				}

				var liObj = $("<li style='visibility:hidden' id=" + obj.num + " class='" + orgtype + "'>" + obj.title + "</li>");

				ulObj.append(liObj);
				if (obj.children) {
					ch_find(liObj, obj.children);
				}	

			});
		}
	}

	$.fn.orgChart = function(data, options, $appendTo) { //$appendTo

		var dataObj = data['oc_data'];
		ch_find(this, dataObj);
		bindData = data;
		
		build($(this).find("ul:first"));
	
		function build(domObj) { //
			var opts = $.extend({}, $.fn.orgChart.defaults, options);

			var $container = $("<div class='" + opts.chartClass + "'/>"); // $container
			if (domObj.is("ul")) {
				buildNode(domObj.find("li:first"), $container, 0, opts);
			} else if (domObj.is("li")) {	
				buildNode(domObj, $container, 0, opts);
			}
			
			$appendTo.append($container);
		};
		
	
		
		for(var i = 0 ; i < data.oc_data[0].children.length; i++){

			var org_id = data.oc_data[0].children[i].org_id;
			var s_manager_cnt = data.oc_data[0].children[i].s_manager_cnt;
			var s_manager_color = data.oc_data[0].children[i].s_manager_color;
			var manager_cnt = data.oc_data[0].children[i].manager_cnt;
			var manager_color = data.oc_data[0].children[i].manager_color;
			var employee_cnt = data.oc_data[0].children[i].employee_cnt;
			var employee_color = data.oc_data[0].children[i].employee_color;
		
			pie_chart_dr(org_id, s_manager_cnt, s_manager_color, manager_cnt, manager_color, employee_cnt, employee_color);
			
		}

	};

	$.fn.orgChart.defaults = {     // 옵션
		depth : -1,
		stack : false,   
		"div_template" : "1",    // 기구조직일경우 1, 화상조직도일경우 2
		chartClass : "orgChart",
		hoverClass : "hover",
		pie_chart : "false",    // 파이차트의 유무
		showLevels : stack_levels,          // 레벨의 위치
		nodeText : function($node) {
			return ""; 
		},
		nodeStaff : function($node) {
			return "";
		},
		nodePhoto : function($node) {
			return "";
		}

	};
	
	function leaf_height(childrens) {
		
		var max_level = 0;
		
		for ( var i = 0; i < childrens.length ; i++ ) {
			var temp_class = $(childrens[i]).attr("class"); //
			var array = temp_class.split(" ");
			var level = Number(array[1]);
			if (max_level < level) {	
				max_level = level;
			}
		}                 
		return max_level;
	};

	/// 클릭 이벤트가 일어나는 부분
	
	$(".in_photo1").live("click", function(e) {   // 사진
		popup_org_infor($(this),1);
	});
	$(".in_content1").live("click", function(e) {   // 기타
		popup_org_infor($(this),1);
	});
	$(".out_content").live("click", function(e) {  		
		popup_org_infor($(this),1);
	});
	$(".in_content2").live("click", function(e) {   
		popup_org_infor($(this),1);
	});
	////////////////////////  기구조직도에서도 사용
	$(".phm_div1").live("click", function(e) {   // 사람 이름 
		popup_org_infor($(this), 1);
	});
	$(".small_div1").live("click", function(e) {   // org_popup이 생성
		popup_org_infor($(this),2);
	});
	$(".temp1_org_name").live("click", function(e) {   // org_popup이 생성
		popup_org_infor($(this),2);
	});
	$(".temp1_phm_div").live("click", function(e) {   // 사람 이름 
		popup_org_infor($(this), 1);

	});
	
	
	function popup_org_infor(org_popup, flag){
		
	
		var click_photo= org_popup.attr("name");    // 사진
		var replace_id = "";
		
		var click_content1= org_popup.attr("name");   // 기타
		var content_replace_id ="";
		
		var click_phm_div1= org_popup.attr("name");   // 사람이름
		var content_phm_div1 ="";
		
		var click_small_div1= org_popup.attr("name");    // org_popup
		var content_small_div1 ="";
		
		var click_out_content= org_popup.attr("name");    // org_popup
		var content_out_content ="";
		
		////////////////////////기구조직도에서도 사용
		var click_temp1_org_name= org_popup.attr("name");    // org_popup
		var content_temp1_org_name ="";
		
		var click_temp1_phm_div= org_popup.attr("name");   // 사람이름
		var content_temp1_phm_div ="";

		
		if (click_photo.indexOf("in_photo1_") != -1) {
			replace_id = click_photo.replace("in_photo1_", "");
			bindingObject["ME_PHM0001_01"][0].emp_id = replace_id;    // 사진
		}
		if (click_content1.indexOf("in_content_pro") != -1) {
			content_replace_id = click_content1.replace("in_content_pro", "");
			bindingObject["ME_PHM0001_01"][0].emp_id= content_replace_id;    // 기타정보 입력장수
		}
		if (click_phm_div1.indexOf("phm_div_pro") != -1) {
			content_phm_div1 = click_phm_div1.replace("phm_div_pro", "");
			bindingObject["ME_PHM0001_01"][0].emp_id = content_phm_div1;
		}
		if (click_out_content.indexOf("out_con_") != -1) {
			content_out_content = click_out_content.replace("out_con_", "");
			bindingObject["ME_PHM0001_01"][0].emp_id = content_out_content;
		}
		if (click_small_div1.indexOf("small_div_pro") != -1) {
			content_small_div1 = click_small_div1.replace("small_div_pro", "");
			bindingObject["ME_HPS0001_01"][0].org_id = content_small_div1;
			bindingObject["ME_HPS0001_01"][0].cust_col1 = $("#cust_col1").val();
		}
		
		////////////////////////기구조직도에서도 사용 temp1_phm_div
		if (click_temp1_phm_div.indexOf("phm_div_pro") != -1) {
			content_temp1_phm_div = click_temp1_phm_div.replace("phm_div_pro", "");       // 기구조직도 이름 출력부분
			bindingObject["ME_PHM0001_01"][0].emp_id = content_temp1_phm_div;
		}
		if (click_temp1_org_name.indexOf("temp1_org_name_pro") != -1) {
			content_temp1_org_name = click_temp1_org_name.replace("temp1_org_name_pro", "");
			bindingObject["ME_HPS0001_01"][0].org_id = content_temp1_org_name;
		}
		
		
		if (auth_str == "admin") {                                      // object 
		if (flag == 1) {
			var emp_id = bindingObject["ME_PHM0001_01"][0].emp_id;
			if (emp_id != "") {
				doAction("empProfile"); // 프로필
				}
			}
		}
		
		if (auth_str == "admin") {    // user와 admin인 경우
			if (flag == 2) {
				var org_id = bindingObject["ME_HPS0001_01"][0].org_id;
				if (org_id == null || org_id == undefined || org_id == 'null'|| org_id == "undefined") {
				} else {
					doAction("searchEmpList"); // 조직원
				}

			}
		}
	}
	
	
	// cross_div는 클릭했을때 노드가 열리가 닫히고 하는 이벤트가 일어나는다.
	

	
	function leaf_lvl(childrens) {

		var temp_class = childrens.attr("class");
		var array = temp_class.split(" ");
		var lvl = Number(array[2]);
		
		return lvl;
	};

	function buildNode($node, $appendTo, level, opts, settings) {
		
		settings = {
			"div_template" : "1"
		};
		if (opts) { //옵션을 주면 settings 의 내용을 체인지함
			$.extend(settings, opts);
		}

		var bind = bindData['children'];
		
		var $table = $("<table cellpadding='0' cellspacing='0' border='0'/>");
		var $tbody = $("<tbody/>");
		
		// Make this node...
		var $nodeRow = $("<tr/>").addClass("nodes");
		var $nodeCell = $("<td/>").addClass("node").attr("colspan", 2); // 
		var $childNodes = $node.children("ul:first").children("li");
		var $childNodes1 = $node.children("ul:first").children("li .nomal");
		var $childNodes2 = $node.children("ul:first").children("li .staff");

		var staff_temp = opts.nodeStaff($node);
		var photo_node = opts.nodePhoto($node);
		var text_node = opts.nodeText($node);
		var obj_array = staff_temp.split(" ");
		var staff_type = obj_array[0];    //staff가 저장
		var org_chart_level = obj_array[1];   // level을 저장
		var org_lvl = obj_array[2];    // org chart의 lvl을 저장
		var chart_org_id = obj_array[5]; // data num 값
		var emp_img = obj_array[4];    // emp의 img
		var pos_emp = obj_array[6];    // 조직도에 직급과, 이름을 저장
		var haschildren = obj_array[7];  // children의 유무
		var org_emp_id = obj_array[8]; // emp_id
		var budget=obj_array[9];
		var actual=obj_array[10];


		//alert("budget:::::"+budget+",actual::::"+actual+",s_manager_cnt:::"+s_manager_cnt+",s_manager_color::::::"+s_manager_color+",manager_cnt:::::::"+manager_cnt+",manager_color:::::::"+manager_color+",employee_cnt:::::::"+employee_cnt+",employee_color:::::::"+employee_color);
	
		var no_ch;
		
		
		if ($node.parent().children("li .staff").length > 0) { //
			var max_level = leaf_height($node.parent().children("li .staff")); //max
			var max_lvl = leaf_lvl($node.parent().children("li .staff"));
			object[max_lvl] = max_level;
		}

		if ($childNodes.length > 1) {
			$nodeCell.attr("colspan", $childNodes.length * 10); //
		}

		if (staff_type != 'staff'&& $node.parent().children("li .staff").length > 0) {
			no_ch = $childNodes1.length;
			no_ch = (50 - (no_ch * 0.09));
		}

		$nodeDiv = $("<div id='sell_id_" + chart_org_id + "'>").addClass("node").css({'border-style':'solid','border-width':'1px'});

		if (settings['div_template'] === "1") {
			

			$nodeDiv.css({'width':'50px','height':'220px', 'letter-spacing':'3px'});
	
			var temp1_org_name = $("<div name='temp1_org_name_pro"+chart_org_id+"'>").addClass("temp1_org_name"); //  부서명이 출력되는 부분
			$nodeDiv.append(temp1_org_name);
			
			var small_title=$("<div>").addClass("tmep1_small_title").text(opts.nodeText($node));    // 부서명
			temp1_org_name.append(small_title);
				
			var phm_div = $("<div name='phm_div_pro"+org_emp_id+"'>").addClass("temp1_phm_div"); 
			$nodeDiv.append(phm_div);
			
			if(pos_emp.indexOf("[" && "]")){
				pos_emp = pos_emp.replace("[", "");
				pos_emp = pos_emp.replace("]", "  ");
			}
			
			var pos_emp = $("<div name='phm_div_pro"+org_emp_id+"'style=''>").addClass("temp1_pos_emp").text(pos_emp);
			phm_div.append(pos_emp);
				
			var pos_count=0;

			if (haschildren == "true") {
				var plus;
				if(chart_org_id == "0"){
					plus = $("<div id='change_0' name='level_1' >").addClass("cross_div").text("-").css({'pacity':'1', 'margin-left': '18px'});
					$nodeDiv.append(plus);
				}else{
					plus = $("<div id='change_" + chart_org_id + "' name='level_"+org_lvl+"'>").addClass("cross_div").text("+").css({'pacity':'1','margin-left': '18px'});
					$nodeDiv.append(plus);// 자식노드가 있을때 플러스 마이너스가 출력되는 부분
				}
			}
		}
		else{   // div_temp가 1이 아닌 경우  화상조직도가 출력된다.
			var small_div = $("<div name='small_div_pro"+chart_org_id+"'>").addClass("small_div1").text(opts.nodeText($node)); //  부서명이 출력되는 부분
			$nodeDiv.append(small_div);

			if (true){
				if(emp_img==""){
					emp_img="/common/img/noimage.png";           // 이미지가 없는 사람은 이미지 없음으로 뜨게된다,
				}

				var img = $("<img style= 'width:80px; height: 79px;'>").attr("src", emp_img);   // 이미지가 출력되는 부분
				var imagediv = $("<div name='in_photo1_"+org_emp_id+"'>").addClass("in_photo1").append(img);
				$nodeDiv.append(imagediv);

			} 

			if(pos_emp.indexOf("[" && "]")){
				pos_emp = pos_emp.replace("[", "");
				pos_emp = pos_emp.replace("]", "");
				var phm_div = $("<div name='phm_div_pro"+org_emp_id+" '>").addClass("phm_div1").text(pos_emp);
			}else{
				var phm_div = $("<div name='phm_div_pro"+org_emp_id+" '>").addClass("phm_div1").text(pos_emp);   // 이름과 직책이 나오게 된다,
			
			}
			
			$nodeDiv.append(phm_div);

					
		 //   var pie_plus= pie_chart_dr(chart_org_id);
			

			var $heading = $("<div id='in_content1_"+chart_org_id+"' name='in_content_pro"+org_emp_id+"'>").addClass("in_content1"); //사진옆에 네모가 출력되는 부분
		
			$nodeDiv.append($heading);
			
			
			var out_content=$("<div id='out_con_"+chart_org_id+"' name='out_con_"+org_emp_id+"' style='margin-top: -25px; font-size: x-small;'><tr><td style='text-align: left; font-size: x-small;'>Budget : </td><td style='text-align: right; font-size: x-small;'>"+budget+"명</td></tr><br><tr><td style='text-align: left; font-size: x-small;'>&nbspActual : </td><td style='text-align: right; font-size: x-small;'>"+actual+"명</td></tr></div>");	
			$nodeDiv.append(out_content);


			if (haschildren == "true") {                               //c_haschildren가 true이면 node에 (+)cross_div 를 append한다. 
				var plus;
				if(chart_org_id == "0"){                    // org_id가 0인 경우는 다음레벨이 출력되기 때문에 처음이 -가 된다.
					
					var plus = $("<div id='change_0' style='float: left;'>").addClass("cross_div").text("-");
					$nodeDiv.append(plus);
				}else{
					var plus = $("<div id='change_" + chart_org_id + "' style='text-align:center; float: left;'>").addClass("cross_div").text("+"); // 자식노드가 있을때 플러스 마이너스가 출력되는 부분
					
					$nodeDiv.append(plus);
				}
			}
			
		}

		chart_org_id++;

		$nodeDiv2 = $("<div id='box';>");

		var div_table = "<table id='table_size' border='0' cellspacing='0' cellpadding='0' style='height:"+ ((object[org_lvl]) * 42 + (object[org_lvl]) * 45)+ "px; '>"
				+ "<tr  style='align:center;'>"
				+ "<td class='line left top' style='width:50%'>"
				+ "</td><td class='myclasstable line right top'style='align:center;' >"
				+ "</td>" + "</tr>" + "</table>";
		if ($node.parent().children("li .staff").length > 0	&& object[org_lvl] != null && object[org_lvl] != undefined && object[org_lvl] != "" && staff_type != "staff") {
			object[org_lvl];
			$nodeDiv2.addClass("myclass");
			$nodeCell.append($nodeDiv2).append(div_table);

		}

		$nodeCell.append($nodeDiv);
		$nodeRow.append($nodeCell);
		$tbody.append($nodeRow);

		$nodeDiv.hover(function() {
			$(this).addClass(opts.hoverClass); // 네모 위에서
		}, function() {
			$(this).removeClass(opts.hoverClass); //네모 빡에서 		
		});

		if ($childNodes.length > 0) {

			if (opts.depth == -1 || level + 1 < opts.depth) {
				//alert(c_name);

				var nomal_height = 20;
				var nomal_width = 1;

				//div.orgChart tr.lines td.line {

				var $downLineRow = $("<tr/>").addClass("lines"); //css 'height' 
				var $downLineCell = $("<td/>").attr("colspan",$childNodes.length * 10);
				$downLineRow.append($downLineCell); //class=lines (1) ->td colspan = 12 (2)
				var $downLineTable = $("<table  cellpadding='0' cellspacing='0' border='0'>");
				$downLineTable.append("<tbody>"); //(3)
				var $downLineLine = $("<tr/>").addClass("lines");
				var $downLeft = $("<td>").addClass("line left").append($nodeDiv2);
				var $downRight = $("<td>").addClass("line right");
				$downLineLine.append($downLeft).append($downRight);//(4) ,(5)
				$downLineTable.children("tbody").append($downLineLine);
				$downLineCell.append($downLineTable);

				$tbody.append($downLineRow);
				


				// Recursively make child nodes...

				var $linesRow = $("<tr/>").addClass("lines");
				var i = 1;
				$childNodes.each( function() {
					var $left = $("<td/>").addClass("line left top");
					var $right = $("<td/>").addClass("line right top");
					$linesRow.append($left).append($right);
					i++;
				});
				$linesRow.find("td:first").removeClass("top");
				$linesRow.find("td:last").removeClass("top");
				$tbody.append($linesRow);

				var $childNodesRow = $("<tr/>");
				$childNodes.each(function() {
					//alert("여기여라 1");
					var $td = $("<td/>");
					$td.attr("colspan", 2);

					buildNode($(this), $td, level + 1, opts);
					$childNodesRow.append($td);
					
					
				});
			} else if (opts.stack) {
				// TODO what to do about this?
				var $list = $("<ul>");
				$childNodes.each(function() {
					$item = $("<li>").text($(this).textChildren());
					$list.append($item);
				});
				$nodeDiv.after($list);
			}
			$tbody.append($childNodesRow);
			
		}
		
	
	    if (opts.showLevels > -1 && level >= opts.showLevels-1) {     //level의 높이를 보여주는 부분에 대해 
	            $nodeRow.nextAll("tr").hide();
	    }

		$table.append($tbody);
		$appendTo.append($table);
		
		
		
	};

})(jQuery);


	/* 화상조직도 차트 그리기 함수
	 *	s_manager_cnt 	: 고급관리자 cnt
	 *  s_manager_color	: 고급관리자 색상
	 *  manager_cnt   	: 관리자 cnt
	 *  manager_color	: 관리자 색상
	 *  employee_cnt	: 팀원 cnt 
	 *  employee_color	: 팀원 색상
	 *
	 */
	function pie_chart_dr(chart_org_id, s_manager_cnt , s_manager_color , manager_cnt , manager_color , employee_cnt , employee_color ){             // 파이차트를 그리는 함수 

			// 색상은 기본적으로 검은색으로 초기화 한다.
			// 이는 CHART 를 그릴 때 검은색이 아닐 경우만 그리도록 세팅이 되어 있기 떄문이다.
			var color1 = "black";
			var color2 = "black";
			var color3 = "black";
			var color4 = "black";
			var color5 = "black";

			// 2013.04.03 김정현 수정
			// java 에서 JSON String 을 가져와서 parsing 하는 형식이 아니기 때문에
			// 바로 JSON 객체를 생성한다.
			var data = {
				data1 : {title:"" , chart_data:[]}
			};
			
			// 고급관리자 숫자가 있을 경우 고급관리자를 chart_data 에 추가.
			if ( s_manager_cnt != ""){
				
				s_manager_cnt = parseInt(s_manager_cnt , 10);
				var s_manager_name = "고급관리자";
				data['data1'].chart_data.push({legend_name:s_manager_name , value:s_manager_cnt });
				
				// 색상 역시 바로 세팅한다.
				color1 = s_manager_color;
			}
			
			// 관리자 숫자가 있을 경우 관리자를 chart_data 에 추가.
			if ( manager_cnt != ""){
				var manager_name = "관리자";
				manager_cnt = parseInt(manager_cnt , 10);
				data['data1'].chart_data.push({legend_name:manager_name , value:manager_cnt});
				color2 = manager_color;
			}
			
			// 팀원 숫자가 있을 경우 팀원을 chart_data 에 추가.
			if ( employee_cnt != ""){
				var emp_name = "팀원";
				employee_cnt = parseInt(employee_cnt , 10);
				data['data1'].chart_data.push({legend_name:emp_name , value:employee_cnt });
				color3 = employee_color;
			}
		
			var content_num= 'in_content1_'+chart_org_id;

			$("#"+content_num).pieframe(data['data1'],{
				//option lengend_show : 범례 ,  background_color : 배경색상을 지워야 할경우. draw_border : border
				"shadow_show" : false,
				"width" : "150",
				"height" : "100",
				"legend_show" : false,
				"color_default":true,
				"title" : false,
	//			"background_color" : "transparent",
				"draw_border" : false,
				"color1":color1,
				"color2":color2,
				"color3":color3,
				"color4":color4,
				"color5":color5,
				"event" : false
				}
			);
					
	}




//function pie_chart_draw(chart_org_id){             // 파이차트를 그리는 함수 
//	$.post("/orm/web/pie_chartData_01.jsp", "cust_col1="+$("#cust_col1").val() + "&chart_org_id=" + chart_org_id+ "&base_ymd=" + $("#base_ymd").val()).done(
//		function (strText) {
//			if ($.trim(strText) == "NOT") {
//				//alert("아무것도없어요!");
//				$("#"+content_num).html("데이터가 없습니다.");		
//			} else {
//				
//				var data = JSON.parse($.trim(strText));
//				var cc_num = data.cnum;
//				var content_num= 'in_content1_'+cc_num;
//				var content_num2= 'in_content2_'+cc_num;
//				
//				
//				if (data['data1'] !== undefined&& data['data1'] !== null&& data['data1'] !== 'null') {
//
//					var color1="";
//					var color2="";
//					var color3="";
//					var color4="";
//					var color5="";
//					var budget=0;
//					var actual=0;
//					
//
//					
//				   if (data['data1'].chart_data[0] !== undefined && data['data1'].chart_data[0]  !== null &&  data['data1'].chart_data[0] != 'null') {
//						color1 = data['data1'].chart_data[0].cust_col2;
//						budget = budget+parseInt(data['data1'].chart_data[0].budget);
//						actual = actual+parseInt(data['data1'].chart_data[0].actual);
//						}else{
//						color1 = "black";
//					}
//					if (data['data1'].chart_data[1] !== undefined &&  data['data1'].chart_data[1]  !== null &&  data['data1'].chart_data[1] != 'null') {
//						color2 = data['data1'].chart_data[1].cust_col2;
//						budget = budget+parseInt(data['data1'].chart_data[1].budget);
//						actual = actual+parseInt(data['data1'].chart_data[1].actual);
//						}else {
//						color2 = "black";
//					}
//					if (data['data1'].chart_data[2] !== undefined &&  data['data1'].chart_data[2]  !== null && data['data1'].chart_data[2] != 'null') {
//						color3 = data['data1'].chart_data[2].cust_col2;
//						budget = budget+parseInt(data['data1'].chart_data[2].budget);
//						actual = actual+parseInt(data['data1'].chart_data[2].actual);
//					} else {
//						color3 = "black";
//					}
//					if (data['data1'].chart_data[3] !== undefined &&  data['data1'].chart_data[3]  !== null &&  data['data1'].chart_data[3] != 'null') {
//						color4 = data['data1'].chart_data[3].cust_col2;
//						budget = budget+parseInt(data['data1'].chart_data[3].budget);
//						actual = actual+parseInt(data['data1'].chart_data[3].actual);
//					} else {
//						color4 = "black";
//					}
//					if (data['data1'].chart_data[4] !== undefined &&  data['data1'].chart_data[4]  !== null &&  data['data1'].chart_data[4] != 'null') {
//						color5 = data['data1'].chart_data[4].cust_col2;
//						budget = budget+parseInt(data['data1'].chart_data[4].budget);
//						actual = actual+parseInt(data['data1'].chart_data[4].actual);
//					} else {
//						color5 = "black";
//					}
//					
//			
//				//	$("#out_con_"+chart_org_id)	.html("<tr><td style='text-align: left; font-size: x-small;'>Budget :</td><td style='text-align: right; font-size: x-small;'>"+cc+"명</td></tr><tr><td style='text-align: left; font-size: x-small;'>&nbspActual :</td><td style='text-align: right; font-size: x-small;'>"+ff+"명</td></tr>");
//		
//			
//					$("#"+content_num).pieframe(data['data1'],
//							{
//								//option lengend_show : 범례 ,  background_color : 배경색상을 지워야 할경우. draw_border : border
//								"shadow_show" : false,
//								"width" : "150",
//								"height" : "100",
//								"legend_show" : false,
//								"color_default":true,
//								"title" : false,
//					//			"background_color" : "transparent",
//								"draw_border" : false,
//								"color1":color1,
//								"color2":color2,
//								"color3":color3,
//								"color4":color4,
//								"color5":color5,
//								"event" : false
//							});
//				}
//
//			}
//			
//			 
//		
//		}
//	);
//}


