/**
 * 몇 가지 일반적인 방법
 */
(function(exports) {
    
    /**
     * 문자열을 html 개체로 변환하고 기본적으로 채울 div를 만듭니다.
     * 매우 일반적으로 사용되기 때문에 별도로 추출
     * @param {String} strHtml 대상 문자열
     * @return {HTMLElement} 처리 된 html 객체를 반환하고, 문자열이 잘못된 경우 null을 반환합니다.
     */
    exports.parseHtml = function(strHtml) {
        if (typeof strHtml !== 'string') {
            return strHtml;
        }
        // 유연한 div 만들기
        var i,
            a = document.createElement('div');
        var b = document.createDocumentFragment();

        a.innerHTML = strHtml;

        while ((i = a.firstChild)) {
            b.appendChild(i);
        }

        return b;
    };

    /**
     * 개체를 템플릿으로 렌더링
     * @param {String} template 해당 대상
     * @param {Object} obj 표적
     * @return {String} 렌더링 된 템플릿
     */
    exports.renderTemplate = function(template, obj) {
        return template.replace(/[{]{2}([^}]+)[}]{2}/g, function($0, $1) {
            return obj[$1] || '';
        });
    };

    /**
     * 카운터 정의
     */
    var counterArr = [0];

    /**
     * 테스트 데이터 추가
     * @param {String} dom 
     * @param {Number} count 추가 할 금액
     * @param {Boolean} isReset 아래로 당겨 새로 고침 할 때 재설정해야합니까?
     * @param {Number} index 어느 새로 고침
     */
    exports.appendTestData = function(gubun, dom, count, isReset, index) {
    	
		if (typeof dom === 'string') {
			dom = document.querySelector(dom);
		}
		
		var template = "";  //실질적으로 그려지는 태그 String
    	if(gubun == "down"){ //새로고침
    		
    		//조회 callback
    		initSearch(function(actionType, obj) {
    			
    			searchList = obj["ME_CMU0010_04"];
    			if (searchList !== undefined && searchList !== null) {
    				
    				if(searchList.length > 0){
    					for( var i = 0 ; i < searchList.length ; i++){
    						var regDate = searchList[i].reg_date;
    							
    						strHtml += '<li id="li_'+i+'" class="list-item" onclick="doAction(\'R\',\''+i+'\',\''+searchList[i].reading_yn+'\',\''+searchList[i].item_id+'\');");">';
    						strHtml += '	<h3 class="msg-title">'+searchList[i].title+'</h3>';
    						strHtml += '	<sapn class="msg-fs14">[ '+searchList[i].org_nm+' ]</span>';
    						strHtml += '	<span class="msg-fs14 msg-date">작성자 : '+searchList[i].emp_nm+'&nbsp;&nbsp;'+regDate.substring(0,10)+'</span>';
    						strHtml += '</li>';
    					}
    					template = strHtml;
        	    		
        	    		//up과 down 모두 동일하게 타는 로직
        	            var prevTitle = typeof index !== 'undefined' ? ('Tab' + index) : '';
        	            var counterIndex = index || 0;
        	            
        	            counterArr[counterIndex] = counterArr[counterIndex] || 0;
        	            
        	            if (isReset) {
        	            	dom.innerHTML = '';
        	            	counterArr[counterIndex] = 0;
        	            }
        	            
        	            var html = '', dateStr = (new Date()).toLocaleString();
        	            for (var i = 0; i < count; i++) {
        	                html += exports.renderTemplate(template, {
        	                    t_index: counterArr[counterIndex]
        	                });
        	                
        	                counterArr[counterIndex]++;
        	            }
        	            var child = exports.parseHtml(html);

        	            dom.appendChild(child);
    				}
    			}
    			
    		});
    	}else if(gubun == "up"){ // 남은 내역 조회..
    		
    		var listLen = dom.children.length;
    		listLen = listLen + 1;
			var maxLen = $('#maxDataSize').val();
    		
    		//나머지 내역 재조회(SQL)
    		searchListRowBetween(listLen ,listLen+5 , function( actionType , obj){
				var searchList = obj["ME_CMU0010_04"];
				var strHtml = "";
				if(searchList.length > 0){
					for( var i = 0 ; i < searchList.length ; i++){
						var regDate = searchList[i].reg_date;
							
						strHtml += '<li id="li_'+(listLen+i)+'" class="list-item" onclick="doAction(\'R\',\''+(listLen+i)+'\',\''+searchList[i].reading_yn+'\',\''+searchList[i].item_id+'\');");">';
						strHtml += '	<h3 class="msg-title">'+searchList[i].title+'</h3>';
						strHtml += '	<sapn class="msg-fs14">[ '+searchList[i].org_nm+' ]</span>';
						strHtml += '	<span class="msg-fs14 msg-date">작성자 : '+searchList[i].emp_nm+'&nbsp;&nbsp;'+regDate.substring(0,10)+'</span>';
						strHtml += '</li>';
					}
					
					template = strHtml;
					
					//up과 down 모두 동일하게 타는 로직
			        var prevTitle = typeof index !== 'undefined' ? ('Tab' + index) : '';
			        var counterIndex = index || 0;
			        
			        counterArr[counterIndex] = counterArr[counterIndex] || 0;
			        
			        if (isReset) {
			        	dom.innerHTML = '';
			        	counterArr[counterIndex] = 0;
			        }
			        
			        var html = '', dateStr = (new Date()).toLocaleString();
			        for (var i = 0; i < count; i++) {
			            html += exports.renderTemplate(template, {
			                t_index: counterArr[counterIndex]
			            });
			            
			            counterArr[counterIndex]++;
			        }
			        var child = exports.parseHtml(html);

			        dom.appendChild(child);
					
				}
			});
    	}
    	
        
    };

    /**
     * 모니터링 이벤트 바인딩, 일시적으로 클릭
     * @param {String} dom 단일 돔 또는 선택기
     * @param {Function} callback 콜백
     * @param {String} eventName 이벤트 이름
     */
    exports.bindEvent = function(dom, callback, eventName) {
	        eventName = eventName || 'click';
	        if (typeof dom === 'string') {
	            dom = document.querySelectorAll(dom);
	        }
	        if (!dom) {
	            return;
	        }
	        if (dom.length > 0) {
	            for (var i = 0, len = dom.length; i < len; i++) {
	                dom[i].addEventListener(eventName, callback);
	            }
	        } else {
	            dom.addEventListener(eventName, callback);
	        }
	    };
	})(window.Common = {});








