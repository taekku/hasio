Alice = {
	version : "0.56",
	creator : "GoodBug",
	mail : "unicorn@jakartaproject.com;tomcat5@paran.com;sdcho@ta9.co.kr",
	homepage : "http://www.jakartaproject.com",
	updated : "2010.01.22"
};

Alice.config = {
	uploadpath : '',
	imageroot : '/img/',
	uploadroot : ''
};

(function() {
	
	Web.EditorManager = {
		hash : new Hash,
		pop : new Hash,
		sequence : 0,
		path : '',
		put : function(el) {
			this.hash[el.aliceId] = el;
		},
		instance : function(id) {
			var h = null;
			var keys = this.hash.keys();
			for ( var i = 0; i < keys.length; i++) {
				if (this.hash[keys[i]].instance == id) {
					h = this.hash[keys[i]];
					break;
				}
			}
			if (!h) {
				h = new Web.Editor(id, arguments[1] || {});
			}
			return h;
		},
		get : function(id) {
			var h = this.hash[id];
			if (!h) {
				h = null;
			}
			return h;
		},
		getId : function() {
			return "s." + (++this.sequence);
		},
		remove : function(id) {
			this.hash.remove(id);
		},
		removeAll : function() {
			var keys = this.hash.keys();
			for ( var i = 0; i < keys.length; i++) {
				this.remove(keys[i]);
			}
		},
		disableRange : function(id) {
			this.hash[id].disableRange();
		},
		disableAllRange : function() {
			var keys = this.hash.keys();
			for ( var i = 0; i < keys.length; i++) {
				this.disableRange(keys[i]);
			}
		},
		disableFocus : function(id) {
			this.hash[id].disableFocus();
		},
		disableAllFocus : function() {
			var keys = this.hash.keys();
			for ( var i = 0; i < keys.length; i++) {
				this.disableFocus(keys[i]);
			}
		},
		pushPop : function(p) {
			this.pop[p.id] = p;
		},
		pullPop : function(id) {
			var p = this.pop[id];
			if (p) {
				p.innerHTML = '';
				p.style.display = 'none';
				this.pop.remove(id);
			}
		},
		pullAllPop : function() {
			var keys = this.pop.keys();
			for ( var i = 0; i < keys.length; i++) {
				this.pullPop(keys[i]);
			}
		},
		disableAlllayout : function() {
			var keys = this.hash.keys();
			for ( var i = 0; i < keys.length; i++) {
				this.hash[keys[i]].fontDisplayHidden();
			}
		}
	};
	
	Web.Editor = Class.create();
	Web.Editor.prototype = {
		initialize : function(id, params) {
			this.instance = id;
			this.seqId = Web.EditorManager.getId();
			this.aliceId = 'alice-' + this.seqId;
			this.mode = 'HTML';
			this.file = new Hash;
			this.preview = null;
			this.range = null;
			this.focus = false;
			this.status = 'MAX';
			this.anchors = '_blank';
			this.limit = params.limit || 0;
			this.dataProvider = params.dataProvider;
			
			if (this.instance) {
				var o1 = $1(this.instance);
				var o2 = $n(this.instance);
				
				var d = 0;
				while (o1 || d == 0) {
					if (o1 && o1.tagName.toLowerCase() == 'textarea') {
						break;
					}
					o1 = o2[d++];
				}
				
				if (!o1) {
					alert('The textarea width id or name is not found');
					return;
				}
			} else {
				alert('Id propery is required');
				return;
			}
			
			var w = 600;
			var h = 200;
			var h2 = 150;
			
//			$.logger("W : " + w);
//			$.logger("H : " + h);
			var p = o1.parentElement || o1.parentNode;
			if (params.width) {
				var sw = params.width.toString();
				if (sw.include('%')) {
					if (p) {
						w = Web.util.Position.pure(params.width) / 100 * Web.util.Position.pure(Element.getStyle(p, 'width'));
					}
				} else {
					w = Web.util.Position.pure(params.width);
					w = w < 400 ? 400 : w;
				}
				if (!Web.isIE) {
					w -= 2;
				}
			}
			
			if (params.height) {
				var sh = params.height.toString();
				if (sh.include('%')) {
					if (p) {
						h = Web.util.Position.pure(params.height) / 100 * Web.util.Position.pure(Element.getStyle(p, 'height'));
					}
				} else {
					h = Web.util.Position.pure(params.height);
					h = h < 200 ? 200 : h;
					h2 = h-50;					
				}
			}
			
			this.invoke = params.invoke;
			this.thumbnail = params.thumbnail || 50;
			this.fontSize = params.size || '13px';
			this.fontFamily = params.family || '돋움';
			this.aliceType = params.type || 'detail';
			this.aliceType = this.aliceType.toLowerCase();
			this.aliceWidth = Web.util.Position.pure(w || Element.getStyle(o1, "width") || '600px');
			this.aliceHeight = Web.util.Position.pure(h || Element.getStyle(o1, "height") || '300px');
			this.aliceHeight2 = h2;
			this.initValue = o1.value;
			this.appendHtml(this.createHtml(), o1);
			this.appendStyle();
			this.loadAlice();
			this.extendContextWindow();
			Web.EditorManager.put(this);
			o1.style.display = 'none';
		},
		
		loadAlice : function() {
			
			var cw = this.getAliceContentWindow();
			cw.document.designMode = "on";
			cw.document.open();
			cw.document.write("<style type='text/css'>body {background-color:#ffffff;scrollbar-face-color:#d0d0d0;scrollbar-highlight-color:#ffffff;scrollbar-3dlight-color:#d0d0d0;scrollbar-darkshadow-color:#666666;scrollbar-shadow-color:#a0a0a0;scrollbar-arrow-color:#ffffff;scrollbar-track-color:#feedf4;}</style>");
			cw.document.write("<style type='text/css'>P {font-family:" + (this.fontFamily) + ";font-size:" + (this.fontSize) + ";margin-top:3px;margin-bottom:3px;margin-left:3;margin-right:3px;white-space: -moz-pre-wrap;word-break:break-all;}</style>");
			cw.document.close();
			cw.document.body.style.fontSize = this.fontSize;
			cw.document.body.style.fontFamily = this.fontFamily;
			cw.document.body.title=this.aliceId;
			
		
			
			this.focusAlice();
			this.loadContent();
			if (Web.isIE) {
				var range = cw.document.selection.createRange();
				this.setAliceRange(range);
			}
			
			Event.observe(cw.document, "keyup", this.appendEventKeyDown); // n
			
		
			if (Web.isIE) {
				Event.observe(cw.document, "mousedown", this.appendEventMouseDown); // n
				Event.observe(this.aliceId, "focus", this.appendEventFocus); // y focus = true;
				Event.observe(window.document, "click", this.appendEventAllClick); // y popup == false then range = null, focus = false
				document.body.oncontextmenu = function() {
					return false;
				};
			}
			Event.observe(cw.document, "click", this.appendEventClick); // n
			Event.observe(this.aliceId, "mouseout", this.appendEventMouseout); // y set range			
		},
		
		showAlice : function() {
			var id = "alc-box-" + this.seqId;
			$1(id).style.display = '';
		},
		
		hideAlice : function() {
			var id = "alc-box-" + this.seqId;
			$1(id).style.display = 'none';
		},
		
		disableAlice : function() {
			this.toggleAlice('HTML');
			var y = Web.util.Position.objectY("alc-box-" + this.seqId);
			var x = Web.util.Position.objectX("alc-box-" + this.seqId);
			
			var obj = $1("alc-disabled.s" + this.seqId);
			if (!obj) {
				var div = document.createElement("div");
				div.setAttribute("id", "alc-disabled.s" + this.seqId);
				document.body.appendChild(div);
				obj = div;
			}
			obj.className = "alc-shadow";
			obj.style.top = y;
			obj.style.left = x;
			obj.style.width = this.aliceWidth;
			obj.style.height = this.aliceHeight;
			obj.style.zIndex = 9999999;
			obj.style.display = 'inline';
		},
		
		enableAlice : function() {
			var obj = $1("alc-disabled.s" + this.seqId);
			if (obj) {
				obj.style.display = 'none';
			}
		},
		
		loadContent : function() {
			if (this.initValue.length > 0) {
				var cw = this.getAliceContentWindow();
				cw.document.body.innerHTML = (cw.document.body.innerHTML || '') + this.initValue;
			}
		},
		
		appendEventClick : function(event) {
			Web.EditorManager.pullAllPop();
			Web.EditorManager.disableAlllayout();
			
		},
		
		appendEventFocus : function(event) {
			
			var alice = event.srcElement;
			//alert("appendEventFocus");
			if (alice.id) {
				var el = Web.EditorManager.get(alice.id);
				if (el) {
					el.focus = true;
				}
			}
		},
		
		appendEventAllClick : function(event) {
			var src = event.srcElement;
			if (src.name != undefined) {
				// only alc-bttns-s.*, alc-select-s.*
				if (src.name.include('alc-')) {
					return;
				}
			}
			Web.EditorManager.disableAllRange();
			Web.EditorManager.disableAllFocus();
		},
		

		appendEventKeyDown : function(event) {
			var alice = Web.isIE ? event.srcElement : event.target;
		
			if (event.keyCode == 9) {
				alice.focus();
				space = "    ";
				if (Web.isIE) {
					alice.selection = document.selection.createRange();
					alice.selection.text = space;
				}
				event.returnValue = false;
			}
			//alice.title
			
			
			
			if (alice.title) {
				alice.focus();
								
				var el = Web.EditorManager.get(alice.title);
				var temp = alice;
				if (el) {
					var cw = el.getAliceContentWindow();
				
					//추가된 내용.
					if (el.instance) {
						var o1 = $1(el.instance);
						var o2 = $n(el.instance);
						
						var d = 0;
						while (o1 || d == 0) {
							if (o1 && o1.tagName.toLowerCase() == 'textarea') {
								break;
							}
							o1 = o2[d++];
						}
						
						o1.value = el.getContent();
						
						
			
						$.setField(bindingObject[el.dataProvider][0], o1.name, el.getContent());
					
					}
					//
					if (Web.isIE) {
				
						var range = cw.document.selection.createRange();
						el.setAliceRange(range);
					}
				}
			}
			
			
		},
		
		appendEventMouseout : function(event) {
			
			var alice = Web.isIE ? event.srcElement : event.target;

			if (alice.id) {
				var el = Web.EditorManager.get(alice.id);
				var temp = alice;
				if (el) {
					var cw = el.getAliceContentWindow();
				
					//추가된 내용.
					if (el.instance) {
						var o1 = $1(el.instance);
						var o2 = $n(el.instance);
						
						var d = 0;
						while (o1 || d == 0) {
							if (o1 && o1.tagName.toLowerCase() == 'textarea') {
								break;
							}
							o1 = o2[d++];
						}
						o1.value = el.getContent();
						
						$.setField(bindingObject[el.dataProvider][0], o1.name, el.getContent());
					
					}
					//
					if (Web.isIE) {
				
						var range = cw.document.selection.createRange();
						el.setAliceRange(range);
					}
				}
			}
			
		},
		
		appendEventMouseDown : function(event) {
			if (event.button == 2) {
				var obj = event.srcElement;
				if (obj) {
					var tid = null;
					if (obj.tagName == 'TD') {
						if (obj.parentElement.parentElement && obj.parentElement.parentElement.tagName == 'TABLE') {
							tid = obj.parentElement.parentElement.id;
						} else if (obj.parentElement.parentElement.parentElement && obj.parentElement.parentElement.parentElement.tagName == 'TABLE') {
							tid = obj.parentElement.parentElement.parentElement.id;
						}
					} else if (obj.tagName == 'TABLE') {
						tid = obj.id;
					}
					
					if (tid) {
						var alice = tid.substring(tid.indexOf('alice'));
						alice = alice.substring(0, alice.indexOf('-t'));
						
						var div = document.createElement("div");
						div.setAttribute("id", "alc-tab-opt.s" + Web.Math.random());
						div.setAttribute("className", "alc-pop");
						div.style.zIndex = 8081;
						document.body.appendChild(div);
						
						div.style.position = "absolute";
						div.style.top = Web.util.Position.objectY(alice) + event.clientY;
						div.style.left = Web.util.Position.objectX(alice) + event.clientX;
						Alice.table.srcElement = obj;
						var d1 = alice + "-menu-row";
						var d2 = alice + "-menu-col";
						var d3 = alice + "-menu-cel";
						div.innerHTML = "" + "<table border=0 cellspacing=2 cellpadding=0 class=alc-cntxt-box><tr><td><table border=0 cellspacing=0 cellpadding=2 class=alc-cntxt-bs>" + "<tr><td rowspan=5 class=alc-cntxt-main><img src=" + Alice.config.imageroot + "alice/editor/table_row.gif></td><td rowspan=5 valign=top style=padding-top:4;width:70><b>행 옵션</td><td onclick=\"Alice.table.appendRowBefore('" + alice + "','" + tid
								+ "')\" class=alc-cntxt-sub onmouseover=this.className='alc-cntxt-sub-o' onmouseout=this.className='alc-cntxt-sub'>위에 행 추가</td></tr>" + "<tr><td onclick=\"Alice.table.appendRowAfter('" + alice + "','" + tid + "')\" class=alc-cntxt-sub onmouseover=this.className='alc-cntxt-sub-o' onmouseout=this.className='alc-cntxt-sub'>아래에 행 추가</td></tr>" + "<tr><td onclick=\"Alice.table.removeRow('" + alice + "','" + tid
								+ "')\" class=alc-cntxt-sub onmouseover=this.className='alc-cntxt-sub-o' onmouseout=this.className='alc-cntxt-sub'>해당행 삭제</td></tr>" + "<tr><td onclick=\"Alice.color.togglePicker('" + d1 + "')\" class=alc-cntxt-sub onmouseover=this.className='alc-cntxt-sub-o' onmouseout=this.className='alc-cntxt-sub'>해당행 배경색 <div style=position:absolute;left:300;width:200px;display:none id='" + d1 + "' onclick=\"Alice.table.colorRow('" + alice + "','" + tid
								+ "')\"></div></td></tr>" + "<tr><td class=alc-cntxt-sub onmouseover=this.className='alc-cntxt-sub-o' onmouseout=this.className='alc-cntxt-sub'>해당행 높이조절 <input type=text id=unc-tab-hei-conf title='해당행 높이조절' style='width:40;height:15px;font-size:10px;'> <span onclick=\"Alice.table.rapHeightCol('" + alice + "','" + tid + "')\" style='cursor:pointer'>입력</span></td></tr>" + "<tr><td colspan=4 height=1 bgcolor=#dddddd></td></tr>"
								+ "<tr><td rowspan=5 class=alc-cntxt-main><img src=" + Alice.config.imageroot + "alice/editor/table_col.gif></td><td rowspan=5 valign=top style=padding-top:4><b>열 옵션</td><td onclick=\"Alice.table.appendColBefore('" + alice + "','" + tid + "')\" class=alc-cntxt-sub onmouseover=this.className='alc-cntxt-sub-o' onmouseout=this.className='alc-cntxt-sub'>좌측에 열 추가</td></tr>" + "<tr><td onclick=\"Alice.table.appendColAfter('" + alice + "','" + tid
								+ "')\" class=alc-cntxt-sub onmouseover=this.className='alc-cntxt-sub-o' onmouseout=this.className='alc-cntxt-sub'>우측에 열 추가</td></tr>" + "<tr><td onclick=\"Alice.table.removeCol('" + alice + "','" + tid + "')\" class=alc-cntxt-sub onmouseover=this.className='alc-cntxt-sub-o' onmouseout=this.className='alc-cntxt-sub'>해당열 삭제</td></tr>" + "<tr><td onclick=\"Alice.color.togglePicker('" + d2
								+ "')\" class=alc-cntxt-sub onmouseover=this.className='alc-cntxt-sub-o' onmouseout=this.className='alc-cntxt-sub'>해당열 배경색 <div style=position:absolute;left:300;width:200px;display:none id='" + d2 + "' onclick=\"Alice.table.colorCol('" + alice + "','" + tid + "')\"></div></td></tr>"
								+ "<tr><td class=alc-cntxt-sub onmouseover=this.className='alc-cntxt-sub-o' onmouseout=this.className='alc-cntxt-sub'>해당열 너비조절 <input type=text id=unc-tab-wid-conf title='해당열 너비조절' style='width:40;height:15px;font-size:10px;'> <span onclick=\"Alice.table.rapWidthCol('" + alice + "','" + tid + "')\" style='cursor:pointer'>입력</span></td></tr>" + "<tr><td colspan=4 height=1 bgcolor=#dddddd></td></tr>" + "<tr><td rowspan=4 class=alc-cntxt-main><img src="
								+ Alice.config.imageroot + "alice/editor/table_cell.gif></td><td rowspan=4 valign=top style=padding-top:4><b>셀 옵션</td><td onclick=\"Alice.table.mergeLeft('" + alice + "','" + tid + "')\" class=alc-cntxt-sub onmouseover=this.className='alc-cntxt-sub-o' onmouseout=this.className='alc-cntxt-sub'>좌측으로 합치기</td></tr>" + "<tr><td onclick=\"Alice.table.mergeRight('" + alice + "','" + tid
								+ "')\" class=alc-cntxt-sub onmouseover=this.className='alc-cntxt-sub-o' onmouseout=this.className='alc-cntxt-sub'>우측으로 합치기</td></tr>" + "<tr><td onclick=\"Alice.table.mergeDown('" + alice + "','" + tid + "')\" class=alc-cntxt-sub onmouseover=this.className='alc-cntxt-sub-o' onmouseout=this.className='alc-cntxt-sub'>아래로 합치기</td></tr>" + "<tr><td onclick=\"Alice.color.togglePicker('" + d3
								+ "')\" class=alc-cntxt-sub onmouseover=this.className='alc-cntxt-sub-o' onmouseout=this.className='alc-cntxt-sub'>해당셀 배경색 <div style=position:absolute;left:250;width:200px;display:none id='" + d3 + "' onclick=\"Alice.table.colorCell('" + alice + "','" + tid + "')\"></div></td></tr>" + "</table></td></tr></table>";
						
						Web.EditorManager.pullAllPop();
						Web.EditorManager.pushPop(div);
						
						return true;
					}
				}
			}
		},
		
		disableRange : function() {
			if (!this.popup) {
				this.setAliceRange(null);
			}
		},
		
		disableFocus : function() {
			if (!this.popup) {
				this.focus = false;
			}
		},
		
		focusAlice : function() {
			this.getAliceContentWindow().focus();
		},
		
		getAliceRange : function() {
			var cw = this.getAliceContentWindow();
			var range = null;
			if (Web.isIE) {
				range = this.range ? this.range : cw.document.selection.createRange();
			} else {
				range = cw.getSelection().getRangeAt(0);
			}
			return range;
		},
		
		setAliceRange : function(range) {
			this.range = range;
		},
		
		popupHide : function() {
			Web.CanvasManager.hideAll();
			if (Web.isIE) {
				if (!this.focus) {
					var cw = this.getAliceContentWindow();
					cw.focus();
				} else {
					if (this.range) {
						this.range.select();
						this.focusAlice();
					}
				}
			} else {
				this.focusAlice();
			}
			this.popup = false;
		},
		
		toggleAlice : function(m) {
			var cw = this.getAliceContentWindow();
			var tv = this.getAliceTextViewer();
			var s = this.seqId;
			
			if ((!m && this.mode == 'TEXT') || (m && m == 'HTML' && this.mode == 'TEXT')) {
				$1("alc-edit-view-" + s).style.display = "inline";
				tv.style.display = "none";
				cw.document.body.innerHTML = tv.value;
				if (this.status == "MAX") {
					Element.setStyle(this.aliceId, {
						height : Web.util.Position.clientHeight() - 53
					});
				} else if (this.status == "NORMAL") {
					Element.setStyle(this.aliceId, {
						height : this.aliceHeight - 53
					});
				}
				this.modifyImagePath();
				this.focusAlice();
				this.mode = 'HTML';
				
				var bttns = document.getElementsByTagName('button');
				for ( var i = 0; i < bttns.length; i++) {
					if (bttns[i].name.include('alc-bttns') || bttns[i].name.include('alc-select')) {
						if (bttns[i].getAttribute("enablebutton") != "on") {
							if (Web.isIE) {
								bttns[i].style.filter = 'alpha(opacity=100)';
							} else {
								bttns[i].style.MozOpacity = 1;
							}
							bttns[i].disabled = false;
						}
					}
				}
			} else if ((!m && this.mode == 'HTML') || (m && m == 'TEXT' && this.mode == 'HTML')) {
				$1("alc-edit-view-" + s).style.display = "none";
				tv.style.display = "inline";
				if (this.status == "MAX") {
					Element.setStyle(tv, {
						height : Web.util.Position.clientHeight() - 53
					});
				} else if (this.status == "NORMAL") {
					Element.setStyle(tv, {
						height : this.aliceHeight - 53
					});
				}
				this.modifyImagePath();
				tv.value = cw.document.body.innerHTML;
				tv.focus();
				this.mode = 'TEXT';
				
				var bttns = document.getElementsByTagName('button');
				for ( var i = 0; i < bttns.length; i++) {
					if (bttns[i].name.include('alc-bttns') || bttns[i].name.include('alc-select')) {
						if (bttns[i].getAttribute("enablebutton") != "on") {
							if (Web.isIE) {
								bttns[i].style.filter = 'alpha(opacity=50)';
							} else {
								bttns[i].style.MozOpacity = .5;
							}
							bttns[i].disabled = true;
						}
					}
				}
			}
			Web.EditorManager.pullAllPop();
		},
		
		getContentWithLimit : function() {
			var html = this.getHtml();
			if (this.isLimit()) {
				Web.alert({
					title : '경고',
					msg : '본문을 너무 많이 작성하셨습니다<br>최대 본문 작성가능 글자수는 <b>' + this.limit + '</b>바이트 입니다<br>현재 작성 글자수는 <b>' + html.getByte() + '</b>바이트 입니다',
					width : 400
				});
				return null;
			}
			return html;
		},
		
		getContent : function(v) {
			v = v || false;
			return this.getHtml(v);
		},
		
		isLimit : function() {
			var html = this.getHtml();
			return (this.limit > 0 && html.getByte() > this.limit);
		},
		
		getHtml : function(v) {
			
			var tv = this.getAliceTextViewer();
			var cw = this.getAliceContentWindow();
			if (this.mode == 'HTML') {
				if (!v) {
					this.modifyImagePath();
				
				}
			
				//html = cw.document.body.innerHTML;
				html = $(cw.document.body).html();
			
			} else if (this.mode == 'TEXT') {
				
				html = tv.value;
				
				
			}
			
			return html;
		},
		
		setContent : function(v) {
			
			var el = Web.EditorManager.get(this.aliceId);
			
			if(el !== undefined && el!== null && el.getContent()===v){
				return;
			}
			
			var cw = this.getAliceContentWindow();
			cw.document.body.innerHTML = v;
			this.modifyImagePath();
			this.focusAlice();
		},
		
		appendContent : function(v) {
			this.pasteHtmlToAlice(v);
		},
		
		getAliceContentWindow : function() {
			return $1(this.aliceId).contentWindow;
		},
		
		getAliceTextViewer : function() {
			return $1('alc-text-view-' + this.seqId);
		},
		
		appendStyle : function() {
			// this.setStyleSelectTag();
			this.setStyleButtonTag();
		},
		
		setStyleSelectTag : function() {
			var objs = $n("alc-select-" + this.seqId);
			for ( var i = 0; i < objs.length; i++) {
				if (objs[i]) {
					objs[i].style.borderStyle = "solid";
					objs[i].style.borderWidth = "1px";
					objs[i].style.borderColor = "#fafafa";
					objs[i].onmouseover = function() {
						this.style.borderColor = "#316ac5";
						this.style.backgroundColor = "#dff1ff";
					}
					objs[i].onmouseout = function() {
						this.style.borderColor = "#fafafa";
						this.style.backgroundColor = "#fafafa";
					}
				}
			}
		},
		
		setStyleButtonTag : function() {
			var objs = $n("alc-bttns-" + this.seqId);
			for ( var i = 0; i < objs.length; i++) {
				if (objs[i]) {
					objs[i].style.borderStyle = "solid";
					objs[i].style.borderWidth = "1px";
					objs[i].style.borderColor = "#fafafa";
					objs[i].onmouseover = function() {
						this.style.borderColor = "#316ac5";
						this.style.backgroundColor = "#dff1ff";
					}
					objs[i].onmouseout = function() {
						this.style.borderColor = "#fafafa";
						this.style.backgroundColor = "#fafafa";
					}
				}
			}
		},
		
		modifyImagePath : function() {
			var cw = this.getAliceContentWindow();
			var images = cw.document.getElementsByName("alc-images");
			for (i = 0; i < images.length; i++) {
				var src = images[i].src;
				if (src.include('http://' + Web.Location.domain())) {
					images[i].src = src.gsub('http://' + Web.Location.domain(), '');
				}
			}
			
			var anchors = cw.document.getElementsByTagName("a");
			for (i = 0; i < anchors.length; i++) {
				anchors.item(i).target = this.anchors;
			}
		},
		
		appendHtml : function(html, el) {
			if (el.insertAdjacentHTML) {
				el.insertAdjacentHTML('beforeBegin', html);
			} else {
				var oRange = document.createRange();
				oRange.setStartBefore(el);
				var oFragment = oRange.createContextualFragment(html);
				el.parentNode.insertBefore(oFragment, el);
			}
		},
		
		createHtml : function() {
			var seq = this.seqId;
			var image = Alice.config.imageroot;
			var ma = "<div onmouseover='' id=alc-box-" + seq + " class=alc-box style=\"width:" + this.aliceWidth + "px;height:" + this.aliceHeight + "px\">";
			var fu = "<div id=alc-edit-property-"
					+ seq
					+ " class=alc-edit-fields>"
					+ "<span title='소스보기'><button name=alc-bttns-"
					+ seq
					+ " onclick=\"Web.EditorManager.get('"
					+ this.aliceId
					+ "').toggleAlice();return false;\" enablebutton=on><img src="
					+ image
					+ "alice/editor/source.gif></button></span>"
					+ "<span title='에디터 내용 초기화'><button name=alc-bttns-"
					+ seq
					+ " onclick=\"Web.EditorManager.get('"
					+ this.aliceId
					+ "').initContextWindow();return false;\"><img src="
					+ image
					+ "alice/editor/newpage.gif></button></span>"
					+ "<span title='미리보기'><button name=alc-bttns-"
					+ seq
					+ " onclick=\"Web.EditorManager.get('"
					+ this.aliceId
					+ "').previewContextWindow();return false;\"><img src="
					+ image
					+ "alice/editor/preview.gif></button></span>"
					+ "<span title='프린트'><button name=alc-bttns-"
					+ seq
					+ " onclick=\"Web.EditorManager.get('"
					+ this.aliceId
					+ "').printContextWindow();return false;\"><img src="
					+ image
					+ "alice/editor/print.gif></button></span>"
					+ "<span><img src="
					+ image
					+ "alice/editor/gray_separator.gif></span>"
					+ "<span title='실행 취소하기'><button name=alc-bttns-"
					+ seq
					+ " onclick=\"Web.EditorManager.get('"
					+ this.aliceId
					+ "').command('Undo',-1);return false;\"><img src="
					+ image
					+ "alice/editor/undo.gif></button></span>"
					+ "<span title='다시 실행하기'><button name=alc-bttns-"
					+ seq
					+ " onclick=\"Web.EditorManager.get('"
					+ this.aliceId
					+ "').command('Redo',1);return false;\"><img src="
					+ image
					+ "alice/editor/redo.gif></button></span>"
					+ "<span><img src="
					+ image
					+ "alice/editor/gray_separator.gif></span>"
					+ "<span title='이미지 삽입'><button name=alc-bttns-"
					+ seq
					+ " onclick=\"Web.EditorManager.get('"
					+ this.aliceId
					+ "').popupImage();return false;\"><img src="
					+ image
					+ "alice/editor/pic.gif></button></span>"
					+ "<span title='이미지 링크 삽입'><button name=alc-bttns-"
					+ seq
					+ " onclick=\"Web.EditorManager.get('"
					+ this.aliceId
					+ "').popupUrlImage();return false;\"><img src="
					+ image
					+ "alice/editor/urlpic.gif></button></span>"
					+ "<span title='플래쉬 삽입'><button name=alc-bttns-"
					+ seq
					+ " onclick=\"Web.EditorManager.get('"
					+ this.aliceId
					+ "').popupFlash();return false;\"><img src="
					+ image
					+ "alice/editor/flash.gif></button></span>"
					+ "<span><img src="
					+ image
					+ "alice/editor/gray_separator.gif></span>"
					+ (this.aliceType == 'detail' || this.aliceType == 'normal' ? "<span title='텍스트 링크 삽입'><button name=alc-bttns-" + seq + " onclick=\"Web.EditorManager.get('" + this.aliceId + "').popupCreateLink();return false;\"><img src=" + image + "alice/editor/link.gif></button></span>" + "<span title='텍스트 링크 제거'><button name=alc-bttns-" + seq + " onclick=\"Web.EditorManager.get('" + this.aliceId + "').execute('Unlink');return false;\"><img src=" + image
							+ "alice/editor/unlink.gif></button></span>" + "<span><img src=" + image + "alice/editor/gray_separator.gif></span>" : "")
					+ "<span title='표 삽입'><button name=alc-bttns-"
					+ seq
					+ " onclick=\"Web.EditorManager.get('"
					+ this.aliceId
					+ "').popupTable();return false;\"><img src="
					+ image
					+ "alice/editor/table.gif></button></span>"
					+ "<span title='필드셋 삽입'><button name=alc-bttns-"
					+ seq
					+ " onclick=\"Web.EditorManager.get('"
					+ this.aliceId
					+ "').popupField();return false;\"><img src="
					+ image
					+ "alice/editor/fieldset.gif></button></span>"
					+ (this.aliceType == 'detail' ? "<span title='라인 삽입'><button name=alc-bttns-" + seq + " onclick=\"Web.EditorManager.get('" + this.aliceId + "').paste('Line');return false;\"><img src=" + image + "alice/editor/line.gif></button></span>" + "<span title='페이지 브레이크 삽입(프린트시 다음 페이지로 설정)'><button name=alc-bttns-" + seq + " onclick=\"Web.EditorManager.get('" + this.aliceId + "').paste('Break');return false;\"><img src=" + image + "alice/editor/pagebreak.gif></button></span>" : "")
					+ "<span><img src="
					+ image
					+ "alice/editor/gray_separator.gif></span>"
					+ "<span title='오른쪽 정렬'><button name=alc-bttns-"
					+ seq
					+ " onclick=\"Web.EditorManager.get('"
					+ this.aliceId
					+ "').execute('JustifyRight');return false;\"><img src="
					+ image
					+ "alice/editor/right.gif></button></span>"
					+ "<span title='가운데 정렬'><button name=alc-bttns-"
					+ seq
					+ " onclick=\"Web.EditorManager.get('"
					+ this.aliceId
					+ "').execute('JustifyCenter');return false;\"><img src="
					+ image
					+ "alice/editor/center.gif></button></span>"
					+ "<span title='왼쪽 정렬'><button name=alc-bttns-"
					+ seq
					+ " onclick=\"Web.EditorManager.get('"
					+ this.aliceId
					+ "').execute('JustifyLeft');return false;\"><img src="
					+ image
					+ "alice/editor/left.gif></button></span>"
					+ "<span title='전체 맞추기'><button name=alc-bttns-"
					+ seq
					+ " onclick=\"Web.EditorManager.get('"
					+ this.aliceId
					+ "').execute('JustifyFull');return false;\"><img src="
					+ image
					+ "alice/editor/full.gif></button></span>"
					+ "<span><img src="
					+ image
					+ "alice/editor/gray_separator.gif></span>"
					+ (this.aliceType == 'detail' || this.aliceType == 'normal' ? (this.aliceType == 'detail' ? "<span title='들여쓰기 줄임'><button name=alc-bttns-" + seq + " onclick=\"Web.EditorManager.get('" + this.aliceId + "').execute('Outdent');return false;\"><img src=" + image + "alice/editor/tableft.gif></button></span>" + "<span title='들여쓰기 늘림'><button name=alc-bttns-" + seq + " onclick=\"Web.EditorManager.get('" + this.aliceId + "').execute('Indent');return false;\"><img src=" + image
							+ "alice/editor/tabright.gif></button></span>" : "")
							+ "<span title='번호있는 목록 넣기'><button name=alc-bttns-"
							+ seq
							+ " onclick=\"Web.EditorManager.get('"
							+ this.aliceId
							+ "').execute('InsertOrderedList');return false;\"><img src="
							+ image
							+ "alice/editor/number.gif></button></span>"
							+ "<span title='번호없는 목록 넣기'><button name=alc-bttns-"
							+ seq
							+ " onclick=\"Web.EditorManager.get('"
							+ this.aliceId
							+ "').execute('InsertUnorderedList');return false;\"><img src="
							+ image
							+ "alice/editor/point.gif></button></span>"
							+ "<span><img src=" + image + "alice/editor/gray_separator.gif></span>" : "")
					+ "<span title='에디터 최대사이즈로'><button name=alc-bttns-"
					+ seq
					+ " onclick=\"Web.EditorManager.get('"
					+ this.aliceId
					+ "').extendContextWindow();return false;\"><img src="
					+ image
					+ "alice/editor/extend.gif></button></span>"
					+ "<span><img src="
					+ image
					+ "alice/editor/gray_separator.gif></span>"
					+ "</div>"
					+ "<div id=alc-text-property-"
					+ seq
					+ " class=alc-text-fields>"
					+ "<span title='스타일 적용'>"
					+ Web.util.Select.alice['alc-font-style'].gsub(/\{0\}/, seq).gsub(/\{1\}/, this.aliceId)
					+ "</span>"
					+ "<span title='폰트 적용'>"
					+ Web.util.Select.alice['alc-font-family'].gsub(/\{0\}/, seq).gsub(/\{1\}/, this.aliceId)
					+ "</span>"
					+ "<span title='폰트크기 적용'>"
					+ Web.util.Select.alice['alc-font-size'].gsub(/\{0\}/, seq).gsub(/\{1\}/, this.aliceId)
					+ "</span>"
					+ "<span><img src="
					+ image
					+ "alice/editor/gray_separator.gif></span>"
					+ "<span title='글자 배경색 넣기'>"
					+ Web.util.Select.alice['alc-font-bgcolor'].gsub(/\{0\}/, seq).gsub(/\{1\}/, this.aliceId).gsub(/\{2\}/, Alice.color.picker(this.seqId))
					+ "</span>"
					+ "<span title='글자색 넣기'>"
					+ Web.util.Select.alice['alc-font-forecolor'].gsub(/\{0\}/, seq).gsub(/\{1\}/, this.aliceId).gsub(/\{2\}/, Alice.color.picker(this.seqId))
					+ "</span>"
					+ "<span><img src="
					+ image
					+ "alice/editor/gray_separator.gif></span>"
					+ "<span title='글자 굵게'><button name=alc-bttns-"
					+ seq
					+ " onclick=\"Web.EditorManager.get('"
					+ this.aliceId
					+ "').execute('Bold');return false;\"><img src="
					+ image
					+ "alice/editor/bold.gif></button></span>"
					+ (this.aliceType == 'detail' || this.aliceType == 'normal' ? "<span title='글자 기울이기'><button name=alc-bttns-" + seq + " onclick=\"Web.EditorManager.get('" + this.aliceId + "').execute('Italic');return false;\"><img src=" + image + "alice/editor/italic.gif></button></span>" + "<span title='글자 밑줄넣기'><button name=alc-bttns-" + seq + " onclick=\"Web.EditorManager.get('" + this.aliceId + "').execute('Underline');return false;\"><img src=" + image
							+ "alice/editor/underline.gif></button></span>" + "<span title='글자 취소표시'><button name=alc-bttns-" + seq + " onclick=\"Web.EditorManager.get('" + this.aliceId + "').execute('Strikethrough');return false;\"><img src=" + image + "alice/editor/strikethrough.gif></button></span>" : "")
					+ "<span><img src="
					+ image
					+ "alice/editor/gray_separator.gif></span>"
					+ (this.aliceType == 'detail' || this.aliceType == 'normal' ? (this.aliceType == 'detail' ? "<span title='아랫 첨자'><button name=alc-bttns-" + seq + " onclick=\"Web.EditorManager.get('" + this.aliceId + "').execute('Subscript');return false;\"><img src=" + image + "alice/editor/subscript.gif></button></span>" + "<span title='윗 첨자'><button name=alc-bttns-" + seq + " onclick=\"Web.EditorManager.get('" + this.aliceId + "').execute('Superscript');return false;\"><img src=" + image
							+ "alice/editor/superscript.gif></button></span>" + "<span><img src=" + image + "alice/editor/gray_separator.gif></span>" : "")
							+ "<span title='포맷 지우기'><button name=alc-bttns-"
							+ seq
							+ " onclick=\"Web.EditorManager.get('"
							+ this.aliceId
							+ "').execute('RemoveFormat');return false;\"><img src="
							+ image
							+ "alice/editor/removeformat.gif></button></span>"
							+ (this.aliceType == 'detail' ? "<span title='아이콘 넣기'><button name=alc-bttns-" + seq + " onclick=\"Web.EditorManager.get('" + this.aliceId + "').popupIcon();return false;\"><img src=" + image + "alice/editor/icon.gif></button></span>" + "<span title='전체 선택하기'><button name=alc-bttns-" + seq + " onclick=\"Web.EditorManager.get('" + this.aliceId + "').execute('SelectAll');return false;\"><img src=" + image + "alice/editor/selectall.gif></button></span>" : "")
							+ "<span title='특수문자 넣기'><button name=alc-bttns-" + seq + " onclick=\"Web.EditorManager.get('" + this.aliceId + "').popupSpecialChar();return false;\"><img src=" + image + "alice/editor/specialchar.gif></button></span>" + "<span><img src=" + image + "alice/editor/gray_separator.gif></span>" : "") + "</div>";
			
			var bo = "<div>" + "<textarea id=alc-text-view-" + seq + " class=alc-dummy></textarea>" + "<span id=alc-edit-view-" + seq + ">" + "<iframe id=alice-" + seq + " class=alc-frame marginwidth=10 marginheight=10 frameborder=0 border=0 scrolling=" + (Web.isIE ? "yes" : "auto") + " style=\"height:"+this.aliceHeight2+"px;\"></iframe>" + "</span>" + "</div>";
			var fo = "</div>";
			return ma + fu + bo + fo;
		},
		
		pasteHtmlToAlice : function(value) {
			if (value != null) {
				var range = this.getAliceRange();
				if (Web.isIE) {
					if (!this.focus) {
						var cw = this.getAliceContentWindow();
						var type = cw.document.selection.type;
						cw.focus();
						cw.document.selection.createRange().pasteHTML(value);
					} else {
						if (range) {
							var cw = this.getAliceContentWindow();
							var type = cw.document.selection.type;
							range.select();
							try {
								range.pasteHTML(value);
							} catch (e) {
							}
							this.focusAlice();
						}
					}
				} else {
					this.focusAlice();
					if (range) {
						range.deleteContents();
						range.insertNode(range.createContextualFragment(value));
					}
				}
			}
		},
		
		command : function(cmd, optn) {
			var cw = this.getAliceContentWindow();
			if (Web.isIE) {
				var range = this.getAliceRange();
				if ('Undo,Redo,SelectAll'.include(cmd)) {
					range = cw.document.selection.createRange();
					range.select();
					var type = cw.document.selection.type;
					var target = (type == "None" ? cw.document : range);
					target.execCommand(cmd, false, optn);
				} else {
					if (!this.focus) {
						var cw = this.getAliceContentWindow();
						cw.focus();
						cw.document.selection.createRange().execCommand(cmd, false, optn);
					} else {
						if (range) {
							range.select();
							range.execCommand(cmd, false, optn);
						}
					}
				}
			} else {
				cw.document.execCommand(cmd, false, optn);
			}
			this.focusAlice();
		},
		
		paste : function(cmd, v) {
			if (cmd == 'Break') {
				this.pasteHtmlToAlice("<div style=\"PAGE-BREAK-AFTER: always\"><span style=\"DISPLAY: none\">&nbsp;</span></div>");
			} else if (cmd == 'Line') {
				this.pasteHtmlToAlice("<P><HR></P>");
			} else if (cmd == 'Char' || cmd == 'Icon') {
				this.pasteHtmlToAlice(v);
			}
		},
		
		appendFile : function(args) {
			this.file[args.physical] = {
				phsical : args.physical,
				full : args.full,
				logical : args.logical,
				size : args.size
			};
			if (this.invoke) {
				eval(this.invoke + "('" + args.physical + "','" + args.logical + "', " + args.size + ")");
			}
		},
		
		getPysicalFile : function() {
			var keys = this.file.keys();
			return keys.toJSON();
		},
		
		getLogicalFile : function() {
			var keys = this.file.keys();
			var ary = new Array;
			for ( var i = 0; i < keys.length; i++) {
				ary.push(this.file[keys[i]].logical);
			}
			return ary.toJSON();
		},
		
		getFullPhsycalFile : function() {
			var keys = this.file.keys();
			var ary = new Array;
			for ( var i = 0; i < keys.length; i++) {
				ary.push(this.file[keys[i]].full);
			}
			return ary.toJSON();
		},
		
		initContextWindow : function() {
			var cw = this.getAliceContentWindow();
			var rg = this.range;
			Web.yesno({
				title : '에디터 초기화',
				msg : '에디터 내용을 초기화 합니다',
				fnyes : function() {
					cw.document.body.innerHTML = '';
					cw.focus();
				},
				fnno : function() {
					cw.focus();
					if (rg) {
						rg.select();
					}
				}
			});
		},
		
		extendContextWindow : function() {
			if (this.status == "MAX") {
				$1("alc-box-" + this.seqId).style.zIndex = 0;
				$1("alc-box-" + this.seqId).style.position = "relative";
				Element.setStyle("alc-box-" + this.seqId, {
					width : this.aliceWidth,
					height : this.aliceHeight
				});
				Element.setStyle(this.aliceId, {
					width : '100%',
					height : this.aliceHeight - 53
				});
				this.status = "NORMAL";
				try {
					// document.body.style.overflowY = 'scroll';
					// document.body.style.overflowX = 'auto';
				} catch (e) {
				}
				;
			} else if (this.status == "NORMAL") {
				$1("alc-box-" + this.seqId).style.zIndex = 8080;
				$1("alc-box-" + this.seqId).style.position = "absolute";
				$1("alc-box-" + this.seqId).style.top = "0";
				$1("alc-box-" + this.seqId).style.left = "0";
				
				if (Web.isIE) {
					Element.setStyle("alc-box-" + this.seqId, {
						width : Web.util.Position.clientWidth(),
						height : Web.util.Position.clientHeight()
					});
					Element.setStyle(this.aliceId, {
						height : Web.util.Position.clientHeight() - 53
					});
				} else {
					Element.setStyle("alc-box-" + this.seqId, {
						width : Web.util.Position.clientWidth() - 18,
						height : Web.util.Position.clientHeight() - 2
					});
					Element.setStyle(this.aliceId, {
						height : Web.util.Position.clientHeight() - 53
					});
				}
				this.status = "MAX";
				
				try {
					document.body.scrollTop = 0;
					document.body.scrollLeft = 0;
					// document.body.style.overflowY = 'hidden';
					// document.body.style.overflowX = 'hidden';
				} catch (e) {
				}
				;
			}
			
		},
		
		previewContextWindow : function() {
			if (this.preview != null) {
				this.preview.close();
			}
			
			var w = (this.aliceWidth).toString();
			w = Web.util.Position.pure(w);
			var windowprops = "scrollbars=yes,left=50,top=50,width=" + (parseInt(w) + 18) + ",height=650";
			this.preview = window.open("about:blank", "_preview", windowprops);
			
			var cw = this.getAliceContentWindow();
			var txt = "<title>미리보기</title>" + "<style type='text/css'>P {margin-top:3px;margin-bottom:3px;margin-left:3;margin-right:3;white-space: -moz-pre-wrap;word-break:break-all;}</style>" + "<table border=0 cellspacing=0 cellpadding=0 width=100% height=100% style=\"cursor:pointer\" onclick=\"window.close()\"><tr><td align=center valign=top>" + "<table border=0 cellspacing=1 cellpadding=0 bgcolor=#dddddd width=98% height=100%><tr><td valign=top>"
					+ "<table border=0 cellspacing=0 cellpadding=0 bgcolor=#ffffff width=100% height=100%><tr><td align=center>" + "<table border=0 cellspacing=0 cellpadding=0 width=98% height=98%><tr><td valign=top><br>" + cw.document.body.innerHTML + "</td></tr></table></td></tr></table></td></tr></table></td></tr></table>";
			
			this.preview.document.open();
			this.preview.document.write(txt);
			this.preview.document.close();
		},
		
		printContextWindow : function() {
			this.focusAlice();
			window.print();
		},
		
		execute : function(cmd) {
			this.command(cmd);
		},
		
		popupFontStyle : function() {
			this.fontDisplayHidden("alc-font-style-box-");
		},
		
		popupFontFamily : function() {
			this.fontDisplayHidden("alc-font-family-box-");
		},
		
		popupFontSize : function() {
			this.fontDisplayHidden("alc-font-size-box-");
		},
		
		popupBackgroundColor : function() {
			this.fontDisplayHidden("alc-font-bgcolor-box-");
		},
		
		popupForegroundColor : function() {
			this.fontDisplayHidden("alc-font-forecolor-box-");
		},
		
		fontDisplayHidden : function(id) {
			if (!id) {
				this.fontStyleHidden();
				this.fontFamilyHidden();
				this.fontSizeHidden();
				this.fontBackColorHidden();
				this.fontForeColorHidden();
			} else {
				if ("alc-font-style-box-" != id) {
					this.fontStyleHidden();
				}
				if ("alc-font-family-box-" != id) {
					this.fontFamilyHidden();
				}
				if ("alc-font-size-box-" != id) {
					this.fontSizeHidden();
				}
				if ("alc-font-bgcolor-box-" != id) {
					this.fontBackColorHidden();
				}
				if ("alc-font-forecolor-box-" != id) {
					this.fontForeColorHidden();
				}
				this.toggleDisplay(id + this.seqId);
			}
		},
		
		fontStyleHidden : function() {
			$1("alc-font-style-box-" + this.seqId).style.display = 'none';
		},
		
		fontFamilyHidden : function() {
			$1("alc-font-family-box-" + this.seqId).style.display = 'none';
		},
		
		fontSizeHidden : function() {
			$1("alc-font-size-box-" + this.seqId).style.display = 'none';
		},
		
		fontBackColorHidden : function() {
			$1("alc-font-bgcolor-box-" + this.seqId).style.display = 'none';
		},
		
		fontForeColorHidden : function() {
			$1("alc-font-forecolor-box-" + this.seqId).style.display = 'none';
		},
		
		toggleDisplay : function(id) {
			if ($1(id).style.display == 'inline') {
				$1(id).style.display = 'none';
			} else {
				$1(id).style.display = 'inline';
			}
		},
		
		encodeHtml : function(txt) {
			if (typeof (txt) != "string") {
				txt = txt.toString();
			}
			txt = txt.replace(/&/g, "&amp;").replace(/"/g, "&quot;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
			return txt;
		},
		
		popupImage : function() {
			this.popup = true;
			var txt = "" + "<h3>이미지 설정</h3>" + "<form name=aliceForm id=aliceForm target=alc-hidden-frame action='"
					+ Alice.config.uploadpath
					+ "alice-upload' method=post enctype='multipart/form-data'>"
					+ "<table border=0 cellspacing=0 cellpadding=0 width=100%>"
					+ "<tr>"
					+ "<td class=alc-pop-bs1><li>이미지</li></td><td><input type=file name=alc-image-upload id=alc-image-upload style=width:325 onkeypress=this.blur()></td>"
					+ "</tr>"
					+ "<tr>"
					+ "<td class=alc-pop-bs1><li>이미지 설명</li></td><td><input type=text id=alc-image-alt style=width:325></td>"
					+ "</tr>"
					+ "<tr><td align=center colspan=2><br><span id=alc-image-uploadbtn onclick=\"Alice.image.upload()\">"
					+ Web.util.Image.alice['alc-crud-upload']
					+ "</span><span id=alc-image-loading style=display:none>"
					+ Web.util.Image.alice['alc-crud-loading']
					+ "</span></td></tr>"
					+ "<tr>"
					+ "<td colspan=2>"
					+ "<table border=0 cellspacing=0 cellpadding=0 width=100%>"
					+ "<tr>"
					+ "<td class=alc-pop-bs1><li>너비</li></td><td><input type=text id=alc-image-width title\"너비\" style=width:50 onkeyup=Alice.image.keyupWidth()></td>"
					+ "<td align=center rowspan=7 class=alc-pop-bs0 valign=top><strong>미리보기</strong><br><div style='padding:2px 2px 2px 2px;width:250px;height:130px;overflow:auto;border:1px solid #336699;background-color:#fff;font-size:8pt' id=alc-image-preview-text>"
					+ "<img id=alc-image-preview style='filter:gray(enabled=false) xray(enabled=false) fliph(enabled=false) flipv(enabled=false) blur(enabled=false,add:1,direction:135) invert(enabled=false);display:none'>"
					+ "동해물과 백두산이 마르고 닳도록 하느님이 보우하사 우리 나라 만세 남산위에 저 소나무 철갑을 두른듯 바람서리 불변함은 우리 기상일세 가을 하늘 공활한데 높고 구름 없이 밝은 달은 우리 가슴 일편 단심일세 이 기상과 이 맘으로 충성을 다하여 괴로우나 즐거우나 나라 사랑하세"
					+ "</div></td>"
					+ "</tr>"
					+ "<tr>"
					+ "<td class=alc-pop-bs1><li>높이</li></td><td><input type=text id=alc-image-height title\"높이\" style=width:50 onkeyup=Alice.image.keyupHeight()></td>"
					+ "</tr>"
					+ "<tr>"
					+ "<td class=alc-pop-bs1><li>테두리</li></td><td><input type=text id=alc-image-border title\"테두리\" style=width:50 onkeyup=Alice.image.keyupBorder()></td>"
					+ "</tr>"
					+ "<tr>"
					+ "<td class=alc-pop-bs1><li>수평여백</li></td><td><input type=text id=alc-image-hspace title\"수평여백\" style=width:50 onkeyup=Alice.image.keyupHspace()></td>"
					+ "</tr>"
					+ "<tr>"
					+ "<td class=alc-pop-bs1><li>수직여백</li></td><td><input type=text id=alc-image-vspace title\"수직여백\" style=width:50 onkeyup=Alice.image.keyupVspace()></td>"
					+ "</tr>"
					+ "<tr>"
					+ "<td class=alc-pop-bs1><li>정렬</li></td><td>"
					+ "<select id=alc-image-order onchange=Alice.image.changeOrder()>"
					+ "<option></option>"
					+ "<option value=left>왼쪽</option>"
					+ "<option value=right>오른쪽</option>"
					+ "<option value=top>위쪽</option>"
					+ "<option value=bottom>아래쪽</option>"
					+ "<option value=absmiddle>줄중간</option>"
					+ "<option value=absbottom>줄아래</option>"
					+ "<option value=baseline>기준선</option>"
					+ "<option value=textTop>글자위</option>"
					+ "</select>"
					+ "<input type=hidden id=alc-is-upload value=N>"
					+ "<input type=hidden id=thumbsize name=thumbsize value="
					+ this.thumbnail
					+ ">"
					+ "</td>"
					+ "</tr>"
					+ "<tr>"
					+ "<td class=alc-pop-bs1><li>글과분리</li></td><td><input type=checkbox id=alc-image-break onclick=Alice.image.insertBreak()></td>"
					+ "</tr>"
					+ (Web.isIE ? "<tr>" + "<td colspan=3>" + "<table border=0 cellspacing=0 cellpadding=0 width=100%>" + "<tr>" + "<td class=alc-pop-bs1><li>흑백전환</li></td><td valign=top><input type=checkbox id=alc-image-black onclick=Alice.image.transformGray()></td>" + "<td class=alc-pop-bs1><li>엑스레이</li></td><td valign=top><input type=checkbox id=alc-image-xray onclick=Alice.image.transformXray()></td>"
							+ "<td class=alc-pop-bs1><li>색상반대</li></td><td valign=top><input type=checkbox id=alc-image-invert onclick=Alice.image.transformInvert()></td>" + "</tr>" + "<tr>" + "<td class=alc-pop-bs1><li>부드럽게</li></td><td valign=top><input type=checkbox id=alc-image-blur onclick=Alice.image.transformBlur()></td>" + "<td class=alc-pop-bs1><li>좌우변경</li></td><td valign=top><input type=checkbox id=alc-image-fliph onclick=Alice.image.transformFliph()></td>"
							+ "<td class=alc-pop-bs1><li>상하변경</li></td><td valign=top><input type=checkbox id=alc-image-flipv onclick=Alice.image.transformFlipv()></td>" + "</tr>" + "</table>" + "</td>" + "</tr>" : "") + "</table>" + "</td>" + "</tr>" + "</table>" + "</form>" + "<center><span onclick=Alice.image.apply('" + this.aliceId + "')>" + Web.util.Image.alice['alc-crud-apply'] + "</span>" + "<span onclick=\"Web.EditorManager.get('" + this.aliceId + "').popupHide()\">"
					+ Web.util.Image.alice['alc-crud-cancel'] + "</span>" + "</center>" + "<iframe src=about:blank name=alc-hidden-frame id=alc-hidden-frame class=alc-hddn-frame></iframe>";
			
			Web.popup({
				title : '이미지 설정',
				msg : txt,
				width : 500,
				height : 440
			});
			Web.Form.setStyle("aliceForm");
		},
		
		popupFlash : function() {
			this.popup = true;
			
			var txt = "" + "<h3>플래쉬 설정</h3>" + "<form name=aliceForm id=aliceForm target=alc-hidden-frame action='" + Alice.config.uploadpath + "alice-upload' method=post enctype='multipart/form-data'>" + "<table border=0 cellspacing=0 cellpadding=0 width=100%>" + "<tr>" + "<td class=alc-pop-bs1><li>플래쉬</li></td><td><input type=file name=alc-flash-upload id=alc-flash-upload style=width:320 onkeypress=this.blur()></td>" + "</tr>"
					+ "<tr><td align=center colspan=2><br><span id=alc-flash-uploadbtn onclick=\"Alice.flash.upload()\">" + Web.util.Image.alice['alc-crud-upload'] + "</span><span id=alc-flash-loading style=display:none>" + Web.util.Image.alice['alc-crud-loading'] + "</span></td></tr>" + "<tr>" + "<td colspan=2 >" + "<table border=0 cellspacing=0 cellpadding=0 width=100%>" + "<tr>" + "<td valign=top width=180><br>" + "<table border=0 cellspacing=0 cellpadding=0>" + "<tr>"
					+ "<td valign=top class=alc-pop-bs1><li>너비</li></td><td valign=top><input type=text id=alc-flash-width style=width:70 onkeyup=Alice.flash.keyupWidth()></td>" + "</tr>" + "<tr>" + "<td valign=top class=alc-pop-bs1><li>높이</li></td><td valign=top><input type=text id=alc-flash-height style=width:70 onkeyup=Alice.flash.keyupHeight()></td>" + "</tr>" + "</table>" + "</td>" + "<td align=center class=alc-pop-bs0 valign=top>"
					+ "<strong>미리보기</strong><br><div style='padding:2px 2px 2px 2px;width:230px;height:130px;overflow:auto;border:1px solid #336699;background-color:#fff' id=alc-flash-preview></div></td>" + "</table>" + "</td>" + "</tr>" + "</table>" + "</form>" + "<center><span onclick=Alice.flash.apply('" + this.aliceId + "')>" + Web.util.Image.alice['alc-crud-apply'] + "</span>" + "<span onclick=\"Web.EditorManager.get('" + this.aliceId + "').popupHide()\">"
					+ Web.util.Image.alice['alc-crud-cancel'] + "</span>" + "</center>" + "<input type=hidden name=alc-is-upload id=alc-is-upload value=N>" + "<iframe src=about:blank name=alc-hidden-frame id=alc-hidden-frame class=alc-hddn-frame></iframe>";
			
			Web.popup({
				title : '플래쉬 설정',
				msg : txt,
				width : 500,
				height : 350
			});
			Web.Form.setStyle("aliceForm");
		},
		
		popupTable : function() {
			this.popup = true;
			
			var txt = "" + "<h3>테이블 설정</h3>" + "<form name=aliceForm>" + "<table border=0 width=100% cellspacing=0 cellpadding=0 class=alc-pop-bs0>" + "<tr height=25>" + "<td width=25%><li>가로줄</li></td>" + "<td width=25%><Input type=text id=trow size=4 value=5></td>" + "<td width=25%><li>너비</li></td>" + "<td width=25%><input type=text id=twidth size=4 value=400> <select id=tsize><option value=picxel>픽셀</option><option value=percentage>퍼센트</option></select></td>" + "</tr>" + "<tr height=25>"
					+ "<td><li>세로줄</li></td>" + "<td><input type=text id=tcol size=4 value=3></td>" + "<td><li>높이</li></td>" + "<td><input type=text id=theight size=4 value=100> 픽셀</td>" + "</tr>" + "<tr height=25>" + "<td><li>테두리 크기</li></td>" + "<td><input type=text id=tborder size=4 value=1></td>" + "<td><li>셀간격</li></td>" + "<td><input type=text id=tspacing size=4 value=1></td>" + "</tr>" + "<tr height=25>" + "<td><li>정렬</li></td>" + "<td><select id=talign>"
					+ "<option value=no>설정되지않음</option>" + "<option value=left>왼쪽</option>" + "<option value=center>가운데</option>" + "<option value=right>오른쪽</option>" + "</select>" + "</td>" + "<td><li>셀여백</li></td>" + "<td><input type=text id=tpadding size=4 value=1></td>" + "</tr>" + "<tr height=25>" + "<td><li>테두리밝은색</li></td>" + "<td><input type=text id=tlight size=8 value=#999999></td>" + "<td><li>테두리어두우색</li></td>" + "<td><input type=text id=tdark size=8 value=#ffffff></td>" + "</tr>"
					+ "<tr height=25>" + "<td><li>캡션</li></td>" + "<td colspan=3><input type=text id=tcap style=width:400></td>" + "</tr>" + "<tr height=25>" + "<td><li>템플릿</li></td>" + "<td colspan=3>" + "<table border=0>" + "<tr bgcolor=#ffffff>" + "<td style='border:1px solid white' onmouseover=\"this.style.border='1px solid #709DBC'\" onmouseout=\"this.style.border='1px solid white'\"><table style=cursor:pointer onclick=\"Alice.table.template('"
					+ this.aliceId
					+ "')\"                               border=1 cellspacing=0 cellpadding=0><tr><td width=20>&nbsp;</td><td width=20>&nbsp;</td></tr><tr><td width=20>&nbsp;</td><td width=20>&nbsp;</td></tr></table></td>"
					+ "<td style='border:1px solid white' onmouseover=\"this.style.border='1px solid #709DBC'\" onmouseout=\"this.style.border='1px solid white'\"><table style=cursor:pointer onclick=\"Alice.table.template('"
					+ this.aliceId
					+ "',null,null,'#eeeeee')\"           border=1 cellspacing=0 cellpadding=0><tr bgcolor=#eeeeee><td width=20>&nbsp;</td><td width=20>&nbsp;</td></tr><tr><td width=20>&nbsp;</td><td width=20>&nbsp;</td></tr></table></td>"
					+ "<td style='border:1px solid white' onmouseover=\"this.style.border='1px solid #709DBC'\" onmouseout=\"this.style.border='1px solid white'\"><table style=cursor:pointer onclick=\"Alice.table.template('"
					+ this.aliceId
					+ "','black','#ffffff')\"             border=1 cellspacing=0 cellpadding=0 bordercolorlight=black bordercolordark=#ffffff><tr><td width=20>&nbsp;</td><td width=20>&nbsp;</td></tr><tr><td width=20>&nbsp;</td><td width=20>&nbsp;</td></tr></table></td>"
					+ "<td style='border:1px solid white' onmouseover=\"this.style.border='1px solid #709DBC'\" onmouseout=\"this.style.border='1px solid white'\"><table style=cursor:pointer onclick=\"Alice.table.template('"
					+ this.aliceId
					+ "','black','#ffffff','#eeeeee')\"   border=1 cellspacing=0 cellpadding=0 bordercolorlight=black bordercolordark=#ffffff><tr bgcolor=#eeeeee><td width=20>&nbsp;</td><td width=20>&nbsp;</td></tr><tr><td width=20>&nbsp;</td><td width=20>&nbsp;</td></tr></table></td>"
					+ "<td style='border:1px solid white' onmouseover=\"this.style.border='1px solid #709DBC'\" onmouseout=\"this.style.border='1px solid white'\"><table style=cursor:pointer onclick=\"Alice.table.template('"
					+ this.aliceId
					+ "','#555555','#ffffff')\"           border=1 cellspacing=0 cellpadding=0 bordercolorlight=#555555 bordercolordark=#ffffff><tr><td width=20>&nbsp;</td><td width=20>&nbsp;</td></tr><tr><td width=20>&nbsp;</td><td width=20>&nbsp;</td></tr></table></td>"
					+ "<td style='border:1px solid white' onmouseover=\"this.style.border='1px solid #709DBC'\" onmouseout=\"this.style.border='1px solid white'\"><table style=cursor:pointer onclick=\"Alice.table.template('"
					+ this.aliceId
					+ "','#555555','#ffffff','#eeeeee')\" border=1 cellspacing=0 cellpadding=0 bordercolorlight=#555555 bordercolordark=#ffffff><tr bgcolor=#eeeeee><td width=20>&nbsp;</td><td width=20>&nbsp;</td></tr><tr><td width=20>&nbsp;</td><td width=20>&nbsp;</td></tr></table></td>"
					+ "<td style='border:1px solid white' onmouseover=\"this.style.border='1px solid #709DBC'\" onmouseout=\"this.style.border='1px solid white'\"><table style=cursor:pointer onclick=\"Alice.table.template('"
					+ this.aliceId
					+ "','#999999','#ffffff')\"           border=1 cellspacing=0 cellpadding=0 bordercolorlight=#999999 bordercolordark=#ffffff><tr><td width=20>&nbsp;</td><td width=20>&nbsp;</td></tr><tr><td width=20>&nbsp;</td><td width=20>&nbsp;</td></tr></table></td>"
					+ "<td style='border:1px solid white' onmouseover=\"this.style.border='1px solid #709DBC'\" onmouseout=\"this.style.border='1px solid white'\"><table style=cursor:pointer onclick=\"Alice.table.template('"
					+ this.aliceId
					+ "','#999999','#ffffff','#eeeeee')\" border=1 cellspacing=0 cellpadding=0 bordercolorlight=#999999 bordercolordark=#ffffff><tr bgcolor=#eeeeee><td width=20>&nbsp;</td><td width=20>&nbsp;</td></tr><tr><td width=20>&nbsp;</td><td width=20>&nbsp;</td></tr></table></td>"
					+ "</tr>"
					+ "<tr bgcolor=#ffffff>"
					+ "<td style='border:1px solid white' onmouseover=\"this.style.border='1px solid #709DBC'\" onmouseout=\"this.style.border='1px solid white'\"><table style=cursor:pointer onclick=\"Alice.table.template('"
					+ this.aliceId
					+ "','#ffffff','#ffffff','#4F81BD','#D0D8E8','#E9EDF4')\" border=1 cellspacing=0 cellpadding=0 bordercolorlight=#ffffff bordercolordark=#ffffff><tr bgcolor=#4F81BD><td width=20>&nbsp;</td><td width=20>&nbsp;</td></tr><tr bgcolor=#D0D8E8><td width=20>&nbsp;</td><td width=20>&nbsp;</td></tr><tr bgcolor=#E9EDF4><td width=20>&nbsp;</td><td width=20>&nbsp;</td></tr></table></td>"
					+ "<td style='border:1px solid white' onmouseover=\"this.style.border='1px solid #709DBC'\" onmouseout=\"this.style.border='1px solid white'\"><table style=cursor:pointer onclick=\"Alice.table.template('"
					+ this.aliceId
					+ "','#ffffff','#ffffff','#000000','#CBCBCB','#E7E7E7')\" border=1 cellspacing=0 cellpadding=0 bordercolorlight=#ffffff bordercolordark=#ffffff><tr bgcolor=#000000><td width=20>&nbsp;</td><td width=20>&nbsp;</td></tr><tr bgcolor=#CBCBCB><td width=20>&nbsp;</td><td width=20>&nbsp;</td></tr><tr bgcolor=#E7E7E7><td width=20>&nbsp;</td><td width=20>&nbsp;</td></tr></table></td>"
					+ "<td style='border:1px solid white' onmouseover=\"this.style.border='1px solid #709DBC'\" onmouseout=\"this.style.border='1px solid white'\"><table style=cursor:pointer onclick=\"Alice.table.template('"
					+ this.aliceId
					+ "','#ffffff','#ffffff','#C0504D','#E8D0D0','#F4E9E9')\" border=1 cellspacing=0 cellpadding=0 bordercolorlight=#ffffff bordercolordark=#ffffff><tr bgcolor=#C0504D><td width=20>&nbsp;</td><td width=20>&nbsp;</td></tr><tr bgcolor=#E8D0D0><td width=20>&nbsp;</td><td width=20>&nbsp;</td></tr><tr bgcolor=#F4E9E9><td width=20>&nbsp;</td><td width=20>&nbsp;</td></tr></table></td>"
					+ "<td style='border:1px solid white' onmouseover=\"this.style.border='1px solid #709DBC'\" onmouseout=\"this.style.border='1px solid white'\"><table style=cursor:pointer onclick=\"Alice.table.template('"
					+ this.aliceId
					+ "','#ffffff','#ffffff','#9BBB59','#DEE7D1','#EFF3EA')\" border=1 cellspacing=0 cellpadding=0 bordercolorlight=#ffffff bordercolordark=#ffffff><tr bgcolor=#9BBB59><td width=20>&nbsp;</td><td width=20>&nbsp;</td></tr><tr bgcolor=#DEE7D1><td width=20>&nbsp;</td><td width=20>&nbsp;</td></tr><tr bgcolor=#EFF3EA><td width=20>&nbsp;</td><td width=20>&nbsp;</td></tr></table></td>"
					+ "<td style='border:1px solid white' onmouseover=\"this.style.border='1px solid #709DBC'\" onmouseout=\"this.style.border='1px solid white'\"><table style=cursor:pointer onclick=\"Alice.table.template('"
					+ this.aliceId
					+ "','#ffffff','#ffffff','#8064A2','#D8D3E0','#EDEAF0')\" border=1 cellspacing=0 cellpadding=0 bordercolorlight=#ffffff bordercolordark=#ffffff><tr bgcolor=#8064A2><td width=20>&nbsp;</td><td width=20>&nbsp;</td></tr><tr bgcolor=#D8D3E0><td width=20>&nbsp;</td><td width=20>&nbsp;</td></tr><tr bgcolor=#EDEAF0><td width=20>&nbsp;</td><td width=20>&nbsp;</td></tr></table></td>"
					+ "<td style='border:1px solid white' onmouseover=\"this.style.border='1px solid #709DBC'\" onmouseout=\"this.style.border='1px solid white'\"><table style=cursor:pointer onclick=\"Alice.table.template('"
					+ this.aliceId
					+ "','#ffffff','#ffffff','#EDEAF0','#D0E3EA','#E9F1F5')\" border=1 cellspacing=0 cellpadding=0 bordercolorlight=#ffffff bordercolordark=#ffffff><tr bgcolor=#EDEAF0><td width=20>&nbsp;</td><td width=20>&nbsp;</td></tr><tr bgcolor=#D0E3EA><td width=20>&nbsp;</td><td width=20>&nbsp;</td></tr><tr bgcolor=#E9F1F5><td width=20>&nbsp;</td><td width=20>&nbsp;</td></tr></table></td>"
					+ "<td style='border:1px solid white' onmouseover=\"this.style.border='1px solid #709DBC'\" onmouseout=\"this.style.border='1px solid white'\"><table style=cursor:pointer onclick=\"Alice.table.template('"
					+ this.aliceId
					+ "','#ffffff','#ffffff','#F79646','#FCDDCF','#FDEFE9')\" border=1 cellspacing=0 cellpadding=0 bordercolorlight=#ffffff bordercolordark=#ffffff><tr bgcolor=#F79646><td width=20>&nbsp;</td><td width=20>&nbsp;</td></tr><tr bgcolor=#FCDDCF><td width=20>&nbsp;</td><td width=20>&nbsp;</td></tr><tr bgcolor=#FDEFE9><td width=20>&nbsp;</td><td width=20>&nbsp;</td></tr></table></td>"
					+ "<td style='border:1px solid white' onmouseover=\"this.style.border='1px solid #709DBC'\" onmouseout=\"this.style.border='1px solid white'\"><table style=cursor:pointer onclick=\"Alice.table.template('"
					+ this.aliceId
					+ "','#ffffff','#ffffff','#FDEFE9','#CCFFCC','#FFFFCC')\" border=1 cellspacing=0 cellpadding=0 bordercolorlight=#ffffff bordercolordark=#ffffff><tr bgcolor=#FDEFE9><td width=20>&nbsp;</td><td width=20>&nbsp;</td></tr><tr bgcolor=#CCFFCC><td width=20>&nbsp;</td><td width=20>&nbsp;</td></tr><tr bgcolor=#FFFFCC><td width=20>&nbsp;</td><td width=20>&nbsp;</td></tr></table></td>"
					+ "</tr>"
					+ "</table>"
					+ "</td>"
					+ "</tr>"
					+ "</table>"
					+ "</form>"
					+ "<center><span onclick=Alice.table.auto('" + this.aliceId + "')>" + Web.util.Image.alice['alc-crud-apply'] + "</span>" + "<span onclick=\"Web.EditorManager.get('" + this.aliceId + "').popupHide()\">" + Web.util.Image.alice['alc-crud-cancel'] + "</span>" + "</center>";
			
			Web.popup({
				title : '테이블 설정',
				msg : txt,
				width : 570,
				height : 400
			});
			Web.Form.setStyle("aliceForm");
		},
		
		popupField : function() {
			this.popup = true;
			var txt = "" + "<h3>필드셋 설정</h3>" + "<form name=aliceForm>" + "<table border=0 width=100% cellspacing=0 cellpadding=0 class=alc-pop-bs0>" + "<tr height=25>" + "<td width=25%><li>너비</li></td>" + "<td width=25%><input type=text id=fwidth size=4 value=100> <select id=fsize><option value=picxel>픽셀</option><option value=percentage selected>퍼센트</option></select></td>" + "<td width=25%><li>높이</li></td>" + "<td width=25%><input type=text id=fheight size=4>픽셀</td>" + "</tr>"
					+ "<tr height=25>" + "<td><li>정렬</li></td>" + "<td><select id=falign>" + "<option value=no>설정되지않음</option>" + "<option value=left>왼쪽</option>" + "<option value=center>가운데</option>" + "<option value=right>오른쪽</option>" + "</select>" + "</td>" + "<td><li>글자색</li></td>" + "<td><input type=text id=fcolor size=8></td>" + "</tr>" + "<tr height=25>" + "<td><li>왼쪽여백</li></td>" + "<td><input type=text id=fpleft size=4 value=5></td>" + "<td><li>위쪽여백</li></td>"
					+ "<td><input type=text id=fptop size=4 value=5> 픽셀</td>" + "</tr>" + "<tr height=25>" + "<td><li>오른쪽여백</li></td>" + "<td><input type=text id=fpright size=4 value=5></td>" + "<td><li>아래쪽여백</li></td>" + "<td><input type=text id=fpbottom size=4 value=5></td>" + "</tr>" + "<tr height=25>" + "<td><li>배경색</li></td>" + "<td><Input type=text id=fbgcolor size=8 value=#ffffff></td>" + "<td><li>테두리</li></td>" + "<td><Input type=text id=fborder size=4 value=1></td>" + "</tr>"
					+ "<tr height=25>" + "<td><li>테두리색</li></td>" + "<td><input type=text id=fbordercolor size=8 value=#999999></td>" + "<td><li>테두리스타일</li></td>" + "<td><input type=radio name=fborderstyle value=solid checked>선 <input type=radio name=fborderstyle value=dotted>점선 <input type=radio name=fborderstyle value='none'>없음</td>" + "</tr>" + "<tr height=25>" + "<td><li>제목</li></td>" + "<td colspan=3><input type=text id=ftitle style=width:445></td>" + "</tr>" + "<tr>"
					+ "<td><li>템플릿</li></td>" + "<td colspan=3>" + "<table border=0 cellspacing=0 cellpadding=0 style=font-size:9pt>" + "<tr>" + "<td style=padding-right:4px><fieldset onclick=\"Alice.fieldset.template('"
					+ this.aliceId
					+ "', '#eeeeee','solid','#999999')\" onmouseover=this.style.color='red' onmouseout=this.style.color='' style='cursor:pointer;background-color:#eeeeee;width:50;height:40;margin :0;padding:0;'><center><br>필드셋</center></fieldset></td>"
					+ "<td style=padding-right:4px><fieldset onclick=\"Alice.fieldset.template('"
					+ this.aliceId
					+ "', '#eeeeee','none','#999999')\" onmouseover=this.style.color='red' onmouseout=this.style.color='' style='cursor:pointer;background-color:#eeeeee;width:50;height:40;margin :0;padding:0;border:none'><center><br>필드셋</center></fieldset>"
					+ "<td style=padding-right:4px><fieldset onclick=\"Alice.fieldset.template('"
					+ this.aliceId
					+ "', '#eeeeee','dotted','#999999')\" onmouseover=this.style.color='red' onmouseout=this.style.color='' style='cursor:pointer;background-color:#eeeeee;width:50;height:40;margin :0;padding:0;border:1px dotted #999999'><center><br>필드셋</center></fieldset>"
					+ "<td style=padding-right:4px><fieldset onclick=\"Alice.fieldset.template('"
					+ this.aliceId
					+ "', '#CAE5FF','solid','#90C8FF')\" onmouseover=this.style.color='red' onmouseout=this.style.color='' style='cursor:pointer;background-color:#CAE5FF;width:50;height:40;margin :0;padding:0;border:1px solid #90C8FF'><center><br>필드셋</center></fieldset>"
					+ "<td style=padding-right:4px><fieldset onclick=\"Alice.fieldset.template('"
					+ this.aliceId
					+ "', '#CAE5FF','dotted','#90C8FF')\" onmouseover=this.style.color='red' onmouseout=this.style.color='' style='cursor:pointer;background-color:#CAE5FF;width:50;height:40;margin :0;padding:0;border:1px dotted #90C8FF'><center><br>필드셋</center></fieldset>"
					+ "<td style=padding-right:4px><fieldset onclick=\"Alice.fieldset.template('"
					+ this.aliceId
					+ "', '#ffffee','solid','#999999','#660066')\" onmouseover=this.style.color='red' onmouseout=this.style.color='#660066' style='cursor:pointer;background-color:#ffffee;width:50;height:40;margin :0;padding:0;color:#660066'><center><br>필드셋</center></fieldset>"
					+ "<td style=padding-right:4px><fieldset onclick=\"Alice.fieldset.template('"
					+ this.aliceId
					+ "', '#ffffee','dotted','#999999','#660066')\" onmouseover=this.style.color='red' onmouseout=this.style.color='#660066' style='cursor:pointer;background-color:#ffffee;width:50;height:40;margin :0;padding:0;color:#660066;border:1px dotted #999999'><center><br>필드셋</center></fieldset>"
					+ "<td style=padding-right:4px><fieldset onclick=\"Alice.fieldset.template('"
					+ this.aliceId
					+ "', '#ffffee','none','#999999','#660066')\" onmouseover=this.style.color='red' onmouseout=this.style.color='#660066' style='cursor:pointer;background-color:#ffffee;width:50;height:40;margin :0;padding:0;color:#660066;border:none'><center><br>필드셋</center></fieldset>"
					+ "</tr>"
					+ "</table>"
					+ "</td>"
					+ "</tr>"
					+ "</table>"
					+ "</form>"
					+ "<center><span onclick=Alice.fieldset.apply('"
					+ this.aliceId
					+ "')>"
					+ Web.util.Image.alice['alc-crud-apply']
					+ "</span>"
					+ "<span onclick=\"Web.EditorManager.get('" + this.aliceId + "').popupHide()\">" + Web.util.Image.alice['alc-crud-cancel'] + "</span>" + "</center>";
			
			Web.popup({
				title : '필드셋 설정',
				msg : txt,
				width : 600,
				height : 340
			});
			Web.Form.setStyle("aliceForm");
		},
		
		popupUrlImage : function() {
			this.popup = true;
			var txt = "" + "<h3>이미지 링크 설정</h3>" + "<form name=aliceForm>" + "<table border=0 cellspacing=0 cellpadding=0 width=100%>" + "<tr>" + "<td class=alc-pop-bs1><li>이미지</li></td><td><input type=text id=alc-urlimage-link style=width:325></td>" + "</tr>" + "<tr>" + "<td class=alc-pop-bs1><li>이미지 설명</li></td><td><input type=text id=alc-urlimage-alt style=width:325></td>" + "</tr>" + "<tr><td align=center colspan=2><br><span onclick=\"Alice.urlimage.change()\">"
					+ Web.util.Image.alice['alc-crud-select'] + "</span></td></tr>" + "<tr>" + "<td colspan=2>" + "<table border=0 cellspacing=0 cellpadding=0 width=100%>" + "<tr>" + "<td class=alc-pop-bs1><li>너비</li></td><td><input type=text id=alc-urlimage-width title=\"너비\" style=width:50 onkeyup=Alice.urlimage.keyupWidth()></td>"
					+ "<td align=center rowspan=6 class=alc-pop-bs0 valign=top><strong>미리보기</strong><br><div style='padding:2px 2px 2px 2px;width:250px;height:130px;overflow:auto;border:1px solid #336699;background-color:#fff' id=alc-urlimage-preview-text>" + "<img id=alc-urlimage-preview style=display:none>"
					+ "경찰에 따르면 오씨 남매는 전농동, 중곡동, 청량리에 각각 공장, 재단방, 창고를 마련해두고 올해 5월부터 최근까지 명품과 똑같이 생긴 가방 9천145개(정품가 110억원)를 만든 뒤 해당 상표를 붙여 동대문과 남대문 상가의 도소매상들에게 판매한 혐의를 받고 있다. 조사 결과 구속된 오씨는 주요 명품회사들이 블랙리스트 1순위에 올려놓은 한국 최고의 짝퉁 기술자로서 다른 짝퉁 업자들이 질투해 고발하는 걸 피하기 위해 친형과 여동생을 각각 재단방과 공장의 책임자로 고용한 것으로 드러났다." + "</div></td>" + "</tr>" + "<tr>" + "<td class=alc-pop-bs1><li>높이</li></td><td><input type=text id=alc-urlimage-height title\"높이\" style=width:50 onkeyup=Alice.urlimage.keyupHeight()></td>" + "</tr>"
					+ "<tr>" + "<td class=alc-pop-bs1><li>테두리</li></td><td><input type=text id=alc-urlimage-border title\"테두리\" style=width:50 onkeyup=Alice.urlimage.keyupBorder()></td>" + "</tr>" + "<tr>" + "<td class=alc-pop-bs1><li>수평여백</li></td><td><input type=text id=alc-urlimage-hspace title\"수평여백\" style=width:50 onkeyup=Alice.urlimage.keyupHspace()></td>" + "</tr>" + "<tr>"
					+ "<td class=alc-pop-bs1><li>수직여백</li></td><td><input type=text id=alc-urlimage-vspace title\"수직여백\" style=width:50 onkeyup=Alice.urlimage.keyupVspace()></td>" + "</tr>" + "<tr>" + "<td class=alc-pop-bs1><li>정렬</li></td><td>" + "<select id=alc-urlimage-order onchange=Alice.urlimage.changeOrder()>" + "<option></option>" + "<option value=left>왼쪽</option>" + "<option value=right>오른쪽</option>" + "<option value=top>위쪽</option>" + "<option value=bottom>아래쪽</option>"
					+ "<option value=absmiddle>줄중간</option>" + "<option value=absbottom>줄아래</option>" + "<option value=baseline>기준선</option>" + "<option value=textTop>글자위</option>" + "</select>" + "<input type=hidden id=alc-is-createlink value=N>" + "</td>" + "</tr>" + "</table>" + "</td>" + "</tr>" + "<tr>" + "<td class=alc-pop-bs1><li>글과분리</li></td><td><input type=checkbox id=alc-urlimage-break onclick=Alice.urlimage.insertBreak()></td>" + "</tr>" + "</table>" + "</form>"
					+ "<center><span onclick=Alice.urlimage.apply('" + this.aliceId + "')>" + Web.util.Image.alice['alc-crud-apply'] + "</span>" + "<span onclick=\"Web.EditorManager.get('" + this.aliceId + "').popupHide()\">" + Web.util.Image.alice['alc-crud-cancel'] + "</span>" + "</center>";
			
			Web.popup({
				title : '이미지 링크 설정',
				msg : txt,
				width : 500,
				height : 380
			});
			Web.Form.setStyle("aliceForm");
		},
		
		popupIcon : function() {
			this.popup = true;
			var image = Alice.config.imageroot;
			var txt = "" + "<h3>아이콘 삽입</h3>" + "<table border=0 cellspacing=0 cellpadding=2 width=100%>" + "<tr>" + "<td onclick=\"Alice.icon.apply('" + this.aliceId + "','01')\"><img src=" + image + "alice/icon/01.gif></td>" + "<td onclick=\"Alice.icon.apply('" + this.aliceId + "','02')\"><img src=" + image + "alice/icon/02.gif></td>" + "<td onclick=\"Alice.icon.apply('" + this.aliceId + "','03')\"><img src=" + image + "alice/icon/03.gif></td>" + "<td onclick=\"Alice.icon.apply('"
					+ this.aliceId + "','04')\"><img src=" + image + "alice/icon/04.gif></td>" + "<td onclick=\"Alice.icon.apply('" + this.aliceId + "','05')\"><img src=" + image + "alice/icon/05.gif></td>" + "<td onclick=\"Alice.icon.apply('" + this.aliceId + "','06')\"><img src=" + image + "alice/icon/06.gif></td>" + "</tr>" + "<tr>" + "<td onclick=\"Alice.icon.apply('" + this.aliceId + "','07')\"><img src=" + image + "alice/icon/07.gif></td>" + "<td onclick=\"Alice.icon.apply('"
					+ this.aliceId + "','08')\"><img src=" + image + "alice/icon/08.gif></td>" + "<td onclick=\"Alice.icon.apply('" + this.aliceId + "','09')\"><img src=" + image + "alice/icon/09.gif></td>" + "<td onclick=\"Alice.icon.apply('" + this.aliceId + "','10')\"><img src=" + image + "alice/icon/10.gif></td>" + "<td onclick=\"Alice.icon.apply('" + this.aliceId + "','11')\"><img src=" + image + "alice/icon/11.gif></td>" + "<td onclick=\"Alice.icon.apply('" + this.aliceId
					+ "','12')\"><img src=" + image + "alice/icon/12.gif></td>" + "</tr>" + "<tr>" + "<td onclick=\"Alice.icon.apply('" + this.aliceId + "','13')\"><img src=" + image + "alice/icon/13.gif></td>" + "<td onclick=\"Alice.icon.apply('" + this.aliceId + "','14')\"><img src=" + image + "alice/icon/14.gif></td>" + "<td onclick=\"Alice.icon.apply('" + this.aliceId + "','15')\"><img src=" + image + "alice/icon/15.gif></td>" + "<td onclick=\"Alice.icon.apply('" + this.aliceId
					+ "','16')\"><img src=" + image + "alice/icon/16.gif></td>" + "<td onclick=\"Alice.icon.apply('" + this.aliceId + "','17')\"><img src=" + image + "alice/icon/17.gif></td>" + "<td onclick=\"Alice.icon.apply('" + this.aliceId + "','18')\"><img src=" + image + "alice/icon/18.gif></td>" + "</tr>" + "<tr>" + "<td onclick=\"Alice.icon.apply('" + this.aliceId + "','19')\"><img src=" + image + "alice/icon/19.gif></td>" + "<td onclick=\"Alice.icon.apply('" + this.aliceId
					+ "','20')\"><img src=" + image + "alice/icon/20.gif></td>" + "<td onclick=\"Alice.icon.apply('" + this.aliceId + "','21')\"><img src=" + image + "alice/icon/21.gif></td>" + "<td onclick=\"Alice.icon.apply('" + this.aliceId + "','22')\"><img src=" + image + "alice/icon/22.gif></td>" + "<td onclick=\"Alice.icon.apply('" + this.aliceId + "','23')\"><img src=" + image + "alice/icon/23.gif></td>" + "<td onclick=\"Alice.icon.apply('" + this.aliceId + "','24')\"><img src=" + image
					+ "alice/icon/24.gif></td>" + "</tr>" + "<tr>" + "<td onclick=\"Alice.icon.apply('" + this.aliceId + "','25')\"><img src=" + image + "alice/icon/25.gif></td>" + "<td onclick=\"Alice.icon.apply('" + this.aliceId + "','26')\"><img src=" + image + "alice/icon/26.gif></td>" + "<td onclick=\"Alice.icon.apply('" + this.aliceId + "','27')\"><img src=" + image + "alice/icon/27.gif></td>" + "<td onclick=\"Alice.icon.apply('" + this.aliceId + "','28')\"><img src=" + image
					+ "alice/icon/28.gif></td>" + "<td onclick=\"Alice.icon.apply('" + this.aliceId + "','29')\"><img src=" + image + "alice/icon/29.gif></td>" + "<td onclick=\"Alice.icon.apply('" + this.aliceId + "','30')\"><img src=" + image + "alice/icon/30.gif></td>" + "</tr>" + "<tr>" + "<td onclick=\"Alice.icon.apply('" + this.aliceId + "','31')\"><img src=" + image + "alice/icon/31.gif></td>" + "<td onclick=\"Alice.icon.apply('" + this.aliceId + "','32')\"><img src=" + image
					+ "alice/icon/32.gif></td>" + "<td onclick=\"Alice.icon.apply('" + this.aliceId + "','33')\"><img src=" + image + "alice/icon/33.gif></td>" + "<td onclick=\"Alice.icon.apply('" + this.aliceId + "','34')\"><img src=" + image + "alice/icon/34.gif></td>" + "<td onclick=\"Alice.icon.apply('" + this.aliceId + "','35')\"><img src=" + image + "alice/icon/35.gif></td>" + "<td onclick=\"Alice.icon.apply('" + this.aliceId + "','36')\"><img src=" + image + "alice/icon/36.gif></td>"
					+ "</tr>" + "<tr>" + "<td onclick=\"Alice.icon.apply('" + this.aliceId + "','37')\"><img src=" + image + "alice/icon/37.gif></td>" + "<td onclick=\"Alice.icon.apply('" + this.aliceId + "','38')\"><img src=" + image + "alice/icon/38.gif></td>" + "<td onclick=\"Alice.icon.apply('" + this.aliceId + "','39')\"><img src=" + image + "alice/icon/39.gif></td>" + "<td onclick=\"Alice.icon.apply('" + this.aliceId + "','40')\"><img src=" + image + "alice/icon/40.gif></td>"
					+ "<td onclick=\"Alice.icon.apply('" + this.aliceId + "','41')\"><img src=" + image + "alice/icon/41.gif></td>" + "<td onclick=\"Alice.icon.apply('" + this.aliceId + "','42')\"><img src=" + image + "alice/icon/42.gif></td>" + "</tr>" + "</table>" + "<br>" + "<center><span onclick=\"Web.EditorManager.get('" + this.aliceId + "').popupHide()\">" + Web.util.Image.alice['alc-crud-cancel'] + "</span>" + "</center>";
			
			Web.popup({
				title : '아이콘 삽입',
				msg : txt,
				width : 250,
				height : 280
			});
		},
		
		popupSpecialChar : function() {
			this.popup = true;
			var txt = "" + "<h3>특수문자 삽입</h3>" + "<table border=0 cellspacing=0 cellpadding=0 width=100%>" + "<tr>" + "<td width=82 align=center><input type=text id=alc-char-preivew readonly></td>" + "<td bgcolor=#C6D5E7>" + "<button onclick=\"Alice.char.apply('" + this.aliceId + "','ⓐ');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=ⓐ class='alc-bttns-char'>ⓐ</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId
					+ "','ⓑ');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=ⓑ class='alc-bttns-char'>ⓑ</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId + "','ⓒ');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=ⓒ class='alc-bttns-char'>ⓒ</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId
					+ "','ⓓ');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=ⓓ class='alc-bttns-char'>ⓓ</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId + "','ⓔ');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=ⓔ class='alc-bttns-char'>ⓔ</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId
					+ "','ⓕ');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=ⓕ class='alc-bttns-char'>ⓕ</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId + "','ⓖ');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=ⓖ class='alc-bttns-char'>ⓖ</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId
					+ "','ⓗ');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=ⓗ class='alc-bttns-char'>ⓗ</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId + "','ⓘ');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=ⓘ class='alc-bttns-char'>ⓘ</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId
					+ "','ⓙ');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=ⓙ class='alc-bttns-char'>ⓙ</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId + "','ⓚ');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=ⓚ class='alc-bttns-char'>ⓚ</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId
					+ "','ⓛ');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=ⓛ class='alc-bttns-char'>ⓛ</button><br>" + "<button onclick=\"Alice.char.apply('" + this.aliceId + "','ⓜ');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=ⓜ class='alc-bttns-char'>ⓜ</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId
					+ "','ⓝ');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=ⓝ class='alc-bttns-char'>ⓝ</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId + "','ⓞ');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=ⓞ class='alc-bttns-char'>ⓞ</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId
					+ "','ⓟ');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=ⓟ class='alc-bttns-char'>ⓟ</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId + "','ⓠ');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=ⓠ class='alc-bttns-char'>ⓠ</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId
					+ "','ⓡ');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=ⓡ class='alc-bttns-char'>ⓡ</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId + "','ⓢ');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=ⓢ class='alc-bttns-char'>ⓢ</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId
					+ "','ⓣ');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=ⓣ class='alc-bttns-char'>ⓣ</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId + "','ⓤ');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=ⓤ class='alc-bttns-char'>ⓤ</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId
					+ "','ⓥ');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=ⓥ class='alc-bttns-char'>ⓥ</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId + "','ⓦ');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=ⓦ class='alc-bttns-char'>ⓦ</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId
					+ "','ⓧ');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=ⓧ class='alc-bttns-char'>ⓧ</button><br>" + "<button onclick=\"Alice.char.apply('" + this.aliceId + "','ⓨ');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=ⓨ class='alc-bttns-char'>ⓨ</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId
					+ "','ⓩ');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=ⓩ class='alc-bttns-char'>ⓩ</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId + "','①');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=① class='alc-bttns-char'>①</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId
					+ "','②');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=② class='alc-bttns-char'>②</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId + "','③');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=③ class='alc-bttns-char'>③</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId
					+ "','④');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=④ class='alc-bttns-char'>④</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId + "','⑤');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=⑤ class='alc-bttns-char'>⑤</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId
					+ "','⑥');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=⑥ class='alc-bttns-char'>⑥</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId + "','⑦');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=⑦ class='alc-bttns-char'>⑦</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId
					+ "','⑧');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=⑧ class='alc-bttns-char'>⑧</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId + "','⑨');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=⑨ class='alc-bttns-char'>⑨</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId
					+ "','⑩');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=⑩ class='alc-bttns-char'>⑩</button>" + "</td>" + "</tr>" + "<tr>" + "<td colspan=2 bgcolor=#C6D5E7>" + "<button onclick=\"Alice.char.apply('" + this.aliceId + "','⑪');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=⑪ class='alc-bttns-char'>⑪</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId
					+ "','⑫');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=⑫ class='alc-bttns-char'>⑫</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId + "','⑬');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=⑬ class='alc-bttns-char'>⑬</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId
					+ "','⑭');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=⑭ class='alc-bttns-char'>⑭</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId + "','⑮');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=⑮ class='alc-bttns-char'>⑮</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId
					+ "','ㅿ');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=ㅿ class='alc-bttns-char'>ㅿ</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId + "','ㆀ');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=ㆀ class='alc-bttns-char'>ㆀ</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId
					+ "','ㆁ');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=ㆁ class='alc-bttns-char'>ㆁ</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId + "','ㆅ');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=ㆅ class='alc-bttns-char'>ㆅ</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId
					+ "','ㅹ');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=ㅹ class='alc-bttns-char'>ㅹ</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId + "','ㅸ');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=ㅸ class='alc-bttns-char'>ㅸ</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId
					+ "','ㆄ');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=ㆄ class='alc-bttns-char'>ㆄ</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId + "','½');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=½ class='alc-bttns-char'>½</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId
					+ "','＃');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=＃ class='alc-bttns-char'>＃</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId + "','＆');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=＆ class='alc-bttns-char'>＆</button><br>" + "<button onclick=\"Alice.char.apply('" + this.aliceId
					+ "','＊');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=＊ class='alc-bttns-char'>＊</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId + "','＠');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=＠ class='alc-bttns-char'>＠</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId
					+ "','§');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=§ class='alc-bttns-char'>§</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId + "','※');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=※ class='alc-bttns-char'>※</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId
					+ "','☆');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=☆ class='alc-bttns-char'>☆</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId + "','★');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=★ class='alc-bttns-char'>★</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId
					+ "','○');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=○ class='alc-bttns-char'>○</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId + "','●');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=● class='alc-bttns-char'>●</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId
					+ "','◎');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=◎ class='alc-bttns-char'>◎</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId + "','◇');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=◇ class='alc-bttns-char'>◇</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId
					+ "','◆');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=◆ class='alc-bttns-char'>◆</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId + "','□');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=□ class='alc-bttns-char'>□</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId
					+ "','■');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=■ class='alc-bttns-char'>■</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId + "','△');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=△ class='alc-bttns-char'>△</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId
					+ "','▲');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=▲ class='alc-bttns-char'>▲</button><br>" + "<button onclick=\"Alice.char.apply('" + this.aliceId + "','▽');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=▽ class='alc-bttns-char'>▽</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId
					+ "','▼');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=▼ class='alc-bttns-char'>▼</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId + "','→');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=→ class='alc-bttns-char'>→</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId
					+ "','←');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=← class='alc-bttns-char'>←</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId + "','↑');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=↑ class='alc-bttns-char'>↑</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId
					+ "','↓');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=↓ class='alc-bttns-char'>↓</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId + "','↔');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=↔ class='alc-bttns-char'>↔</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId
					+ "','〓');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=〓 class='alc-bttns-char'>〓</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId + "','◁');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=◁ class='alc-bttns-char'>◁</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId
					+ "','◀');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=◀ class='alc-bttns-char'>◀</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId + "','▷');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=▷ class='alc-bttns-char'>▷</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId
					+ "','▶');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=▶ class='alc-bttns-char'>▶</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId + "','♤');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=♤ class='alc-bttns-char'>♤</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId
					+ "','♠');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=♠ class='alc-bttns-char'>♠</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId + "','♡');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=♡ class='alc-bttns-char'>♡</button><br>" + "<button onclick=\"Alice.char.apply('" + this.aliceId
					+ "','♥');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=♥ class='alc-bttns-char'>♥</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId + "','♧');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=♧ class='alc-bttns-char'>♧</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId
					+ "','♣');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=♣ class='alc-bttns-char'>♣</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId + "','⊙');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=⊙ class='alc-bttns-char'>⊙</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId
					+ "','◈');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=◈ class='alc-bttns-char'>◈</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId + "','▣');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=▣ class='alc-bttns-char'>▣</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId
					+ "','◐');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=◐ class='alc-bttns-char'>◐</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId + "','◑');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=◑ class='alc-bttns-char'>◑</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId
					+ "','▒');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=▒ class='alc-bttns-char'>▒</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId + "','▤');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=▤ class='alc-bttns-char'>▤</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId
					+ "','▥');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=▥ class='alc-bttns-char'>▥</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId + "','▨');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=▨ class='alc-bttns-char'>▨</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId
					+ "','▧');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=▧ class='alc-bttns-char'>▧</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId + "','▦');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=▦ class='alc-bttns-char'>▦</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId
					+ "','▩');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=▩ class='alc-bttns-char'>▩</button><br>" + "<button onclick=\"Alice.char.apply('" + this.aliceId + "','♨');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=♨ class='alc-bttns-char'>♨</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId
					+ "','☏');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=☏ class='alc-bttns-char'>☏</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId + "','☎');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=☎ class='alc-bttns-char'>☎</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId
					+ "','☜');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=☜ class='alc-bttns-char'>☜</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId + "','☞');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=☞ class='alc-bttns-char'>☞</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId
					+ "','¶');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=¶ class='alc-bttns-char'>¶</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId + "','†');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=† class='alc-bttns-char'>†</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId
					+ "','‡');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=‡ class='alc-bttns-char'>‡</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId + "','↕');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=↕ class='alc-bttns-char'>↕</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId
					+ "','↗');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=↗ class='alc-bttns-char'>↗</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId + "','↙');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=↙ class='alc-bttns-char'>↙</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId
					+ "','↖');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=↖ class='alc-bttns-char'>↖</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId + "','↘');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=↘ class='alc-bttns-char'>↘</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId
					+ "','♭');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=♭ class='alc-bttns-char'>♭</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId + "','♩');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=♩ class='alc-bttns-char'>♩</button><br>" + "<button onclick=\"Alice.char.apply('" + this.aliceId
					+ "','♪');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=♪ class='alc-bttns-char'>♪</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId + "','♬');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=♬ class='alc-bttns-char'>♬</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId
					+ "','㉿');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=㉿ class='alc-bttns-char'>㉿</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId + "','㈜');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=㈜ class='alc-bttns-char'>㈜</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId
					+ "','№');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=№ class='alc-bttns-char'>№</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId + "','㏇');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=㏇ class='alc-bttns-char'>㏇</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId
					+ "','™');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=™ class='alc-bttns-char'>™</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId + "','㏂');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=㏂ class='alc-bttns-char'>㏂</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId
					+ "','㏘');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=㏘ class='alc-bttns-char'>㏘</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId + "','℡');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=℡ class='alc-bttns-char'>℡</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId
					+ "','®');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=® class='alc-bttns-char'>®</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId + "','＂');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=＂ class='alc-bttns-char'>＂</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId
					+ "','〔');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=〔 class='alc-bttns-char'>〔</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId + "','〕');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=〕 class='alc-bttns-char'>〕</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId
					+ "','〈');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=〈 class='alc-bttns-char'>〈</button><br>" + "<button onclick=\"Alice.char.apply('" + this.aliceId + "','〉');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=〉 class='alc-bttns-char'>〉</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId
					+ "','‘');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=‘ class='alc-bttns-char'>‘</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId + "','’');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=’ class='alc-bttns-char'>’</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId
					+ "','“');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=“ class='alc-bttns-char'>“</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId + "','”');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=” class='alc-bttns-char'>”</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId
					+ "','《');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=《 class='alc-bttns-char'>《</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId + "','》');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=》 class='alc-bttns-char'>》</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId
					+ "','「');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=「 class='alc-bttns-char'>「</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId + "','」');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=」 class='alc-bttns-char'>」</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId
					+ "','『');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=『 class='alc-bttns-char'>『</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId + "','』');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=』 class='alc-bttns-char'>』</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId
					+ "','【');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=【 class='alc-bttns-char'>【</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId + "','】');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=】 class='alc-bttns-char'>】</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId
					+ "','＄');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=＄ class='alc-bttns-char'>＄</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId + "','％');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=％ class='alc-bttns-char'>％</button><br>" + "<button onclick=\"Alice.char.apply('" + this.aliceId
					+ "','￦');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=￦ class='alc-bttns-char'>￦</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId + "','℃');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=℃ class='alc-bttns-char'>℃</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId
					+ "','Å');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=Å class='alc-bttns-char'>Å</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId + "','￠');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=￠ class='alc-bttns-char'>￠</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId
					+ "','￥');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=￥ class='alc-bttns-char'>￥</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId + "','℉');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=℉ class='alc-bttns-char'>℉</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId
					+ "','ℓ');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=ℓ class='alc-bttns-char'>ℓ</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId + "','㎘');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=㎘ class='alc-bttns-char'>㎘</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId
					+ "','㏄');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=㏄ class='alc-bttns-char'>㏄</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId + "','㎣');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=㎣ class='alc-bttns-char'>㎣</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId
					+ "','㎤');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=㎤ class='alc-bttns-char'>㎤</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId + "','㎥');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=㎥ class='alc-bttns-char'>㎥</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId
					+ "','㎦');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=㎦ class='alc-bttns-char'>㎦</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId + "','Ω');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=Ω class='alc-bttns-char'>Ω</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId
					+ "','Θ');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=Θ class='alc-bttns-char'>Θ</button><br>" + "<button onclick=\"Alice.char.apply('" + this.aliceId + "','Ξ');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=Ξ class='alc-bttns-char'>Ξ</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId
					+ "','Σ');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=Σ class='alc-bttns-char'>Σ</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId + "','Φ');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=Φ class='alc-bttns-char'>Φ</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId
					+ "','Ψ');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=Ψ class='alc-bttns-char'>Ψ</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId + "','Ω');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=Ω class='alc-bttns-char'>Ω</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId
					+ "','α');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=α class='alc-bttns-char'>α</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId + "','β');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=β class='alc-bttns-char'>β</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId
					+ "','γ');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=γ class='alc-bttns-char'>γ</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId + "','π');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=π class='alc-bttns-char'>π</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId
					+ "','χ');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=χ class='alc-bttns-char'>χ</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId + "','ψ');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=ψ class='alc-bttns-char'>ψ</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId
					+ "','ω');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=ω class='alc-bttns-char'>ω</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId + "','＋');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=＋ class='alc-bttns-char'>＋</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId
					+ "','－');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=－ class='alc-bttns-char'>－</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId + "','＜');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=＜ class='alc-bttns-char'>＜</button><br>" + "<button onclick=\"Alice.char.apply('" + this.aliceId
					+ "','＝');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=＝ class='alc-bttns-char'>＝</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId + "','＞');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=＞ class='alc-bttns-char'>＞</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId
					+ "','±');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=± class='alc-bttns-char'>±</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId + "','×');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=× class='alc-bttns-char'>×</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId
					+ "','÷');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=÷ class='alc-bttns-char'>÷</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId + "','≠');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=≠ class='alc-bttns-char'>≠</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId
					+ "','≤');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=≤ class='alc-bttns-char'>≤</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId + "','≥');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=≥ class='alc-bttns-char'>≥</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId
					+ "','∞');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=∞ class='alc-bttns-char'>∞</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId + "','∴');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=∴ class='alc-bttns-char'>∴</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId
					+ "','♂');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=♂ class='alc-bttns-char'>♂</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId + "','♀');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=♀ class='alc-bttns-char'>♀</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId
					+ "','∠');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=∠ class='alc-bttns-char'>∠</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId + "','⊥');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=⊥ class='alc-bttns-char'>⊥</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId
					+ "','⌒');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=⌒ class='alc-bttns-char'>⌒</button><br>" + "<button onclick=\"Alice.char.apply('" + this.aliceId + "','∂');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=∂ class='alc-bttns-char'>∂</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId
					+ "','∇');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=∇ class='alc-bttns-char'>∇</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId + "','≡');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=≡ class='alc-bttns-char'>≡</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId
					+ "','≒');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=≒ class='alc-bttns-char'>≒</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId + "','≪');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=≪ class='alc-bttns-char'>≪</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId
					+ "','≫');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=≫ class='alc-bttns-char'>≫</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId + "','√');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=√ class='alc-bttns-char'>√</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId
					+ "','∽');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=∽ class='alc-bttns-char'>∽</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId + "','∝');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=∝ class='alc-bttns-char'>∝</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId
					+ "','∵');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=∵ class='alc-bttns-char'>∵</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId + "','∫');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=∫ class='alc-bttns-char'>∫</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId
					+ "','∬');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=∬ class='alc-bttns-char'>∬</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId + "','∈');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=∈ class='alc-bttns-char'>∈</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId
					+ "','∋');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=∋ class='alc-bttns-char'>∋</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId + "','⊆');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=⊆ class='alc-bttns-char'>⊆</button><br>" + "<button onclick=\"Alice.char.apply('" + this.aliceId
					+ "','⊇');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=⊇ class='alc-bttns-char'>⊇</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId + "','⊂');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=⊂ class='alc-bttns-char'>⊂</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId
					+ "','⊃');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=⊃ class='alc-bttns-char'>⊃</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId + "','∪');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=∪ class='alc-bttns-char'>∪</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId
					+ "','∩');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=∩ class='alc-bttns-char'>∩</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId + "','∧');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=∧ class='alc-bttns-char'>∧</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId
					+ "','∨');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=∨ class='alc-bttns-char'>∨</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId + "','￢');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=￢ class='alc-bttns-char'>￢</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId
					+ "','⇒');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=⇒ class='alc-bttns-char'>⇒</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId + "','⇔');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=⇔ class='alc-bttns-char'>⇔</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId
					+ "','∀');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=∀ class='alc-bttns-char'>∀</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId + "','∃');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=∃ class='alc-bttns-char'>∃</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId
					+ "','∮');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=∮ class='alc-bttns-char'>∮</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId + "','∑');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=∑ class='alc-bttns-char'>∑</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId
					+ "','∏');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=∏ class='alc-bttns-char'>∏</button><br>" + "<button onclick=\"Alice.char.apply('" + this.aliceId + "','／');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=／ class='alc-bttns-char'>／</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId
					+ "','！');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=！ class='alc-bttns-char'>！</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId + "','？');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=？ class='alc-bttns-char'>？</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId
					+ "','＿');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=＿ class='alc-bttns-char'>＿</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId + "','￣');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=￣ class='alc-bttns-char'>￣</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId
					+ "','‥');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=‥ class='alc-bttns-char'>‥</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId + "','…');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=… class='alc-bttns-char'>…</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId
					+ "','〃');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=〃 class='alc-bttns-char'>〃</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId + "','＼');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=＼ class='alc-bttns-char'>＼</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId
					+ "','∼');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=∼ class='alc-bttns-char'>∼</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId + "','～');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=～ class='alc-bttns-char'>～</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId
					+ "','㉠');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=㉠ class='alc-bttns-char'>㉠</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId + "','㉡');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=㉡ class='alc-bttns-char'>㉡</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId
					+ "','㉢');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=㉢ class='alc-bttns-char'>㉢</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId + "','㉣');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=㉣ class='alc-bttns-char'>㉣</button><br>" + "<button onclick=\"Alice.char.apply('" + this.aliceId
					+ "','㉤');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=㉤ class='alc-bttns-char'>㉤</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId + "','㉥');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=㉥ class='alc-bttns-char'>㉥</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId
					+ "','㉦');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=㉦ class='alc-bttns-char'>㉦</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId + "','㉧');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=㉧ class='alc-bttns-char'>㉧</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId
					+ "','㉨');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=㉨ class='alc-bttns-char'>㉨</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId + "','㉩');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=㉩ class='alc-bttns-char'>㉩</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId
					+ "','㉪');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=㉪ class='alc-bttns-char'>㉪</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId + "','㉫');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=㉫ class='alc-bttns-char'>㉫</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId
					+ "','㉬');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=㉬ class='alc-bttns-char'>㉬</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId + "','㉭');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=㉭ class='alc-bttns-char'>㉭</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId
					+ "','㉮');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=㉮ class='alc-bttns-char'>㉮</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId + "','㉯');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=㉯ class='alc-bttns-char'>㉯</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId
					+ "','㉰');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=㉰ class='alc-bttns-char'>㉰</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId + "','㉱');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=㉱ class='alc-bttns-char'>㉱</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId
					+ "','㉲');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=㉲ class='alc-bttns-char'>㉲</button><br>" + "<button onclick=\"Alice.char.apply('" + this.aliceId + "','㉳');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=㉳ class='alc-bttns-char'>㉳</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId
					+ "','㉴');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=㉴ class='alc-bttns-char'>㉴</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId + "','㉵');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=㉵ class='alc-bttns-char'>㉵</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId
					+ "','㉶');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=㉶ class='alc-bttns-char'>㉶</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId + "','㉷');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=㉷ class='alc-bttns-char'>㉷</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId
					+ "','㉸');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=㉸ class='alc-bttns-char'>㉸</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId + "','㉹');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=㉹ class='alc-bttns-char'>㉹</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId
					+ "','㉺');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=㉺ class='alc-bttns-char'>㉺</button>" + "<button onclick=\"Alice.char.apply('" + this.aliceId + "','㉻');return false;\" onmouseover=Alice.char.over(this); onmouseout=Alice.char.out(this); value=㉻ class='alc-bttns-char'>㉻</button>" + "</td>" + "</tr>" + "</table><br>" + "<center><span onclick=\"Web.EditorManager.get('" + this.aliceId + "').popupHide()\">"
					+ Web.util.Image.alice['alc-crud-cancel'] + "</span>" + "</center>";
			
			Web.popup({
				title : '특수문자 삽입',
				msg : txt,
				width : 460,
				height : 600
			});
		},
		
		popupCreateLink : function() {
			this.popup = true;
			var txt = "" + "<h3>텍스트 링크 설정</h3>" + "<form name=aliceForm>" + "<table border=0 cellspacing=0 cellpadding=0 width=100%>" + "<tr>" + "<td class=alc-pop-bs1><li>링크</li></td><td><input type=text id=alc-link-url style=width:325></td>" + "</tr>" + "<tr>" + "<td class=alc-pop-bs1><li>텍스트</li></td><td><input type=text id=alc-link-text style=width:325></td>" + "</tr>" + "</table>" + "</form>" + "<center><span onclick=Alice.link.apply('" + this.aliceId + "')>"
					+ Web.util.Image.alice['alc-crud-apply'] + "</span>" + "<span onclick=\"Web.EditorManager.get('" + this.aliceId + "').popupHide()\">" + Web.util.Image.alice['alc-crud-cancel'] + "</span>" + "</center>";
			
			Web.popup({
				title : '텍스트 링크 설정',
				msg : txt,
				width : 500,
				height : 150
			});
			Web.Form.setStyle("aliceForm");
		}
	};
	
})();

Alice.image = {
	filename : '',
	filesize : 0,
	upload : function() {
		if (!$1("alc-image-upload").present()) {
			Web.alert({
				title : '경고',
				msg : '업로드할 이미지를 선택하세요'
			});
			return;
		}
		
		var fnm = $1("alc-image-upload").value;
		fnm = fnm.substring(fnm.lastIndexOf('\\') + 1);
		for ( var i = 0; i < fnm.length; i++) {
			if ("!@#$%^&*,;:'\"?=".indexOf(fnm.substring(i, i + 1)) > -1) {
				alert('파일명에 특수문자가 들어가면 안됩니다');
				return;
			}
		}
		
		if (!Web.Form.validateFile("alc-image-upload", "gif", "jpg", "png", "jpeg")) {
			Web.alert({
				title : '경고',
				msg : 'GIF,JPG,PNG,JPEG 파일만 업로가 가능합니다'
			});
			return;
		}
		
		this.loading(true);
		$1("aliceForm").submit();
	},
	preview : function(args) {
		this.loading(false);
		$1("alc-image-preview").style.display = '';
		$1("alc-image-preview").src = (Alice.config.uploadroot.empty() ? args.upload : Alice.config.uploadroot) + "/" + args.filename.substring(0, 8) + "/" + args.filename;
		// $1("alc-image-width").value = "";
		// $1("alc-image-height").value = "";
		// $1("alc-image-border").value = "";
		// $1("alc-image-hspace").value = "";
		// $1("alc-image-vspace").value = "";
		// $1("alc-image-order").selectedIndex = 0;
		$1("alc-is-upload").value = "Y";
		$1("alc-image-break").checked = false;
		this.filename = args.filename;
		this.filesize = args.filesize;
	},
	transformGray : function() {
		if ($1("alc-image-black").checked) {
			$1("alc-image-preview").filters[0].Enabled = true;
		} else {
			$1("alc-image-preview").filters[0].Enabled = false;
		}
	},
	transformXray : function() {
		if ($1("alc-image-xray").checked) {
			$1("alc-image-preview").filters[1].Enabled = true;
		} else {
			$1("alc-image-preview").filters[1].Enabled = false;
		}
	},
	transformFliph : function() {
		if ($1("alc-image-fliph").checked) {
			$1("alc-image-preview").filters[2].Enabled = true;
		} else {
			$1("alc-image-preview").filters[2].Enabled = false;
		}
	},
	transformFlipv : function() {
		if ($1("alc-image-flipv").checked) {
			$1("alc-image-preview").filters[3].Enabled = true;
		} else {
			$1("alc-image-preview").filters[3].Enabled = false;
		}
	},
	transformBlur : function() {
		if ($1("alc-image-blur").checked) {
			$1("alc-image-preview").filters[4].Enabled = true;
		} else {
			$1("alc-image-preview").filters[4].Enabled = false;
		}
	},
	transformInvert : function() {
		if ($1("alc-image-invert").checked) {
			$1("alc-image-preview").filters[5].Enabled = true;
		} else {
			$1("alc-image-preview").filters[5].Enabled = false;
		}
	},
	keyupWidth : function() {
		if ($1("alc-image-width").present() && Web.Form.validateNum("alc-image-width")) {
			Element.setStyle("alc-image-preview", {
				width : ($1("alc-image-width").value.include('px') ? $1("alc-image-width").value : $1("alc-image-width").value + 'px')
			});
		}
	},
	keyupHeight : function() {
		if ($1("alc-image-height").present() && Web.Form.validateNum("alc-image-height")) {
			Element.setStyle("alc-image-preview", {
				height : ($1("alc-image-height").value.include('px') ? $1("alc-image-height").value : $1("alc-image-height").value + 'px')
			});
		}
	},
	keyupBorder : function() {
		if ($1("alc-image-border").present() && Web.Form.validateNum("alc-image-border")) {
			$1("alc-image-preview").border = $1("alc-image-border").value;
		}
	},
	keyupHspace : function() {
		if ($1("alc-image-hspace").present() && Web.Form.validateNum("alc-image-hspace")) {
			$1("alc-image-preview").hspace = $1("alc-image-hspace").value;
		}
	},
	keyupVspace : function() {
		if ($1("alc-image-vspace").present() && Web.Form.validateNum("alc-image-vspace")) {
			$1("alc-image-preview").vspace = $1("alc-image-vspace").value;
		}
	},
	changeOrder : function() {
		$1("alc-image-preview").align = $1("alc-image-order").value;
	},
	removeClear : function() {
		var c = $1("alc-image-preview-text").innerHTML;
		var v1 = c.indexOf('clear=all');
		if (v1 > -1) {
			var v2 = c.substring(0, v1 - 4);
			var v3 = c.substring(v1 + 10, c.length);
			$1("alc-image-preview-text").update(v2 + v3);
		}
	},
	insertBreak : function() {
		if ($1("alc-is-upload").value == "Y") {
			if ($1("alc-image-break").checked) {
				var c = $1("alc-image-preview-text").innerHTML;
				var v1 = c.indexOf('>');
				var v2 = c.substring(0, v1 + 1);
				var v3 = c.substring(v1 + 1, c.length);
				$1("alc-image-preview-text").update(v2 + "<BR clear=all>" + v3);
			} else {
				this.removeClear();
			}
		}
	},
	
	apply : function(id) {
		if (!$1("alc-image-upload").present() || $1("alc-is-upload").value != "Y") {
			Web.alert({
				title : '경고',
				msg : '이미지를 선택후 업로드 버튼을 클릭하세요'
			});
			return;
		}
		var img = "<img src=" + $1("alc-image-preview").src + " name=alc-images " + ($1("alc-image-width").present() ? "width=" + $1("alc-image-width").value : "") + " " + ($1("alc-image-height").present() ? "height=" + $1("alc-image-height").value : "") + " " + ($1("alc-image-border").present() ? "border=" + $1("alc-image-border").value : "") + " " + ($1("alc-image-hspace").present() ? "hspace=" + $1("alc-image-hspace").value : "") + " "
				+ ($1("alc-image-vspace").present() ? "vspace=" + $1("alc-image-vspace").value : "") + " " + ($1("alc-image-order").selectedIndex > 0 ? "align=" + $1("alc-image-order").value : "") + " " + ($1("alc-image-alt").present() ? "alt='" + $1("alc-image-alt").value.gsub(/"/, '') + "'" : "") + " " + "onclick=\"this.src.viewer()\" " + "style='cursor:pointer;" + (Web.isIE ? "filter:" : "") + (Web.isIE && $1("alc-image-black").checked ? "gray(enalbed=true)" : "") + " "
				+ (Web.isIE && $1("alc-image-xray").checked ? "xray(enalbed=true)" : "") + " " + (Web.isIE && $1("alc-image-fliph").checked ? "fliph(enalbed=true)" : "") + " " + (Web.isIE && $1("alc-image-flipv").checked ? "flipv(enalbed=true)" : "") + " " + (Web.isIE && $1("alc-image-blur").checked ? "blur(enalbed=true,add:1,direction:135)" : "") + " " + (Web.isIE && $1("alc-image-invert").checked ? "invert(enalbed=true)" : "") + " " + "'>"
				+ ($1("alc-image-break").checked ? "<br clear=all></br>" : "");
		
		var sp = $1("alc-image-upload").value.split("\\");
		var fn = sp[sp.length - 1];
		var sc = $1("alc-image-preview").src;
		if (sc.include('http://' + Web.Location.domain())) {
			sc = sc.gsub('http://' + Web.Location.domain(), '');
		}
		
		var el = Web.EditorManager.get(id);
		el.popupHide();
		el.pasteHtmlToAlice(img);
		el.appendFile({
			physical : this.filename,
			full : sc,
			logical : fn,
			size : this.filesize
		});
	},
	loading : function(bu) {
		if (bu) {
			$1("alc-image-uploadbtn").style.display = 'none';
			$1("alc-image-loading").style.display = '';
		} else {
			$1("alc-image-uploadbtn").style.display = '';
			$1("alc-image-loading").style.display = 'none';
		}
	}
};

Alice.urlimage = {
	change : function() {
		if ($1("alc-urlimage-link").present()) {
			$1("alc-urlimage-preview").style.display = '';
			$1("alc-urlimage-preview").src = $1("alc-urlimage-link").value;
			$1("alc-urlimage-width").value = "";
			$1("alc-urlimage-height").value = "";
			$1("alc-urlimage-border").value = "";
			$1("alc-urlimage-hspace").value = "";
			$1("alc-urlimage-vspace").value = "";
			$1("alc-urlimage-order").selectedIndex = 0;
			$1("alc-urlimage-break").checked = false;
			$1("alc-is-createlink").value = "Y";
		} else {
			Web.alert({
				title : '경고',
				msg : '이미지 주소를 입력하세요',
				focus : "alc-urlimage-link"
			});
		}
	},
	keyupWidth : function() {
		if ($1("alc-urlimage-width").present() && Web.Form.validateNum("alc-urlimage-width")) {
			Element.setStyle("alc-urlimage-preview", {
				width : $1("alc-urlimage-width").value + 'px'
			});
		}
	},
	keyupHeight : function() {
		if ($1("alc-urlimage-height").present() && Web.Form.validateNum("alc-urlimage-height")) {
			Element.setStyle("alc-urlimage-preview", {
				height : $1("alc-urlimage-height").value + 'px'
			});
		}
	},
	keyupBorder : function() {
		if ($1("alc-urlimage-border").present() && Web.Form.validateNum("alc-urlimage-border")) {
			$1("alc-urlimage-preview").border = $1("alc-urlimage-border").value;
		}
	},
	keyupHspace : function() {
		if ($1("alc-urlimage-hspace").present() && Web.Form.validateNum("alc-urlimage-hspace")) {
			$1("alc-urlimage-preview").hspace = $1("alc-urlimage-hspace").value;
		}
	},
	keyupVspace : function() {
		if ($1("alc-urlimage-vspace").present() && Web.Form.validateNum("alc-urlimage-vspace")) {
			$1("alc-urlimage-preview").vspace = $1("alc-urlimage-vspace").value;
		}
	},
	changeOrder : function() {
		$1("alc-urlimage-preview").align = $1("alc-urlimage-order").value;
	},
	removeClear : function() {
		var c = $1("alc-urlimage-preview-text").innerHTML;
		var v1 = c.indexOf('clear=all');
		if (v1 > -1) {
			var v2 = c.substring(0, v1 - 4);
			var v3 = c.substring(v1 + 10, c.length);
			$1("alc-urlimage-preview-text").update(v2 + v3);
		}
	},
	insertBreak : function() {
		if ($1("alc-is-createlink").value == "Y") {
			if ($1("alc-urlimage-break").checked) {
				var c = $1("alc-urlimage-preview-text").innerHTML;
				var v1 = c.indexOf('>');
				var v2 = c.substring(0, v1 + 1);
				var v3 = c.substring(v1 + 1, c.length);
				$1("alc-urlimage-preview-text").update(v2 + "<BR clear=all>" + v3);
			} else {
				this.removeClear();
			}
		}
	},
	apply : function(id) {
		if ($1("alc-is-createlink").value != "Y") {
			Web.alert({
				title : '경고',
				msg : '이미지 주소를 입력 후 업로드 버튼을 클릭하세요',
				focus : "alc-urlimage-link"
			});
			return;
		}
		var img = "<img src=" + $1("alc-urlimage-preview").src + " name=alc-urlimages " + ($1("alc-urlimage-width").present() ? "width=" + $1("alc-urlimage-width").value : "") + " " + ($1("alc-urlimage-height").present() ? "height=" + $1("alc-urlimage-height").value : "") + " " + ($1("alc-urlimage-border").present() ? "border=" + $1("alc-urlimage-border").value : "") + " " + ($1("alc-urlimage-hspace").present() ? "hspace=" + $1("alc-urlimage-hspace").value : "") + " "
				+ ($1("alc-urlimage-vspace").present() ? "vspace=" + $1("alc-urlimage-vspace").value : "") + " " + ($1("alc-urlimage-order").selectedIndex > 0 ? "align=" + $1("alc-urlimage-order").value : "") + " " + ($1("alc-urlimage-alt").present() ? "alt=" + $1("alc-urlimage-alt").value.gsub(/"/, '') : "") + ">" + ($1("alc-urlimage-order").checked ? "<br clear=all>" : "");
		
		var el = Web.EditorManager.get(id);
		el.popupHide();
		el.pasteHtmlToAlice(img);
	}
};

Alice.flash = {
	src : '',
	width : '',
	height : '',
	filename : '',
	filesize : 0,
	upload : function() {
		if (!$1("alc-flash-upload").present()) {
			Web.alert({
				title : '경고',
				msg : '업로드할 플래쉬를 선택하세요'
			});
			return;
		}
		
		var fnm = $1("alc-flash-upload").value;
		fnm = fnm.substring(fnm.lastIndexOf('\\') + 1);
		for ( var i = 0; i < fnm.length; i++) {
			if ("!@#$%^&*,;:'\"?=".indexOf(fnm.substring(i, i + 1)) > -1) {
				alert('파일명에 특수문자가 들어가면 안됩니다');
				return;
			}
		}
		
		if (!Web.Form.validateFile("alc-flash-upload", "swf")) {
			Web.alert({
				title : '경고',
				msg : 'SWF 파일만 업로드해주세요'
			});
			return;
		}
		this.loading(true);
		$1("aliceForm").submit();
	},
	preview : function(args) {
		this.width = '';
		this.height = '';
		this.src = (Alice.config.uploadroot.empty() ? args.upload : Alice.config.uploadroot) + "/" + args.filename.substring(0, 8) + "/" + args.filename;
		
		this.loading(false);
		$1("alc-flash-preview").update(this.get({}));
		$1("alc-is-upload").value = "Y";
		this.filename = args.filename;
		this.filesize = args.filesize;
	},
	keyupWidth : function() {
		$1("alc-flash-preview").update(this.get({
			fwidth : $1("alc-flash-width").value,
			fheight : this.height
		}));
		this.width = $1("alc-flash-width").value;
	},
	keyupHeight : function() {
		$1("alc-flash-preview").update(this.get({
			fwidth : this.width,
			fheight : $1("alc-flash-height").value
		}));
		this.height = $1("alc-flash-height").value;
	},
	get : function(args) {
		return "<object name=alc-flashes classid=\"clsid:D27CDB6E-AE6D-11cf-96B8-444553540000\"" + "  codeBase=\"http://fpdownload.macromedia.com/pub/shockwave/cabs/flash/swflash.cab#version=8,0,0,0\" type=\"application/x-shockwave-flash\" " + (args.fwidth && args.fwidth.notEmpty() ? "width=" + args.fwidth : "") + " " + (args.fheight && args.fheight.notEmpty() ? "height=" + args.fheight : "") + ">" + "  <param name=\"movie\" value=\"" + this.src + "\">"
				+ "  <param name=\"quality\" value=\"high\">" + "  <embed src=\"" + this.src + "\" quality=\"high\" wmode=\"transparent\" type=\"application/x-shockwave-flash\" " + (args.fwidth && args.fwidth.notEmpty() ? "width=" + args.fwidth : "") + " " + (args.fheight && args.fheight.notEmpty() ? "height=" + args.fheight : "") + "></embed>" + "</object>";
	},
	apply : function(id) {
		if (!$1("alc-flash-upload").present() || $1("alc-is-upload").value != "Y") {
			Web.alert({
				title : '경고',
				msg : '플래쉬를 선택후 업로드 버튼을 클릭하세요'
			});
			return;
		}
		
		var sp = $1("alc-flash-upload").value.split("\\");
		var fn = sp[sp.length - 1];
		var sc = this.src;
		if (sc.include('http://' + Web.Location.domain())) {
			sc = sc.gsub('http://' + Web.Location.domain(), '');
		}
		
		var el = Web.EditorManager.get(id);
		el.popupHide();
		el.pasteHtmlToAlice(this.get({
			fwidth : this.width,
			fheight : this.height
		}));
		el.appendFile({
			physical : this.filename,
			full : sc,
			logical : fn,
			size : this.filesize
		});
	},
	loading : function(bu) {
		if (bu) {
			$1("alc-flash-uploadbtn").style.display = 'none';
			$1("alc-flash-loading").style.display = '';
		} else {
			$1("alc-flash-uploadbtn").style.display = '';
			$1("alc-flash-loading").style.display = 'none';
		}
	}
};

Alice.table = {
	trow : '',
	tcol : '',
	tsize : '',
	twidth : '',
	theight : '',
	tborder : '',
	tspacing : '',
	tpadding : '',
	talign : '',
	tlight : '',
	tdark : '',
	tcap : '',
	tbody : '',
	srcElement : null,
	
	initialize : function() {
		this.trow = !$1("trow").present() ? 1 : $1("trow").value;
		this.tcol = !$1("tcol").present() ? 1 : $1("tcol").value;
		this.tsize = $1("tsize").value;
		this.twidth = !$1("twidth").present() ? '' : ($1("tsize").value == 'picxel' ? 'width=' + $1("twidth").value : 'width=' + $1("twidth").value + '%');
		this.theight = !$1("theight").present() ? '' : 'height=' + $1("theight").value;
		this.tborder = !$1("tborder").present() ? '' : 'border=' + $1("tborder").value;
		this.tspacing = !$1("tspacing").present() ? '' : 'cellspacing=' + $1("tspacing").value;
		this.tpadding = !$1("tpadding").present() ? '' : 'cellpadding=' + $1("tpadding").value;
		this.talign = $1("talign").value == 'no' ? '' : 'align=' + $1("talign").value;
		this.tlight = !$1("tlight").present() ? '' : 'bordercolorlight=' + $1("tlight").value;
		this.tdark = !$1("tdark").present() ? '' : 'bordercolordark=' + $1("tdark").value;
		this.tcap = !$1("tcap").present() ? '' : '<caption>' + $1("tcap").value + '</caption>';
		
		this.rwidth = !$1("twidth").present() ? 400 : ($1("tsize").value == 'picxel' ? parseInt($1("twidth").value) : 600);
		this.rheight = !$1("theight").present() ? 100 : parseInt($1("theight").value);
	},
	
	template : function(id, tl, td, tb, dj, dh) {
		this.initialize();
		this.tlight = tl ? 'bordercolorlight=' + tl : '';
		this.tdark = td ? 'bordercolordark=' + td : '';
		this.tspacing = 'cellspacing=0';
		this.tpadding = 'cellpadding=0';
		tb = tb ? 'bgcolor=' + tb : '';
		dj = dj ? 'bgcolor=' + dj : '';
		dh = dh ? 'bgcolor=' + dh : '';
		var body = '';
		var seq = 1;
		var eheight = parseInt(this.rheight) / parseInt(this.trow);
		var ewidth = parseInt(this.rwidth) / parseInt(this.tcol);
		
		for ( var i = 0; i < this.trow; i++) {
			if (i == 0) {
				body += '<tr ' + tb + '>';
			} else {
				if (seq % 2 == 0)
					body += '<tr ' + dj + '>';
				else
					body += '<tr ' + dh + '>';
				seq++;
			}
			for ( var k = 0; k < this.tcol; k++) {
				body += '<td width=' + ewidth + ' height=' + eheight + ' >&#160;</td>';
			}
			body += '</tr>';
		}
		this.tbody = body;
		this.apply(id);
	},
	
	auto : function(id) {
		this.initialize();
		var eheight = parseInt(this.rheight) / parseInt(this.trow);
		var ewidth = parseInt(this.rwidth) / parseInt(this.tcol);
		var body = '';
		for ( var i = 0; i < this.trow; i++) {
			body += '<tr>';
			for ( var k = 0; k < this.tcol; k++) {
				body += '<td width=' + ewidth + ' height=' + eheight + ' >&#160;</td>';
			}
			body += '</tr>';
		}
		this.tbody = body;
		this.apply(id);
	},
	
	getMaxCellLength : function(id, t) {
		var max = 0;
		var el = Web.EditorManager.get(id);
		if (el) {
			var cw = el.getAliceContentWindow();
			var tab = cw.document.getElementById(t);
			for ( var i = 0; i < tab.rows.length; i++) {
				var row = tab.rows[i];
				if (max < row.cells.length) {
					max = row.cells.length;
				}
			}
		}
		return max;
	},
	
	getRowIndex : function(id, t) {
		var r = 0;
		var el = Web.EditorManager.get(id);
		if (el) {
			var cw = el.getAliceContentWindow();
			var tab = cw.document.getElementById(t);
			for ( var i = 0; i < tab.rows.length; i++) {
				var row = tab.rows[i];
				for ( var j = 0; j < row.cells.length; j++) {
					var cell = row.cells[j];
					if (cell == this.srcElement) {
						r = i;
						break;
					}
				}
			}
		}
		return r;
	},
	
	getCellIndex : function(id, t) {
		var c = 0;
		var el = Web.EditorManager.get(id);
		if (el) {
			var cw = el.getAliceContentWindow();
			var tab = cw.document.getElementById(t);
			
			for ( var i = 0; i < tab.rows.length; i++) {
				var row = tab.rows[i];
				for ( var j = 0; j < row.cells.length; j++) {
					var cell = row.cells[j];
					if (cell == this.srcElement) {
						c = j;
						break;
					}
				}
			}
		}
		return c;
	},
	
	appendRowBefore : function(id, t) {
		var el = Web.EditorManager.get(id);
		if (el) {
			var cw = el.getAliceContentWindow();
			var tab = cw.document.getElementById(t);
			var r = this.getRowIndex(id, t);
			this.appendRow(id, t, r);
		}
	},
	
	appendRowAfter : function(id, t) {
		var el = Web.EditorManager.get(id);
		if (el) {
			var cw = el.getAliceContentWindow();
			var tab = cw.document.getElementById(t);
			var r = this.getRowIndex(id, t);
			this.appendRow(id, t, r + 1);
		}
	},
	
	appendRow : function(id, t, v) {
		var el = Web.EditorManager.get(id);
		if (el) {
			var cw = el.getAliceContentWindow();
			var tab = cw.document.getElementById(t);
			if (tab.rows.length <= v) {
				v = -1;
			}
			var rm = this.getMaxCellLength(id, t);
			var r = tab.insertRow(v);
			for ( var i = 0; i < rm; i++) {
				r.insertCell().innerHTML = "&#160";
			}
		}
		Web.EditorManager.pullAllPop();
	},
	
	removeRow : function(id, t, v) {
		var el = Web.EditorManager.get(id);
		if (el) {
			var cw = el.getAliceContentWindow();
			var tab = cw.document.getElementById(t);
			
			var v1 = v == undefined ? this.getRowIndex(id, t) : v;
			if (tab.rows.length > 1 && tab.rows.length > v1) {
				tab.deleteRow(v1);
			} else {
				Web.alert({
					title : '경고',
					msg : '삭제할 수 있는 범위가 아닙니다'
				});
			}
		}
		Web.EditorManager.pullAllPop();
	},
	
	appendColBefore : function(id, t) {
		var el = Web.EditorManager.get(id);
		if (el) {
			var cw = el.getAliceContentWindow();
			var tab = cw.document.getElementById(t);
			var c = this.getCellIndex(id, t);
			this.appendCell(id, t, c);
		}
	},
	
	appendColAfter : function(id, t) {
		var el = Web.EditorManager.get(id);
		if (el) {
			var cw = el.getAliceContentWindow();
			var tab = cw.document.getElementById(t);
			var c = this.getCellIndex(id, t);
			this.appendCell(id, t, c + 1);
		}
	},
	
	appendCell : function(id, t, v) {
		var el = Web.EditorManager.get(id);
		if (el) {
			var cw = el.getAliceContentWindow();
			var tab = cw.document.getElementById(t);
			var r = this.getRowIndex(id, t);
			if (tab.rows(r).cells.length <= v) {
				v = -1;
			}
			for ( var i = 0; i < tab.rows.length; i++) {
				tab.rows[i].insertCell(v).innerHTML = "&#160";
			}
		}
		Web.EditorManager.pullAllPop();
	},
	
	removeCol : function(id, t) {
		var el = Web.EditorManager.get(id);
		if (el) {
			var cw = el.getAliceContentWindow();
			var tab = cw.document.getElementById(t);
			var v = this.getCellIndex(id, t);
			var r = this.getRowIndex(id, t);
			if (tab.rows(r).cells.length > 1 && tab.rows(r).cells.length > v) {
				for ( var i = 0; i < tab.rows.length; i++) {
					tab.rows[i].deleteCell(v);
				}
			} else {
				Web.alert({
					title : '경고',
					msg : '삭제할 수 있는 범위가 아닙니다'
				});
			}
		}
		Web.EditorManager.pullAllPop();
	},
	
	mergeLeft : function(id, t) {
		var el = Web.EditorManager.get(id);
		if (el) {
			var cw = el.getAliceContentWindow();
			var tab = cw.document.getElementById(t);
			
			var c = this.getCellIndex(id, t);
			var r = this.getRowIndex(id, t);
			c--;
			if (c > -1) {
				var cells = new Hash;
				for ( var i = 0; i < tab.rows.length; i++) {
					if (i == r) {
						var row = tab.rows[i];
						for ( var j = 0; j < row.cells.length; j++) {
							var cell = row.cells[j];
							cells[j] = {
								txt : cell.innerHTML,
								colSpan : cell.colSpan,
								rowSpan : cell.rowSpan
							};
						}
					}
				}
				
				var cl = tab.rows(r).cells.length;
				this.removeRow(id, t, r);
				var row = tab.insertRow(r);
				for ( var i = 0; i < cl; i++) {
					var cell = row.insertCell();
					if (c == i) {
						cell.colSpan = (parseInt(cells[i].colSpan) + parseInt(cells[i + 1].colSpan)).toString();
						cell.rowSpan = cells[i].rowSpan;
						cell.innerHTML = cells[i].txt;
						cell.style.textAlign = "center";
						i++;
					} else {
						cell.colSpan = cells[i].colSpan;
						cell.rowSpan = cells[i].rowSpan;
						cell.innerHTML = cells[i].txt;
					}
				}
			}
		}
		Web.EditorManager.pullAllPop();
	},
	
	mergeRight : function(id, t) {
		var el = Web.EditorManager.get(id);
		if (el) {
			var cw = el.getAliceContentWindow();
			var tab = cw.document.getElementById(t);
			
			var c = this.getCellIndex(id, t);
			var r = this.getRowIndex(id, t);
			var cl = tab.rows(r).cells.length;
			
			if (c < cl - 1) {
				var cells = new Hash;
				for ( var i = 0; i < tab.rows.length; i++) {
					if (i == r) {
						var row = tab.rows[i];
						for ( var j = 0; j < row.cells.length; j++) {
							var cell = row.cells[j];
							cells[j] = {
								txt : cell.innerHTML,
								colSpan : cell.colSpan,
								rowSpan : cell.rowSpan
							};
						}
					}
				}
				
				var cl = tab.rows(r).cells.length;
				this.removeRow(id, t, r);
				var row = tab.insertRow(r);
				for ( var i = 0; i < cl; i++) {
					var cell = row.insertCell();
					if (c == i) {
						cell.colSpan = (parseInt(cells[i].colSpan) + parseInt(cells[i + 1].colSpan)).toString();
						cell.rowSpan = cells[i].rowSpan;
						cell.innerHTML = cells[i + 1].txt;
						cell.style.textAlign = "center";
						i++;
					} else {
						cell.colSpan = cells[i].colSpan;
						cell.rowSpan = cells[i].rowSpan;
						cell.innerHTML = cells[i].txt;
					}
				}
			}
		}
		Web.EditorManager.pullAllPop();
	},
	
	mergeDown : function(id, t) {
		var el = Web.EditorManager.get(id);
		if (el) {
			var cw = el.getAliceContentWindow();
			var tab = cw.document.getElementById(t);
			
			var c = this.getCellIndex(id, t);
			var r = this.getRowIndex(id, t);
			
			if (r < tab.rows.length) {
				var rw = 0;
				for ( var i = 0; i < tab.rows.length; i++) {
					var row = tab.rows[i];
					for ( var j = 0; j < row.cells.length; j++) {
						var cell = row.cells[j];
						if (i == r && j == c) {
							rw = parseInt(cell.rowSpan);
						}
					}
				}
				
				var upCells = new Hash;
				var dwCells = new Hash;
				for ( var i = 0; i < tab.rows.length; i++) {
					var row = tab.rows[i];
					for ( var j = 0; j < row.cells.length; j++) {
						var cell = row.cells[j];
						if (i == r) {
							upCells[j] = {
								txt : cell.innerHTML,
								colSpan : cell.colSpan,
								rowSpan : cell.rowSpan,
								rno : cell.getAttribute('rno') || 0
							};
						} else if (i == (r + rw)) {
							dwCells[j] = {
								txt : cell.innerHTML,
								colSpan : cell.colSpan,
								rowSpan : cell.rowSpan,
								rno : cell.getAttribute('rno') || 0
							};
						}
					}
				}
				
				var cl1 = upCells.size();
				var cl2 = dwCells.size();
				var c2 = 0;
				this.removeRow(id, t, r);
				var row = tab.insertRow(r);
				var rc = 0;
				for ( var i = 0; i < cl1; i++) {
					var cell = row.insertCell();
					if (c == i) {
						c2 = i - rc + upCells[i].rno;
						cell.colSpan = upCells[i].colSpan;
						cell.rowSpan = (parseInt(upCells[i].rowSpan) + parseInt(dwCells[c2] ? dwCells[c2].rowSpan : 0)).toString();
						cell.innerHTML = upCells[i].txt;
					} else {
						cell.colSpan = upCells[i].colSpan;
						cell.rowSpan = upCells[i].rowSpan;
						cell.innerHTML = upCells[i].txt;
					}
					if (parseInt(upCells[i].rowSpan) > 1) {
						rc++;
					}
					cell.setAttribute('rno', upCells[i].rno);
				}
				
				this.removeRow(id, t, r + rw);
				row = tab.insertRow(r + rw);
				for ( var i = 0; i < cl2; i++) {
					if ((c2) == i) {
						continue;
					} else {
						var cell = row.insertCell();
						cell.colSpan = dwCells[i].colSpan;
						cell.rowSpan = dwCells[i].rowSpan;
						cell.innerHTML = dwCells[i].txt;
						if (i > c2) {
							cell.setAttribute('rno', dwCells[i].rno + 1);
						} else {
							cell.setAttribute('rno', dwCells[i].rno);
						}
					}
				}
			}
		}
		Web.EditorManager.pullAllPop();
	},
	
	colorRow : function(id, t) {
		var el = Web.EditorManager.get(id);
		if (el) {
			var cw = el.getAliceContentWindow();
			var tab = cw.document.getElementById(t);
			var r = this.getRowIndex(id, t);
			for ( var i = 0; i < tab.rows.length; i++) {
				if (i == r) {
					var row = tab.rows[i];
					for ( var j = 0; j < row.cells.length; j++) {
						row.cells[j].style.backgroundColor = Alice.color.selectedColor;
					}
				}
			}
			this.coloring = true;
		}
		Web.EditorManager.pullAllPop();
	},
	
	colorCol : function(id, t) {
		var el = Web.EditorManager.get(id);
		if (el) {
			var cw = el.getAliceContentWindow();
			var tab = cw.document.getElementById(t);
			var c = this.getCellIndex(id, t);
			for ( var i = 0; i < tab.rows.length; i++) {
				var row = tab.rows[i];
				for ( var j = 0; j < row.cells.length; j++) {
					if (c == j) {
						row.cells[j].style.backgroundColor = Alice.color.selectedColor;
					}
				}
			}
			this.coloring = true;
		}
		Web.EditorManager.pullAllPop();
	},
	
	colorCell : function(id, t) {
		var el = Web.EditorManager.get(id);
		if (el) {
			var cw = el.getAliceContentWindow();
			var tab = cw.document.getElementById(t);
			var c = this.getCellIndex(id, t);
			var r = this.getRowIndex(id, t);
			
			for ( var i = 0; i < tab.rows.length; i++) {
				if (r == i) {
					var row = tab.rows[i];
					for ( var j = 0; j < row.cells.length; j++) {
						if (c == j) {
							row.cells[j].style.backgroundColor = Alice.color.selectedColor;
						}
					}
				}
			}
			this.coloring = true;
		}
		Web.EditorManager.pullAllPop();
	},
	
	heightRow : function(id, t, add) {
		var el = Web.EditorManager.get(id);
		if (el) {
			var nhei = 0;
			var padd = 0;
			var cw = el.getAliceContentWindow();
			var tab = cw.document.getElementById(t);
			var r = this.getRowIndex(id, t);
			for ( var i = 0; i < tab.rows.length; i++) {
				if (i == r) {
					var row = tab.rows[i];
					for ( var j = 0; j < row.cells.length; j++) {
						nhei = row.cells[j].height;
					}
				}
			}
			
			if (nhei == '')
				return;
			nhei = parseInt(nhei);
			if (nhei > add)
				padd = (nhei - add) * -1;
			else
				padd = add - nhei;
			if (tab.height == '')
				return;
			tab.height = parseInt(tab.height) + padd;
			
			for ( var i = 0; i < tab.rows.length; i++) {
				if (i == r) {
					var row = tab.rows[i];
					for ( var j = 0; j < row.cells.length; j++) {
						row.cells[j].height = add;
					}
				}
			}
		}
		Web.EditorManager.pullAllPop();
	},
	
	widthCol : function(id, t, add) {
		var el = Web.EditorManager.get(id);
		if (el) {
			var nwid = 0;
			var padd = 0;
			var cw = el.getAliceContentWindow();
			var tab = cw.document.getElementById(t);
			var c = this.getCellIndex(id, t);
			for ( var i = 0; i < tab.rows.length; i++) {
				var row = tab.rows[i];
				for ( var j = 0; j < row.cells.length; j++) {
					if (c == j) {
						nwid = row.cells[j].width;
					}
				}
			}
			
			if (nwid == '')
				return;
			nwid = parseInt(nwid);
			if (nwid > add)
				padd = (nwid - add) * -1;
			else
				padd = add - nwid;
			if (tab.width == '')
				return;
			tab.width = parseInt(tab.width) + padd;
			
			for ( var i = 0; i < tab.rows.length; i++) {
				var row = tab.rows[i];
				for ( var j = 0; j < row.cells.length; j++) {
					if (c == j) {
						row.cells[j].width = add;
					}
				}
			}
		}
		Web.EditorManager.pullAllPop();
	},
	
	rapWidthCol : function(id, t) {
		if (!Web.Form.validateValue('unc-tab-wid-conf'))
			return;
		if (!Web.Form.validateNum('unc-tab-wid-conf'))
			return;
		
		Alice.table.widthCol(id, t, $1('unc-tab-wid-conf').value);
	},
	
	rapHeightCol : function(id, t) {
		if (!Web.Form.validateValue('unc-tab-hei-conf'))
			return;
		if (!Web.Form.validateNum('unc-tab-hei-conf'))
			return;
		Alice.table.heightRow(id, t, $1('unc-tab-hei-conf').value);
	},
	
	apply : function(id) {
		var txt = '<table id=alc-tab-' + id + '-t.' + (Web.Math.random()) + ' ' + this.twidth + ' ' + this.theight + ' ' + this.tborder + ' ' + this.tspacing + ' ' + this.tpadding + ' ' + this.talign + ' ' + this.tlight + ' ' + this.tdark + ' >' + this.tcap + '<tbody>' + this.tbody + '</tbody>' + '</table>';
		
		var el = Web.EditorManager.get(id);
		el.popupHide();
		el.pasteHtmlToAlice(txt);
	}
};

Alice.fieldset = {
	fpleft : '',
	fpright : '',
	fptop : '',
	fpbottom : '',
	fbgcolor : '',
	fwidth : '',
	fheight : '',
	fsize : '',
	fborder : '',
	fbordercolor : '',
	fborderstyle : '',
	fborderstr : '',
	falign : '',
	ftitle : '',
	fcolor : '',
	
	initialize : function() {
		this.fpright = !$1("fpright").present() ? 0 : $1("fpright").value;
		this.fpleft = !$1("fpleft").present() ? 0 : $1("fpleft").value;
		this.fpbottom = !$1("fpbottom").present() ? 0 : $1("fpbottom").value;
		this.fptop = !$1("fptop").present() ? 0 : $1("fptop").value;
		this.fbgcolor = !$1("fbgcolor").present() ? '' : 'background-color:' + $1("fbgcolor").value + ';';
		this.fsize = !$1("fsize").value == 'picxel' ? 'px' : '%';
		this.fwidth = !$1("fwidth").present() ? '' : 'width:' + $1("fwidth").value + this.fsize + ';';
		this.fheight = !$1("fheight").present() ? '' : 'height:' + $1("fheight").value + 'px;';
		this.fbordercolor = !$1("fbordercolor").present() ? '' : $1("fbordercolor").value;
		var nm = $n("fborderstyle");
		for ( var i = 0; i < nm.length; i++) {
			if (nm[i].checked) {
				this.fborderstyle = nm[i].value;
				break;
			}
		}
		this.fborder = !$1("fborder").present() ? '' : $1("fborder").value;
		this.fborderstr = (this.fborderstyle == 'none') ? 'border:none;' : 'border:' + this.fborder + 'px ' + this.fbordercolor + ' ' + this.fborderstyle + ';';
		this.falign = $1("falign").value == 'no' ? '' : 'align=' + $1("falign").value;
		this.ftitle = !$1("ftitle").present() ? '' : '<legend>' + $1("ftitle").value + '</legend>';
		this.fcolor = !$1("fcolor").present() ? '' : 'color:' + $1("fcolor").value + ';';
	},
	template : function(id, fb, fs, fsc, fc) {
		this.initialize();
		this.fbgcolor = !fb.present() ? '' : 'background-color:' + fb + ';';
		fsc = fsc ? fsc : '#999999';
		this.fcolor = fc ? 'color:' + fc + ';' : '';
		this.fborderstr = fs == 'none' ? 'border:none;' : 'border:1px ' + fsc + ' ' + fs + ';';
		this.apply(id);
	},
	auto : function(id) {
		this.initialize();
		this.apply(id);
	},
	apply : function(id) {
		var txt = '<fieldset style=\"padding:' + this.fpright + ',' + this.fpright + ',' + this.fpbottom + ',' + this.fptop + ';' + this.fbgcolor + this.fwidth + this.fheight + this.fborderstr + this.fcolor + ' ' + this.falign + '\">' + this.ftitle + "&#160;" + '</fieldset>';
		
		var el = Web.EditorManager.get(id);
		el.popupHide();
		el.pasteHtmlToAlice(txt);
	}
};

Alice.font = {
	setSize : function(id, sz) {
		var el = Web.EditorManager.get(id);
		el.fontSizeHidden();
		el.command('FontSize', sz);
	},
	
	setFamily : function(id, fn) {
		var el = Web.EditorManager.get(id);
		el.fontFamilyHidden();
		el.command('FontName', fn);
		
	},
	
	setStyle : function(id, st) {
		var el = Web.EditorManager.get(id);
		el.fontStyleHidden();
		el.command('FormatBlock', st);
	},
	
	setStylePlus : function(id, st) {
		if (st == 'STYLE01') {
			var el = Web.EditorManager.get(id);
			el.fontStyleHidden();
			el.command('Bold');
			el.command('ForeColor', '#FF0000');
			// el.command('FontName', 'Impact');
			el.command('FontSize', '4');
		} else if (st == 'STYLE02') {
			var el = Web.EditorManager.get(id);
			el.fontStyleHidden();
			el.command('Bold');
			el.command('ForeColor', '#0000FF');
			// el.command('FontName', 'Impact');
			el.command('FontSize', '4');
		} else if (st == 'STYLE03') {
			var el = Web.EditorManager.get(id);
			el.fontStyleHidden();
			el.command('Bold');
			el.command('ForeColor', '#000000');
			// el.command('FontName', 'Impact');
			el.command('FontSize', '4');
			el.command('Underline');
		} else if (st == 'STYLE04') {
			var el = Web.EditorManager.get(id);
			el.fontStyleHidden();
			el.command('BackColor', '#FFFF00');
		} else if (st == 'STYLE05') {
			var el = Web.EditorManager.get(id);
			el.fontStyleHidden();
			el.command('BackColor', '#00FF00');
		}
	}
};

Alice.link = {
	apply : function(id) {
		if (!$1("alc-link-url").present() || !$1("alc-link-text").present()) {
			Web.alert({
				title : '경고',
				msg : '링크를 만들 주소와 텍스트를 입력하세요',
				focus : "alc-link-url"
			});
			return;
		}
		
		var txt = "<a href='" + $1("alc-link-url").value + "' target=_blank>" + $1("alc-link-text").value.gsub(/"/, '') + "</a>";
		var el = Web.EditorManager.get(id);
		el.popupHide();
		el.pasteHtmlToAlice(txt);
	}
};

Alice.color = {
	hash : new Hash,
	seed : 0,
	selectedColor : '#000000',
	
	apply : function(id, cmd) {
		var el = Web.EditorManager.get(id);
		el.fontBackColorHidden();
		el.fontForeColorHidden();
		if (this.selectedColor == '000000') {
			this.selectedColor = '000001';
		}
		el.command(cmd, this.selectedColor);
	},
	
	picker : function(seq) {
		this.seed++;
		var txt = "<div class=alc-pick-box>";
		for ( var k = 0x00; k < 0x100; k += 0x33) {
			for ( var j = 0x00; j < 0x80; j += 0x33) {
				for ( var i = 0x00; i < 0x100; i += 0x33) {
					n = "" + (k.toString(16) == 0 ? '00' : k.toString(16)) + (j.toString(16) == 0 ? '00' : j.toString(16)) + (i.toString(16) == 0 ? '00' : i.toString(16));
					txt += "<div style='background-color:#" + n + "' title='#" + n + "' onmouseover=\"Alice.color.pick('" + n + "','" + seq + "','" + Alice.color.seed + "')\"></div>";
				}
			}
			txt += "";
		}
		
		for ( var k = 0x00; k < 0x100; k += 0x33) {
			for ( var j = 0x99; j < 0x100; j += 0x33) {
				for ( var i = 0x00; i < 0x100; i += 0x33) {
					n = "" + (k.toString(16) == 0 ? '00' : k.toString(16)) + (j.toString(16) == 0 ? '00' : j.toString(16)) + (i.toString(16) == 0 ? '00' : i.toString(16));
					txt += "<div style='background-color:#" + n + "' title='#" + n + "' onmouseover=\"Alice.color.pick('" + n + "','" + seq + "','" + Alice.color.seed + "')\"></div>";
				}
			}
			txt += "";
		}
		txt += "<div style='background-color:#000000' title='#000000' onmouseover=\"Alice.color.pick('#000000','" + seq + "','" + Alice.color.seed + "')\"></div>" + "<div style='background-color:#111111' title='#111111' onmouseover=\"Alice.color.pick('#111111','" + seq + "','" + Alice.color.seed + "')\"></div>" + "<div style='background-color:#222222' title='#222222' onmouseover=\"Alice.color.pick('#222222','" + seq + "','" + Alice.color.seed + "')\"></div>"
				+ "<div style='background-color:#333333' title='#333333' onmouseover=\"Alice.color.pick('#333333','" + seq + "','" + Alice.color.seed + "')\"></div>" + "<div style='background-color:#444444' title='#444444' onmouseover=\"Alice.color.pick('#444444','" + seq + "','" + Alice.color.seed + "')\"></div>" + "<div style='background-color:#555555' title='#555555' onmouseover=\"Alice.color.pick('#555555','" + seq + "','" + Alice.color.seed + "')\"></div>"
				+ "<div style='background-color:#666666' title='#666666' onmouseover=\"Alice.color.pick('#666666','" + seq + "','" + Alice.color.seed + "')\"></div>" + "<div style='background-color:#777777' title='#777777' onmouseover=\"Alice.color.pick('#777777','" + seq + "','" + Alice.color.seed + "')\"></div>" + "<div style='background-color:#888888' title='#888888' onmouseover=\"Alice.color.pick('#888888','" + seq + "','" + Alice.color.seed + "')\"></div>"
				+ "<div style='background-color:#999999' title='#999999' onmouseover=\"Alice.color.pick('#999999','" + seq + "','" + Alice.color.seed + "')\"></div>" + "<div style='background-color:#aaaaaa' title='#aaaaaa' onmouseover=\"Alice.color.pick('#aaaaaa','" + seq + "','" + Alice.color.seed + "')\"></div>" + "<div style='background-color:#bbbbbb' title='#bbbbbb' onmouseover=\"Alice.color.pick('#bbbbbb','" + seq + "','" + Alice.color.seed + "')\"></div>"
				+ "<div style='background-color:#cccccc' title='#cccccc' onmouseover=\"Alice.color.pick('#cccccc','" + seq + "','" + Alice.color.seed + "')\"></div>" + "<div style='background-color:#dddddd' title='#dddddd' onmouseover=\"Alice.color.pick('#dddddd','" + seq + "','" + Alice.color.seed + "')\"></div>" + "<div style='background-color:#eeeeee' title='#eeeeee' onmouseover=\"Alice.color.pick('#eeeeee','" + seq + "','" + Alice.color.seed + "')\"></div>"
				+ "<div style='background-color:#ffffff' title='#ffffff' onmouseover=\"Alice.color.pick('#ffffff','" + seq + "','" + Alice.color.seed + "')\"></div>" + "<div style='background-color:#ffffff' title='#ffffff' onmouseover=\"Alice.color.pick('#ffffff','" + seq + "','" + Alice.color.seed + "')\"></div>" + "<div style='background-color:#ffffff' title='#ffffff' onmouseover=\"Alice.color.pick('#ffffff','" + seq + "','" + Alice.color.seed + "')\"></div>"
				+ "</div><div style='clear:both;text-align:center;' id=w-picker-space-" + seq + "-" + this.seed + "></div>";
		return txt;
	},
	
	pick : function(c, s, n) {
		$1("w-picker-space-" + s + "-" + n).style.background = "#" + c;
		$1("w-picker-space-" + s + "-" + n).innerHTML = "<em><strong>#" + c + "</strong></em>";
		this.selectedColor = c;
	},
	
	viewPicker : function(id) {
		if ($1(id)) {
			this.hiddenAllPicker(id);
			$1(id).update(this.getPicker(id));
		}
	},
	
	togglePicker : function(id) {
		if ($1(id)) {
			if ($1(id).style.display == 'none') {
				$1(id).style.display = '';
				this.viewPicker(id);
			} else {
				this.hiddenPicker(id);
				$1(id).style.display = 'none';
			}
		}
	},
	
	hiddenPicker : function(id, nid) {
		if ($1(id)) {
			$1(id).update('');
			if (id != nid) {
				$1(id).style.display = 'none';
			}
		}
	},
	
	hiddenAllPicker : function(id) {
		var keys = this.hash.keys();
		for ( var i = 0; i < keys.length; i++) {
			this.hiddenPicker(keys[i], id);
		}
	},
	
	getPicker : function(id) {
		var p = null;
		if (this.hash[id]) {
			p = this.hash[id];
		} else {
			p = this.picker(id);
			this.hash[id] = p;
		}
		return p;
	}
};

Alice.char = {
	over : function(obj) {
		obj.className = "alc-bttns-char-o";
		$1("alc-char-preivew").value = obj.value;
	},
	
	out : function(obj) {
		obj.className = "alc-bttns-char";
	},
	
	apply : function(id, v) {
		var el = Web.EditorManager.get(id);
		el.paste('Char', v);
		el.popupHide();
	}
};

Alice.icon = {
	apply : function(id, v) {
		var el = Web.EditorManager.get(id);
		el.paste('Icon', '<img src="' + Alice.config.imageroot + '/alice/icon/' + v + '.gif" style=vertical-align:middle name=alc-icon>');
		el.popupHide();
	}
};

(function() {
	
	Object.extend(Web.util.Image, {
		alice : {
			'alc-crud-upload' : '<span title="업로드" class=alc-crud><img src=' + Alice.config.imageroot + 'alice/button/btn_upload.gif onmouseover=this.src="' + Alice.config.imageroot + 'alice/button/btn_upload_o.gif" onmouseout=this.src="' + Alice.config.imageroot + 'alice/button/btn_upload.gif"></span>',
			'alc-crud-apply' : '<span title="적용하기" class=alc-crud><img src=' + Alice.config.imageroot + 'alice/button/btn_apply.gif onmouseover=this.src="' + Alice.config.imageroot + 'alice/button/btn_apply_o.gif" onmouseout=this.src="' + Alice.config.imageroot + 'alice/button/btn_apply.gif"></span>',
			'alc-crud-cancel' : '<span title="취소" class=alc-crud><img src=' + Alice.config.imageroot + 'alice/button/btn_cancel.gif onmouseover=this.src="' + Alice.config.imageroot + 'alice/button/btn_cancel_o.gif" onmouseout=this.src="' + Alice.config.imageroot + 'alice/button/btn_cancel.gif"></span>',
			'alc-crud-select' : '<span title="선택하기" class=alc-crud><img src=' + Alice.config.imageroot + 'alice/button/btn_check.gif onmouseover=this.src="' + Alice.config.imageroot + 'alice/button/btn_check_o.gif" onmouseout=this.src="' + Alice.config.imageroot + 'alice/button/btn_check.gif"></span>',
			'alc-crud-loading' : '<span title="로딩중" class=alc-crud><img src=' + Alice.config.imageroot + 'alice/form/i_loading.gif></span>',
			'alc-etc-up' : '<span title="증가" class=alc-crud><img src=' + Alice.config.imageroot + 'alice/button/btn_up.gif onmouseover=this.src="' + Alice.config.imageroot + 'alice/button/btn_up_o.gif" onmouseout=this.src="' + Alice.config.imageroot + 'alice/button/btn_up.gif"></span>',
			'alc-etc-down' : '<span title="감소" class=alc-crud><img src=' + Alice.config.imageroot + 'alice/button/btn_down.gif onmouseover=this.src="' + Alice.config.imageroot + 'alice/button/btn_down_o.gif" onmouseout=this.src="' + Alice.config.imageroot + 'alice/button/btn_down.gif"></span>'
		}
	});
	
	Object.extend(Web.util.Select, {
		alice : {
			'alc-font-style' : '<div><button name=alc-select-{0} style="width:98px" onclick="Web.EditorManager.get(\'{1}\').popupFontStyle();return false;"><img src=' + Alice.config.imageroot + 'alice/form/sel_style.gif onmouseover=this.src="' + Alice.config.imageroot + 'alice/form/sel_style_o.gif" onmouseout=this.src="' + Alice.config.imageroot + 'alice/form/sel_style.gif" class=alc-img-b></button></div>' + '<div id=alc-font-style-box-{0} class=alc-font-box>'
					+ '<div class=alc-select-font-style onmouseover=this.className="alc-select-font-style-o" onmouseout=this.className="alc-select-font-style" onclick="Alice.font.setStylePlus(\'{1}\',\'STYLE01\')" style=color:red;font-size:14px;font-weight:bold>RED TITLE</div>'
					+ '<div class=alc-select-font-style onmouseover=this.className="alc-select-font-style-o" onmouseout=this.className="alc-select-font-style" onclick="Alice.font.setStylePlus(\'{1}\',\'STYLE02\')" style=color:blue;font-size:14px;font-weight:bold>BLUE TITLE</div>'
					+ '<div class=alc-select-font-style onmouseover=this.className="alc-select-font-style-o" onmouseout=this.className="alc-select-font-style" onclick="Alice.font.setStylePlus(\'{1}\',\'STYLE03\')" style=font-size:14px;font-weight:bold;font-style:underline>BLACK TITLE</div>'
					+ '<div class=alc-select-font-style onmouseover=this.className="alc-select-font-style-o" onmouseout=this.className="alc-select-font-style" onclick="Alice.font.setStylePlus(\'{1}\',\'STYLE04\')" style=height:25px;><span style="background-color:yellow">Marker Yellow</span></div>'
					+ '<div class=alc-select-font-style onmouseover=this.className="alc-select-font-style-o" onmouseout=this.className="alc-select-font-style" onclick="Alice.font.setStylePlus(\'{1}\',\'STYLE05\')" style=height:25px;><span style="background-color:lime">Marker Green</span></div>'
					+ '<div class=alc-select-font-style onmouseover=this.className="alc-select-font-style-o" onmouseout=this.className="alc-select-font-style" onclick="Alice.font.setStyle(\'{1}\',\'<P>\')">Normal&lt;P&gt;</div>' + '<div class=alc-select-font-style onmouseover=this.className="alc-select-font-style-o" onmouseout=this.className="alc-select-font-style" onclick="Alice.font.setStyle(\'{1}\',\'<DIV>\')">Normal&lt;DIV&gt;</div>'
					+ '<div class=alc-select-font-style onmouseover=this.className="alc-select-font-style-o" onmouseout=this.className="alc-select-font-style" onclick="Alice.font.setStyle(\'{1}\',\'<PRE>\')">Formated&lt;PRE&gt;</div>' + '<div class=alc-select-font-style onmouseover=this.className="alc-select-font-style-o" onmouseout=this.className="alc-select-font-style" onclick="Alice.font.setStyle(\'{1}\',\'<ADDRESS>\')"><address>Address</address></div>'
					+ '<div class=alc-select-font-style onmouseover=this.className="alc-select-font-style-o" onmouseout=this.className="alc-select-font-style" onclick="Alice.font.setStyle(\'{1}\',\'<DD>\')" style=height:20px>DD</div>'
					+ '<div class=alc-select-font-style onmouseover=this.className="alc-select-font-style-o" onmouseout=this.className="alc-select-font-style" onclick="Alice.font.setStyle(\'{1}\',\'<H6>\')" style=height:20px><h6 style=font-size:10px;font-weight:bold>Heading 6</h6></div>'
					+ '<div class=alc-select-font-style onmouseover=this.className="alc-select-font-style-o" onmouseout=this.className="alc-select-font-style" onclick="Alice.font.setStyle(\'{1}\',\'<H5>\')" style=height:20px><h5 style=font-size:12px;font-weight:bold>Heading 5</h5></div>'
					+ '<div class=alc-select-font-style onmouseover=this.className="alc-select-font-style-o" onmouseout=this.className="alc-select-font-style" onclick="Alice.font.setStyle(\'{1}\',\'<H4>\')" style=height:25px><h4 style=font-size:16px;font-weight:bold>Heading 4</h4></div>'
					+ '<div class=alc-select-font-style onmouseover=this.className="alc-select-font-style-o" onmouseout=this.className="alc-select-font-style" onclick="Alice.font.setStyle(\'{1}\',\'<H3>\')" style=height:30px;vertical-align:middle;><h3 style=font-size:18px;font-weight:bold>Heading 3</h3></div>'
					+ '<div class=alc-select-font-style onmouseover=this.className="alc-select-font-style-o" onmouseout=this.className="alc-select-font-style" onclick="Alice.font.setStyle(\'{1}\',\'<H2>\')" style=height:35px;vertical-align:middle;><h2 style=font-size:24px;font-weight:bold>Heading 2</h2></div>'
					+ '<div class=alc-select-font-style onmouseover=this.className="alc-select-font-style-o" onmouseout=this.className="alc-select-font-style" onclick="Alice.font.setStyle(\'{1}\',\'<H1>\')" style=height:40px;vertical-align:middle><h1 style=font-size:32px;font-weight:bold>Heading 1</h1></div>' + '</div>',
			'alc-font-family' : '<div><button name=alc-select-{0} style="width:98px" onclick="Web.EditorManager.get(\'{1}\').popupFontFamily();return false;"><img src=' + Alice.config.imageroot + 'alice/form/sel_font.gif onmouseover=this.src="' + Alice.config.imageroot + 'alice/form/sel_font_o.gif" onmouseout=this.src="' + Alice.config.imageroot + 'alice/form/sel_font.gif" class=alc-img-b></button></div>' + '<div id=alc-font-family-box-{0} class=alc-font-box>'
					+ '<div class=alc-select-font-style onmouseover=this.className="alc-select-font-style-o" onmouseout=this.className="alc-select-font-style" onclick="Alice.font.setFamily(\'{1}\',\'굴림\')" style="font-family:굴림">굴림</div>' + '<div class=alc-select-font-style onmouseover=this.className="alc-select-font-style-o" onmouseout=this.className="alc-select-font-style" onclick="Alice.font.setFamily(\'{1}\',\'궁서\')" style="font-family:궁서">궁서</div>'
					+ '<div class=alc-select-font-style onmouseover=this.className="alc-select-font-style-o" onmouseout=this.className="alc-select-font-style" onclick="Alice.font.setFamily(\'{1}\',\'돋움\')" style="font-family:돋움">돋움</div>' + '<div class=alc-select-font-style onmouseover=this.className="alc-select-font-style-o" onmouseout=this.className="alc-select-font-style" onclick="Alice.font.setFamily(\'{1}\',\'바탕\')" style="font-family:바탕">바탕</div>'
					+ '<div class=alc-select-font-style onmouseover=this.className="alc-select-font-style-o" onmouseout=this.className="alc-select-font-style" onclick="Alice.font.setFamily(\'{1}\',\'Arial\')" style="font-family:Arial">Arial</div>' + '<div class=alc-select-font-style onmouseover=this.className="alc-select-font-style-o" onmouseout=this.className="alc-select-font-style" onclick="Alice.font.setFamily(\'{1}\',\'Arial Black\')" style="font-family:Arial Black">Arial Black</div>'
					+ '<div class=alc-select-font-style onmouseover=this.className="alc-select-font-style-o" onmouseout=this.className="alc-select-font-style" onclick="Alice.font.setFamily(\'{1}\',\'Comic Sans MS\')" style="font-family:Comic Sans MS">Comic Sans MS</div>'
					+ '<div class=alc-select-font-style onmouseover=this.className="alc-select-font-style-o" onmouseout=this.className="alc-select-font-style" onclick="Alice.font.setFamily(\'{1}\',\'Courier New\')" style="font-family:Courier New">Courier New</div>' + '<div class=alc-select-font-style onmouseover=this.className="alc-select-font-style-o" onmouseout=this.className="alc-select-font-style" onclick="Alice.font.setFamily(\'{1}\',\'Impact\')" style="font-family:Impact">Impact</div>'
					+ '<div class=alc-select-font-style onmouseover=this.className="alc-select-font-style-o" onmouseout=this.className="alc-select-font-style" onclick="Alice.font.setFamily(\'{1}\',\'Tahoma\')" style="font-family:Tahoma">Tahoma</div>'
					+ '<div class=alc-select-font-style onmouseover=this.className="alc-select-font-style-o" onmouseout=this.className="alc-select-font-style" onclick="Alice.font.setFamily(\'{1}\',\'Times New Roman\')" style="font-family:Times New Roman">Times New Roman</div>'
					+ '<div class=alc-select-font-style onmouseover=this.className="alc-select-font-style-o" onmouseout=this.className="alc-select-font-style" onclick="Alice.font.setFamily(\'{1}\',\'Verdana\')" style="font-family:Verdana">Verdana</div>' + '<div class=alc-select-font-style onmouseover=this.className="alc-select-font-style-o" onmouseout=this.className="alc-select-font-style" onclick="Alice.font.setFamily(\'{1}\',\'Webdings\')" style="font-family:Webdings">Webdings</div>'
					+ '<div class=alc-select-font-style onmouseover=this.className="alc-select-font-style-o" onmouseout=this.className="alc-select-font-style" onclick="Alice.font.setFamily(\'{1}\',\'Wingdings\')" style="font-family:Wingdings">Wingdings</div>' + '</div>',
			'alc-font-size' : '<div><button name=alc-select-{0} style="width:98px" onclick="Web.EditorManager.get(\'{1}\').popupFontSize();return false;"><img src=' + Alice.config.imageroot + 'alice/form/sel_size.gif onmouseover=this.src="' + Alice.config.imageroot + 'alice/form/sel_size_o.gif" onmouseout=this.src="' + Alice.config.imageroot + 'alice/form/sel_size.gif" class=alc-img-b></button></div>' + '<div id=alc-font-size-box-{0} class=alc-font-box>'
					+ '<div class=alc-select-font-style onmouseover=this.className="alc-select-font-style-o" onmouseout=this.className="alc-select-font-style" onclick="Alice.font.setSize(\'{1}\',\'1\')" style=height:20px;font-size:10px;>Size 1</div>' + '<div class=alc-select-font-style onmouseover=this.className="alc-select-font-style-o" onmouseout=this.className="alc-select-font-style" onclick="Alice.font.setSize(\'{1}\',\'2\')" style=height:20px;font-size:12px;>Size 2</div>'
					+ '<div class=alc-select-font-style onmouseover=this.className="alc-select-font-style-o" onmouseout=this.className="alc-select-font-style" onclick="Alice.font.setSize(\'{1}\',\'3\')" style=height:20px;vertical-align:middle;font-size:14px;>Size 3</div>'
					+ '<div class=alc-select-font-style onmouseover=this.className="alc-select-font-style-o" onmouseout=this.className="alc-select-font-style" onclick="Alice.font.setSize(\'{1}\',\'4\')" style=height:25px;vertical-align:middle;font-size:16px;font-weight:bold>Size 4</div>'
					+ '<div class=alc-select-font-style onmouseover=this.className="alc-select-font-style-o" onmouseout=this.className="alc-select-font-style" onclick="Alice.font.setSize(\'{1}\',\'5\')" style=height:30px;vertical-align:middle;font-size:18px;font-weight:bold>Size 5</div>'
					+ '<div class=alc-select-font-style onmouseover=this.className="alc-select-font-style-o" onmouseout=this.className="alc-select-font-style" onclick="Alice.font.setSize(\'{1}\',\'6\')" style=height:35px;vertical-align:middle;font-size:24px;font-weight:bold>Size 6</div>'
					+ '<div class=alc-select-font-style onmouseover=this.className="alc-select-font-style-o" onmouseout=this.className="alc-select-font-style" onclick="Alice.font.setSize(\'{1}\',\'7\')" style=height:40px;vertical-align:middle;font-size:32px;font-weight:bold>Size 7</div>' + '</div>',
			'alc-font-bgcolor' : '<div onclick="Web.EditorManager.get(\'{1}\').popupBackgroundColor()"><button name=alc-bttns-{0} onclick="return false;"><img src=' + Alice.config.imageroot + 'alice/editor/bgcolor.gif></button></div>' + '<div id=alc-font-bgcolor-box-{0} class=alc-font-color-box onclick="Alice.color.apply(\'{1}\',\'BackColor\')">{2}</div>',
			'alc-font-forecolor' : '<div onclick="Web.EditorManager.get(\'{1}\').popupForegroundColor()"><button name=alc-bttns-{0} onclick="return false;"><img src=' + Alice.config.imageroot + 'alice/editor/color.gif></button></div>' + '<div id=alc-font-forecolor-box-{0} class=alc-font-color-box onclick="Alice.color.apply(\'{1}\',\'ForeColor\')">{2}</div>'
		}
	}); 
})();