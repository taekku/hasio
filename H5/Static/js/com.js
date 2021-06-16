/* menu sub all view */
function chg_st()
{
	chg_st_obj = document.getElementById("navi");
	chg_btn_obj = document.getElementById("chg_btn");
	if(chg_st_obj.className =="bx_des")
	{
		chg_st_obj.className = "bx_des2"
		chg_btn_obj.src = "../../common/img/320/com/btn_close.gif"
	}else{
		chg_st_obj.className = "bx_des"
		chg_btn_obj.src = "../../common/img/320/com/btn_home.gif"
	}
}
/* menu sub all view E  */

/* menu smartLearning */
function naviB (id) {
	for(num=1; num<=6; num++) document.getElementById('naviB_'+num).style.display='none'; //
	document.getElementById(id).style.display='block'; //
}
/* menu smartLearning E */

/* tab */
$(function(){

	$("#tabA > a").click(function(e){
		switch(this.id){
			case "tabA_A":
				$("#tabA_A").addClass("on");
				$("#tabA_B").removeClass("on");
		
				$("ul#tabAcont_A").fadeIn();
				$("ul#tabAcont_B").css("display", "none");
				
				$('#container_list_area_navi').hide();
			break;
			case "tabA_B":
				$("#tabA_A").removeClass("on");
				$("#tabA_B").addClass("on");
		
				$("ul#tabAcont_A").css("display", "none");
				$("ul#tabAcont_B").fadeIn();
				
				$('#container_list_area_navi').show();
			break;
			
		}
		return false;
	});
});
/* tab E */
