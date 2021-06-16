var SLB_cnt = 0;

function SLB(url, type)
{
	var a = document.getElementById('SLB_film');
	var b = document.getElementById('SLB_content');
	var c = document.getElementById('SLB_loading');

	/* 필름 펼치기 s */
	a.style.position = "absolute";
	a.style.top = "-4px";
	a.style.left = "-21px";
	a.style.height = win.getScrollHeight()+"px";
	a.style.width = win.getScrollWidth()+"px";
	/* 필름 펼치기 e */

	if(url) {
		a.style.top = 0;
		a.style.left = 0;
		a.style.display = "";
		if (document.documentElement.scrollHeight > document.body.scrollHeight) {
			a.style.height = document.documentElement.scrollHeight + 'px';
		} else { 
			a.style.height = document.body.scrollHeight + 'px';
		}
		c.style.display = "block";
		SLB_setCenter(c,true);
		if(type == 'image') {
			modal_html = '';
			modal_html += '<div style="position:absolute;left:0;top:0;z-index:99999;" class="SLB_center">';
			modal_html += '<table cellpadding="0" cellspacing="0" border="0" class="mp_bx">';
			modal_html += '<colgroup>';
			modal_html += '<col width="10"/>';
			modal_html += '<col/>';
			modal_html += '<col width="10"/>';
			modal_html += '</colgroup>';
			modal_html += '<tr>';
			modal_html += '	<td class="top01"></td>';
			modal_html += '	<td class="top02"></td>';
			modal_html += '	<td class="top03"></td>';
			modal_html += '</tr>';
			modal_html += '<tr>';
			modal_html += '	<td class="mid01"></td>';
			modal_html += '	<td class="mid02" style="background:#ddd;border:0px;">';
			modal_html += '		<div id="con" style="border:0px;">';
			modal_html += '		<h2 class="modal_h2"><img src="../images/mybox/tit2_zoom_image.gif" height="22" border="0" alt="이미지 확대 보기" title="이미지 확대 보기"/></h2>';
			modal_html += '		<img src="'+url+'" onload="SLB_setCenter(this)" class="mgt10" />';
			modal_html += '		</div>';
			modal_html += '	</td>';
			modal_html += '	<td class="mid03"></td>';
			modal_html += '</tr>';
			modal_html += '<tr>';
			modal_html += '	<td class="bot01"></td>';
			modal_html += '	<td class="bot02"></td>';
			modal_html += '	<td class="bot03"></td>';
			modal_html += '</tr>';
			modal_html += '</table>';
			modal_html += '</div>';
			b.innerHTML = modal_html;
			if(arguments[2]) a.onclick = function () { SLB() };
			if(arguments[3]) b.innerHTML += "<div class='SLB_caption'>"+ arguments[3] +"</div>";;
		} else if (type == 'iframe') {
			modal_html = '';
			modal_html += '<div style="position:absolute;left:0;top:0;z-index:99999;" class="SLB_center">';
			modal_html += '<table cellpadding="0" cellspacing="0" border="0" width="'+ arguments[2] +'" class="mp_bx tl_f">';
			modal_html += '<colgroup>';
			modal_html += '<col width="10"/>';
			modal_html += '<col/>';
			modal_html += '<col width="10"/>';
			modal_html += '</colgroup>';
			modal_html += '<tr>';
			modal_html += '	<td class="top01"></td>';
			modal_html += '	<td class="top02"></td>';
			modal_html += '	<td class="top03"></td>';
			modal_html += '</tr>';
			modal_html += '<tr>';
			modal_html += '	<td class="mid01"></td>'; 
			modal_html += '	<td class="mid02" style="vertical-align:top;margin:0px;padding:0px; background:#ddd;border:0px;">';
			modal_html += '		<div id="con" style="border:0px;">';
			modal_html += '			<iframe id="SLB_iframe" src="'+ url +'" width="100%" height="'+ arguments[3] +'" marginwidth="0" marginheight="0" frameborder="0" scrollbars="0" vspace="0" hspace="0" onload="tryReHeight(\''+arguments[5]+'\');"/></iframe>';
			modal_html += '		</div>';
			modal_html += '	</td>';
			modal_html += '	<td class="mid03"></td>';
			modal_html += '</tr>';
			modal_html += '<tr>';
			modal_html += '	<td class="bot01"></td>';
			modal_html += '	<td class="bot02"></td>';
			modal_html += '	<td class="bot03"></td>';
			modal_html += '</tr>';
			modal_html += '</table>';
			modal_html += '</div>';
			b.innerHTML = modal_html;
			if(arguments[2]) b.onclick = '';
		} else if (type='html'){
			b.innerHTML = url;
			SLB_setCenter(b.firstChild);
			if(arguments[2]) b.onclick = '';
		}
		hideSelect();
	} else {
		a.onclick = '';
		a.style.display = "none";
		a.style.height = '100%';
		a.style.width = '100%';
		b.innerHTML = "";
		b.onclick = function () { SLB() };
		c.style.display = "none";
		showSelect();
		SLB_cnt = 0;
	}
}

