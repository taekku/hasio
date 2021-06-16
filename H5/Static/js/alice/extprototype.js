
Object.extend(String.prototype, {
  /***************************************/
  /* trim function                       */
  /***************************************/
  trim: function() {
    return this.replace(/(^[ \f\n\r\t]*)|([ \f\n\r\t]*$)/g, "");
  },
  
  /***************************************/
  /* notEmpty() added                    */
  /***************************************/
  notEmpty: function() {
    return this != '';
  },
  
  /***************************************/
  /* getByte() added                     */
  /***************************************/
  getByte: function() {
  	var result = 0;
	for (var i = 0; i < this.length; i++) {
		(this.charCodeAt(i) > 255) ? result += 2 : result += 1;
	}
	return result;
  },

  /***************************************/
  /* present() added                     */
  /***************************************/
  present: function() {
  	return this != null;
  },
  
  /***************************************/
  /* pattern() added                     */
  /***************************************/
  pattern: function(pattern) {
  	return this.search(pattern) > -1;
  },

  /***************************************/
  /* filsizeFormat() added               */
  /*    argument : sosu length           */
  /***************************************/
  filesizeFormat: function(solen) {
    var isValidate = true;
    var value = this;
    for (var i = 0; i < value.length; i++) {
      if ("0123456789".indexOf(value.substring(i, i + 1)) < 0) {
      	isValidate = false;
      	break;
      }
    }
    
    var unit = '';
    var calsize = '';
    var size = '';
    if (isValidate) {      
      if ((1024 < value) && (value < 1024 * 1024)) {
        unit = 'KB';
        calsize = value/1024;
      } else if (1024 * 1024 <= value) {
        unit = 'MB';
        calsize = value/(1024*1024);
      } else {
        unit = 'Bytes';
        calsize = value;
      }
      size = calsize.toString();
      if (size.indexOf('.') > -1) {
        var sosu = size.substring(size.indexOf('.') + 1, size.length);        
        if (!solen) {
          solen = 2;
        }        
        if (sosu.length > solen) {
          size = size.substring(0, size.indexOf('.')) + '.' + sosu.substring(0, solen);
        }
      }
	}
	return size+' '+unit;
  },

  /***************************************/
  /* moneyFormat() added                 */
  /***************************************/
  moneyFormat: function() {
	var string = this;
	var factor = string.length % 3;
    var value = string.substring(0, factor);
    for (var i = 0; i < (string.length - factor) / 3; i++) {
      if ((factor == 0) && (i == 0)) {
        value += string.substring(factor+(3*i), factor+3+(3*i));
      }
      else {
        if (string.substring(factor + (3 * i) - 1, factor+( 3 * i)) != '-') {
        	value +=',';
        }
        value += string.substring(factor + (3 * i), factor + 3 + (3 * i));
      }
    }
	return value;
  },

  /***************************************/
  /* viewer() added                      */
  /***************************************/
  viewer: function() {
    var img_view = this;
    Web.ImageViewerManager.view({title: '�̹��� ���', src:img_view});
    
    /*
    var x = x + 20 ;
    var y = y + 30 ;
    imagez = window.open('', "image", "width="+ 100 +", height="+ 100 +", top=0,left=0,scrollbars=auto,resizable=1,toolbar=0,menubar=0,location=0,directories=0,status=1");
    imagez.document.open();
    imagez.document.write("<html><head><title>view image</title><style>body{margin:0;cursor:pointer;}</style></head><body scroll=auto onload='width1=document.getElementById(\"chimera_popup_image\").width;if(width1>1024)width1=1024;height1=document.getElementById(\"chimera_popup_image\").height;if(height1>768)height1=768;top.window.resizeTo(width1+30,height1+54);' onclick='top.window.close();'><img src='"+img_view+"' title='' name='chimera_popup_image' id='chimera_popup_image'></body></html>");
    imagez.document.close();
    */
  },
  
  /* ������ */
  popupView: function() {
  	this.viewer();
  }
});


/***************************************/
/* simplified function                 */
/***************************************/
function $n(element) {
	if (arguments.length > 1) {
		for (var i = 0, elements = [], length = arguments.length; i < length; i++) {
			elements.push($n(arguments[i]));
		}
		return elements;
	}
	if (typeof element == 'string') {
		element = document.getElementsByName(element);		
	}
	return Element.extend(element);
}

function $fn(formname, name) {
	var tgt = null;
	if (document.forms) {
		for (var i = 0; i < document.forms.length; i++) {
			var f = document.forms[i];			
			if (f.name == formname) {
				for (var k = 0; k < f.elements.length; k++) {
					var e = f.elements[k];
					if (e.name == name) {
						tgt = e;
					}	
				}
			}	
		}
	}
	
	return tgt;
}


function $n1(names) {
	var nm = $n(names);
	if (nm && nm.length == 1) {
		return nm[0];
	}
	else {
		return null;
	}
}

function $rd(names) {
	var val = null;
	var arr = $n(names);
	for (var i = 0; i < arr.length; i++) {
		if (arr[i].checked) {
			val = arr[i].value;
			break;
		}
	}
	return val;
}