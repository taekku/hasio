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
 * live()  -> on() 으로 바꿈.(jquery 3.3.1 버전에 따른 수정.) 2018.04.18 김용빈 
 * on() -> attr('onclick', function) 태그 생성시에 event 부여 2018.08.14 (LMY)
 */
var privacyInfoData;
(function($) {
	var bindData;
	var object = {}; //
	var stack_levels = 2;
	
	function ch_find(domObj, obj) {
		
		if (obj !== undefined && obj !== null) {
			var ulObj = $("<ul></ul>");
			$(domObj).append(ulObj);

			$.each(obj, function(i, obj) {
				var orgtype = "";
				
				if (obj['type'] === null || obj['type'] === undefined || obj['type'] === 'null') { //5t  

					orgtype = "nomal 0 " + obj['lvl'] + " 0 " + obj['img'] + " " + obj['num'] + " " + obj['pos_emp'] + " "+ obj['haschildren'] + " " + obj['emp_id'] + " " + obj['org_type_cd']; //3
				} else {

					orgtype = "staff " + obj['level'] + " " + obj['lvl'] + " 0 " + obj['img'] + " " + obj['num'] + " " + obj['pos_emp'] + " " + obj['haschildren'] + " " + obj['emp_id'] + " " + obj['org_type_cd'];
				}

				var liObj = $("<li style='visibility:hidden' id=" + obj.num + " class='" + orgtype + "'>" + obj.title + "</li>");

				ulObj.append(liObj);
				if (obj.children) {
					ch_find(liObj, obj.children);
				}	
			});
		}
	}

	$.fn.orgChart = function(data, options, $appendTo, privacyData) { //$appendTo

		var dataObj = data['oc_data'];
		ch_find(this, dataObj);
		bindData = data;
		privacyInfoData = privacyData;
		
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
		for ( var i = 0; i < childrens.length; i++) {
			var temp_class = $(childrens[i]).attr("class"); //
			var array = temp_class.split(" ");
			var level = Number(array[1]);
			if (max_level < level) {	
				max_level = level;
			}
		}                 
		return max_level;
	};
	
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

		var $table = $("<table cellpadding='0' cellspacing='0' border='0'/>");
		var $tbody = $("<tbody/>");
		
		// Make this node...
		var $nodeRow = $("<tr/>").addClass("nodes");
		var $nodeCell = $("<td/>").addClass("node").attr("colspan", 2); // 
		var $childNodes = $node.children("ul:first").children("li");
		var $childNodes1 = $node.children("ul:first").children("li .nomal");

		var staff_temp = opts.nodeStaff($node);
		var obj_array = staff_temp.split(" ");
		var staff_type = obj_array[0];    // staff가 저장
		var org_lvl = obj_array[2];    	  // org chart의 lvl을 저장
		var chart_org_id = obj_array[5];  // data num 값
		var emp_img = obj_array[4];       // emp의 img
		var pos_emp = obj_array[6];       // 조직도에 직급과, 이름을 저장
		var haschildren = obj_array[7];   // children의 유무
		var org_emp_id = obj_array[8];    // emp_id
		var org_type_cd = obj_array[9]; 
		
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

		if (settings['div_template'] === "1") { // temp1일 경우에 화상조직도가 출력된다.

			$nodeDiv.css({'width':'50px','height':'150px', 'letter-spacing':'3px'});
			
			// 2013.10.31 김정현 수정. 조직유형에 따라 색상변경
			var bg_class_nm = "";
			
			if ( org_type_cd == "100"){			// 회사
				bg_class_nm = "ceo_bg_color";
			}else if (org_type_cd == "150"){	// 부사장
				bg_class_nm = "subleader_bg_color";
			}else if (org_type_cd == "200"){	// 사업부
				bg_class_nm = "bizorg_bg_color";
			}else if (org_type_cd == "300"){	// 본부
				bg_class_nm = "org_bg_color";
			}else if (org_type_cd == "400"){	// 그룹
				bg_class_nm = "group_bg_color";
			}else if (org_type_cd == "500"){	// 팀
				bg_class_nm = "team_bg_color";
			}
			
			// 2013.10.31 김정현 수정 END
			var temp1_org_name = $("<div name='temp1_org_name_pro"+chart_org_id+"'>")
									.addClass("temp1_org_name").addClass(bg_class_nm)
									.attr("onclick", "popup_org_infor($(this), 2)"); //  부서명이 출력되는 부분
			
			$nodeDiv.append(temp1_org_name);
			
			var small_title=$("<div>").addClass("tmep1_small_title").text(opts.nodeText($node));    // 부서명
			temp1_org_name.append(small_title);
				
			var phm_div = $("<div name='phm_div_pro"+org_emp_id+"'>").addClass("temp1_phm_div")
							.attr("onclick", "popup_org_infor($(this), 1)"); 
			$nodeDiv.append(phm_div);
			if(pos_emp.indexOf("[" && "]")){
				pos_emp = pos_emp.replace("[", "");
				pos_emp = pos_emp.replace("]", "");
			}
			
			var pos_emp = $("<div name='phm_div_pro"+org_emp_id+"'style=''>").addClass("temp1_pos_emp").html(pos_emp);
			phm_div.append(pos_emp);
				
			//var pos_count=0;

			if (haschildren == "true") {
				var plus;
				if(org_lvl == "undefined"){
					plus = $("<div id='change_0' name='level_1' >").addClass("cross_div").attr("onclick", "panelToggle(0)")
								.html("<p>-</p>").css({'pacity':'1', 'margin-left': '18px'});
					$nodeDiv.append(plus);
				}else{
					plus = $("<div id='change_" + chart_org_id + "' name='level_"+org_lvl+"'>").addClass("cross_div").attr("onclick", "panelToggle("+chart_org_id+")")
								.html("<p>+</p>").css({'pacity':'1','margin-left': '18px'});
					$nodeDiv.append(plus);// 자식노드가 있을때 플러스 마이너스가 출력되는 부분
				}
			}
		}
		else{   // div_temp가 1이 아닌 경우  화상조직도가 출력된다.
			
			// 2013.10.31 김정현 수정. 조직유형에 따라 색상변경
			var bg_class_nm = "";
			
			if ( org_type_cd == "100"){			// 회사
				bg_class_nm = "ceo_bg_color";
			}else if (org_type_cd == "150"){	// 부사장
				bg_class_nm = "subleader_bg_color";
			}else if (org_type_cd == "200"){	// 사업부
				bg_class_nm = "bizorg_bg_color";
			}else if (org_type_cd == "300"){	// 본부
				bg_class_nm = "org_bg_color";
			}else if (org_type_cd == "400"){	// 그룹
				bg_class_nm = "group_bg_color";
			}else if (org_type_cd == "500"){	// 팀
				bg_class_nm = "team_bg_color";
			}
			
			// 2013.10.31 김정현 수정 END
			// 부서명이 출력되는 부분
			var small_div = $("<div name='small_div_pro"+chart_org_id+"'>")
							.addClass("small_div1").addClass(bg_class_nm)
							.attr("onclick", "popup_org_infor($(this), 2)").text(opts.nodeText($node)); 
			
			$nodeDiv.append(small_div);

			if (true){
				if(emp_img==""){
					emp_img="/common/img/noimage.png";           // 이미지가 없는 사람은 이미지 없음으로 뜨게된다,
				}

				var img = $("<img style= 'width:80px; height: 79px;'>").attr("src", emp_img);   // 이미지가 출력되는 부분
				var imagediv = $("<div name='in_photo1_"+org_emp_id+"'>")
								.addClass("in_photo1").attr("onclick", "popup_org_infor($(this), 1)").append(img);
				$nodeDiv.append(imagediv);
			} 

			if(pos_emp == "[]"){
				var phm_div = $("<div name='phm_div_pro"+org_emp_id+" '>")
								.addClass("phm_div1").attr("onclick", "popup_org_infor($(this), 1)").text("");
			}else if(pos_emp.indexOf("[" && "]")){
				
				pos_emp = pos_emp.replace("[", "");
				pos_emp = pos_emp.replace("]", "");
				var phm_div = $("<div name='phm_div_pro"+org_emp_id+" '>")
								.addClass("phm_div1").attr("onclick", "popup_org_infor($(this), 1)").html(pos_emp);   // 이름과 직책이 나오게 된다,
			}
			
			$nodeDiv.append(phm_div);

			var privacyInfo = privacy_info_draw(chart_org_id); 
			$nodeDiv.append(privacyInfo);

			// 사진옆에 네모가 출력되는 부분
			var $heading = $("<div id='in_content1_"+chart_org_id+"' name='in_content_pro"+org_emp_id+"'>")
								.addClass("in_content1").attr("onclick", "popup_org_infor($(this), 2)"); 
		
			$nodeDiv.append($heading);

			if (haschildren == "true") {                               //c_haschildren가 true이면 node에 (+)cross_div 를 append한다. 
				var plus;
				if(chart_org_id == "0"){                    // org_id가 0인 경우는 다음레벨이 출력되기 때문에 처음이 -가 된다.
					
					var plus = $("<div id='change_0' style='float: left;'>")
										.addClass("cross_div").attr("onclick", "panelToggle(0)").html("<p>-</p>");
					$nodeDiv.append(plus);
				}
				else {
					
					var plus = $("<div id='change_" + chart_org_id + "' style='text-align:center; float: left;'>")
										.addClass("cross_div").attr("onclick", "panelToggle("+chart_org_id+")").html("<p>+</p>"); // 자식노드가 있을때 플러스 마이너스가 출력되는 부분
					
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
		};

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
				$childNodes.each(function() {
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

function privacy_info_draw(chart_org_id){
	var privacyInfoTable = '',
		job_nm 	  = '',
		pos_nm 	  = '',
		hire_ymd  = '',
		birth_ymd = '';
	
	for(var i=0; i<privacyInfoData.length; i++) {
		var data = privacyInfoData[i];
		
		if( data['org_id'] == chart_org_id ) {
			job_nm 	  = data['job_nm'];
			pos_nm 	  = data['pos_nm'];
			hire_ymd  = data['hire_ymd'];
			birth_ymd = data['birth_ymd'];
			break;
		}
	}
	
	privacyInfoTable =	"<div class='privacy_info'>" +
							"<ul>" +
								"<li><div>직군 </div><div class='job_nm'>: "		+ job_nm 	+"</div></li>" +
								"<li><div>직위 </div><div class='pos_nm'>: "		+ pos_nm 	+"</div></li>" +
								"<li><div>입사일 </div><div class='hire_ymd'>: "	+ hire_ymd 	+"</div></li>" +
								"<li><div>생년월일 </div><div class='birth_ymd'>: " + birth_ymd +"</div></li>" +
							"</ul>" +
					   	"</div>";
	
	return privacyInfoTable;
}

function CreateChildChart(replace_id){
	var node = $("#sell_id_" + replace_id).parent().parent().parent();
	
	var tr = node.children().last();

	var tdId = tr.find("div.node");
	
	tdId.each(function(index){

		var tdId = $(this).attr("id");
		var rePlId = tdId.replace("sell_id_", "");
	
		privacy_info_draw(rePlId);
	});
}

function panelToggle(chart_org_id) {
	var replace_id = chart_org_id;        
	var cross_div_id = "change_" + chart_org_id;
	var $this = $("#sell_id_" + chart_org_id);   
	var $row = $this.closest("tr");
	var text = $('#' + cross_div_id).find("p").html();
	
	if ($row.next("tr").is(":visible")) {     // 클릭했을때, 접힌다.
		$row.nextAll("tr").fadeOut("fast", function() {
			if (text == "+") {
				$('#' + cross_div_id).html("<p>-<p>");			
			} else {
				$('#' + cross_div_id).html("<p>+</p>");	
			}
		});
	} else {			
		$row.nextAll("tr").each(function(index){
			$(this).fadeIn("fast", function() {// 클릭했을때, 열린다.	
				if (text == "+") {
					$('#' + cross_div_id).html("<p>-</p>");
				} else {
					$('#' + cross_div_id).html("<p>+</p>");
				}
			});
			if(index=="2"){	
				//ddil alert("1");						
				$(this).children().children().children().children().children().find("div.node").each(function(index) {     // 접혔다 다시 열때, 바로 밑의 노드만 출력되도록한다.
					var $child_row = $(this).closest("tr");
					var this_id = $(this).attr("id");  // $(this)는 다음 네모를 가르킨다.	
					var colse_id = this_id.replace("sell_id_","change_");  // sell_id에서 change로 바꾼다.
					var text1 = $('#'+ colse_id).html();   // cross_div의 id 값을 가지고 온다.
					
					if ($child_row.next("tr").is(":visible")) { // 클릭했을때, 접힌다.
						$child_row.nextAll("tr").hide();    // 바로 밑 노드를 제외한 노드를 다 숨켜버린다.
						if (text1 == "+") {
							$('#'+ colse_id).html("<p>-</p>");
						} else {
							$('#'+ colse_id).html("<p>+</p>");
						}
					}
				});
			}
		});
		stack_levels = 2;
		
		if($("#org_type").val()=="1" ){  // org_type가 1이면 하위노드의 차트를 그리지 않는다.
			
		}else{
			CreateChildChart(chart_org_id);  // 열릴때, 하위 레벨에 있는 노드에 차트를 그린다.
		}
	}
}

/******************************
 * flag : 1 ( 사원정보 팝업 )
 * flag : 2 ( 조직정보 팝업 )
 ******************************/
function popup_org_infor(org_popup, flag){
	
	var click_photo= org_popup.attr("name");    // 사진
	var replace_id = "";
	
	var click_content1= org_popup.attr("name");   // 기타
	var click_contentId= org_popup.attr("id");		// 기타 ID로 추가
	var content_replace_id ="";
	
	var click_phm_div1= org_popup.attr("name");   // 사람이름
	var content_phm_div1 ="";
	
	var click_small_div1= org_popup.attr("name");    // org_popup
	var content_small_div1 ="";
	
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
		// 기타정보 입력장수
		bindingObject["ME_PHM0001_01"][0].emp_id = content_replace_id;
		
		if( flag == '2' ){
			/** 조직 차트 추가 **/
			if( click_contentId.indexOf("in_content1_") != -1) {
				click_contentId = click_contentId.replace("in_content1_", "");
				bindingObject["ME_HPS0001_01"][0].org_id = click_contentId;
			}
		}
	}
	
	
	if (click_phm_div1.indexOf("phm_div_pro") != -1) {
		content_phm_div1 = click_phm_div1.replace("phm_div_pro", "");
		
		bindingObject["ME_PHM0001_01"][0].emp_id = content_phm_div1;
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
	
	if (auth_str == "admin" || auth_str == "org_leader" || auth_str == "executive") {   
		if (flag == 2) {
			var org_id = bindingObject["ME_HPS0001_01"][0].org_id;
			if (org_id == null || org_id == undefined || org_id == 'null'|| org_id == "undefined") {
				
			} else {
				doAction("searchEmpList"); // 조직원
			}
		}
	}
}