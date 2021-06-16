/*==========================================================================
결재자 : yul2
==========================================================================*/

var colorBox = new Array('#80E12A', '#0000FF', '#FEEB01', '#9932CC', '#FF8200', '#D0FF00', '#1B75BC', '#FBB040', '#FF00AE', '#E74F30', '#AAFA82', '#AFDFE5', '#FFF020', '#FFC0CB', '#f5089f');
var colorName = new Array('typeA', 'typeB', 'typeC', 'typeD', 'typeE', 'typeF', 'typeG', 'typeH', 'typeI', 'typeJ', 'typeK', 'typeL', 'typeM', 'typeN', 'typeO');	


var js_piechart = function (obj) {
    this.obj = obj;
    
    this.pieName = ['L1', 'L2', 'L3', 'L4', '계약', '특정']; // 분류명
    this.pieData = [50, 30, 20, 10, 36, 15]; // 분류값
    this.pieColor = ['#4572A7', '#AA4643', '#89A54E', '#71588F', '#4198AF', '#DC843C']; // 분류색상
    this.pieWidth = 150;    // 넓이
    
    this.pieX = 150;  // X 좌표
    this.pieY = 100;  // Y 좌표
    
    this.canvas;
    this.context;
    this.total;
    
    this.angle = 11;
    
    this.init();   
};    

js_piechart.prototype.dataChk = function() {
	var total = 0;
    for(var i=0 ; i < this.pieData.length ; i++ ){
        var value = this.pieData[i];
        total += value;
    }
    return total;
};
    
js_piechart.prototype.init = function() {
    this.canvas = document.getElementById(this.obj);
    this.context = this.canvas.getContext("2d");
};

js_piechart.prototype.clear = function() {
    this.canvas.width = this.canvas.width;
    this.angle += 2;
};

js_piechart.prototype.initClear = function() {
    this.canvas.width = this.canvas.width;
    this.angle = 11;
};

js_piechart.prototype.drawChart = function() {        

    // 총 합계 계산
    var value;
    this.total = 0;
    for(var i=0 ; i < this.pieData.length ; i++ ){
        value = this.pieData[i];
        this.total += value;
    }
    
    if(this.total > 0) {
    
    	$('#'+ this.obj).show();
    	
	    if(this.pieX == 0) {
	        this.pieX = this.pieWidth / 2;
	    }
	    if(this.pieY == 0) {
	        this.pieY = this.pieWidth / 2;
	    }
	    
	    var r,g,b;
	    var x = this.pieX;
	    var y = this.pieY;
	    var radius = 75;
	    var startAngle = this.angle;    // 값이 11 이어야 시계방향으로 12시 위치에서 시작한다.
	    var endAngle = 0;
	    var rate = 0;
	    var startAngles = [];
	    var endAngles = [];
	    var rates = [];
	                
	    for(i=0; i<this.pieData.length; i++){
	        // 비율 구하기   
	        rate = this.getRate(this.pieData[i], this.total);
	
	        // 각도
	        endAngle = this.getAngle(rate, startAngle);
	       
	        this.context.fillStyle = this.pieColor[i];
	                    
	        this.context.beginPath();
	        // 선 굻기
	        this.context.lineWidth = 1;  
	        this.context.moveTo( x, y );
	        this.context.arc( x, y, radius, startAngle, endAngle, false );
	        startAngles.push( startAngle );
	        rates.push( Math.round( rate ) );
	        startAngle = endAngle;
	        this.context.fill();
	
	                    
	        endAngles.push( endAngle );
	    }
	                
	    var textX;
	    var textY;
	    var textWidth;
	    
	    var preTextY = 0;
	    
	    for( i = 0 ; i < this.pieData.length ; i++ ){
	    	
	        startAngle = startAngles[i];
	        endAngle = endAngles[i];
	        textY = y + ( radius * ( Math.sin ( ( endAngle + startAngle) /2 ) ) ) / 1;
	        textX = x + ( radius * ( Math.cos( ( endAngle + startAngle) /2 ) ) ) / 1;
	        
	       
	        // 폰트 색상 설정
	        this.context.fillStyle = "#777777";
	        
	        // 지정된 위치에 폰트 출력
	        textWidth = this.context.measureText( this.pieName[i] ).width;
	        this.context.font = "normal 11px Tahoma";
	        
	        if(this.pieData[i]  > 0)
	    	{
		        if(textX  < 150) {
			        this.context.fillText( 
			            this.pieName[i]
			            , textX - textWidth
			            , textY 
			        );  
		        } else {
		        	this.context.fillText( 
			            this.pieName[i]
			            , textX
			            , textY 
			        );
		        }
	    	}
	    	
	    }
    } else {
    	$('#'+ this.obj).hide();
    }
    
};
            
js_piechart.prototype.getRate = function(value, totalValue) {             
    return value / totalValue * 100;
};
            
js_piechart.prototype.getAngle = function(rate, startAngle){
    return ( 2 * Math.PI * ( rate/100 ) )+startAngle;
};
            
js_piechart.prototype.getRandom = function(min, max){
    return Math.ceil( Math.random() * ( max - min ) ) + min;
};


       