function SLB_setCenter(obj) {
	if (obj) {
		var h = (window.innerHeight || self.innerHeight || document.documentElement.clientHeight || document.body.clientHeight);
		var w = (window.innerWidth || self.innerWidth || document.documentElement.clientWidth || document.body.clientWidth);
		var l = ((window.pageXOffset || document.documentElement.scrollLeft || document.body.scrollLeft) + ((w-(obj.width||parseInt(obj.style.width)||obj.offsetWidth))/2));
		var t = ((window.pageYOffset || document.documentElement.scrollTop || document.body.scrollTop) + ((h-(obj.height||parseInt(obj.style.height)||obj.offsetHeight))/2));
		if((obj.width||parseInt(obj.style.width)||obj.offsetWidth) >= w) l = 0;
		if((obj.height||parseInt(obj.style.height)||obj.offsetHeight) >= h) t = (window.pageYOffset || document.documentElement.scrollTop || document.body.scrollTop);
		document.getElementById('SLB_content').style.left = l + "px";
		if(SLB_cnt == 0) {
			document.getElementById('SLB_content').style.top = t + "px";
			if(document.getElementById('SLB_content').offsetHeight >= h - 20) {
				SLB_cnt ++;
			}
			if(obj.nextSibling && (obj.nextSibling.className == 'SLB_close' || obj.nextSibling.className == 'SLB_caption')) {
				obj.nextSibling.style.display = 'block';
				if((t - (window.pageYOffset || document.documentElement.scrollTop || document.body.scrollTop))>(obj.nextSibling.offsetHeight/2)) {
					document.getElementById('SLB_content').style.top = parseInt(document.getElementById('SLB_content').style.top) - (obj.nextSibling.offsetHeight/2) + "px";
				}
			}
		}
		obj.style.visibility = 'visible';
		if(!arguments[1]) {
			document.getElementById('SLB_loading').style.display = "none";
		} else {
			obj.style.left = l + "px";
			obj.style.top = t + "px";
		}
	}
}

function hideSelect() {
	var windows = window.frames.length;
	var selects = document.getElementsByTagName("SELECT");
	for (i=0;i < selects.length ;i++ )
	{
		selects[i].style.visibility = "hidden";
	}
	if (windows > 0) {
		for(i=0; i < windows; i++) {
			try {
				var selects = window.frames[i].document.getElementsByTagName("SELECT");
				for (j=0;j<selects.length ;j++ )
				{
					selects[j].style.visibility = "hidden";
				}
			} catch (e) {}
		}
	}
}

function showSelect() {
	var windows = window.frames.length;
	var selects = document.getElementsByTagName("SELECT");
	for (i=0;i < selects.length ;i++ )
	{
		selects[i].style.visibility = "visible";
	}
	if (windows > 0) {
		for(i=0; i < windows; i++) {
			try {
				var selects = window.frames[i].document.getElementsByTagName("SELECT");
				for (j=0;j<selects.length ;j++ )
				{
					selects[j].style.visibility = "visible";
				}
			} catch (e) {}
		}
	}
}

function tryReHeight(sign) {
	var getFFVersion=navigator.userAgent.substring(navigator.userAgent.indexOf("Firefox")).split("/")[1];
	var FFextraHeight=parseFloat(getFFVersion)>=0.1? 16 : 0;
	var currentfr=document.getElementById('SLB_iframe');
	var currentDiv=document.getElementById('SLB_content');
	if(sign) {
		try {
			if (currentfr.contentDocument && currentfr.contentDocument.body.offsetHeight) {
				setIframeSize(currentfr.contentDocument.body.offsetHeight+FFextraHeight);
			} else if (currentfr.Document && currentfr.Document.body.scrollHeight) {
				setIframeSize(currentfr.Document.body.scrollHeight);
			}
		}catch(e) { }
		SLB_setCenter(document.getElementById('SLB_content').firstChild);
	} else {
		SLB_setCenter(document.getElementById('SLB_content').firstChild);
	}
}

function setIframeSize(h, w) {
	SLB_cnt = 0;
	var ifr = currentfr=document.getElementById('SLB_iframe');
	if (ifr) {
		if(w) {
			ifr.width = w;
		}
		if(h) {
			ifr.height = h;
		}
		SLB_setCenter(ifr);
	}
}

var prevOnScroll = window.onscroll;
window.onscroll = function () {
	if(prevOnScroll != undefined) prevOnScroll();
	if (document.documentElement.scrollHeight > document.body.scrollHeight) {
		document.getElementById('SLB_film').style.height = document.documentElement.scrollHeight + 'px';
	} else { 
		document.getElementById('SLB_film').style.height = document.body.scrollHeight + 'px';
	}
	document.getElementById('SLB_film').style.width = document.body.scrollWidth + 'px';
	SLB_setCenter(document.getElementById('SLB_content').firstChild);
}

var prevOnResize = window.onresize;
window.onresize = function () {
	if(prevOnResize != undefined) prevOnResize();
	if (document.documentElement.scrollHeight > document.body.scrollHeight) {
		document.getElementById('SLB_film').style.height = document.documentElement.scrollHeight + 'px';
	} else { 
		document.getElementById('SLB_film').style.height = document.body.scrollHeight + 'px';
	}
	document.getElementById('SLB_film').style.width = document.body.offsetWidth + 'px';
	SLB_setCenter(document.getElementById('SLB_content').firstChild);
}

//윈도우 가로 세로 얻는 함수 from mootools
var win ={
	getWidth: function(){
		if (document.childNodes && !document.all && !navigator.taintEnabled) return window.innerWidth;
		if (window.opera) return document.body.clientWidth;
		return document.documentElement.clientWidth;
	},

	getHeight: function(){
		if (document.childNodes && !document.all && !navigator.taintEnabled) return window.innerHeight;
		if (window.opera) return document.body.clientHeight;
		return document.documentElement.clientHeight;
	},

	getScrollWidth: function(){
		if (window.ActiveXObject) return Math.max(document.documentElement.offsetWidth, document.documentElement.scrollWidth);
		if (document.childNodes && !document.all && !navigator.taintEnabled) return document.body.scrollWidth;
		return document.documentElement.scrollWidth;
	},

	getScrollHeight: function(){
		if (window.ActiveXObject) return Math.max(document.documentElement.offsetHeight, document.documentElement.scrollHeight);
		if (document.childNodes && !document.all && !navigator.taintEnabled) return document.body.scrollHeight;
		return document.documentElement.scrollHeight;
	},

	getScrollLeft: function(){
		return window.pageXOffset || document.documentElement.scrollLeft;
	},

	getScrollTop: function(){
		return window.pageYOffset || document.documentElement.scrollTop;
	},
	getPosition: function(){return {'x': 0, 'y': 0}}

};

