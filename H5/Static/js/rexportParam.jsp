<%@ page contentType="text/html; charset=UTF-8"
        import="java.util.Iterator,
                    java.util.HashMap,
                    java.io.BufferedReader,
                    h5.sys.service.ServiceDef,
                    h5.sys.context.ResponseContext,
                    h5.sys.context.DelimiterSet,
                    h5.sys.message.IMessage,
                    h5.sys.message.IMessageItem,
                    h5.sys.registry.SystemRegistry,
                    h5.sys.registry.RegistryItem,
                    com.win.rf.util.AesCrypto,
                    h5.security.SeedCipher,
                    h5.sys.message.IListBaseMessage" %>
<%
	// 복호화
	SeedCipher sc = new SeedCipher();
	String session_id = (String)session.getAttribute("session_id");
	
	// parammeter setting
	String rtnString = "";

	BufferedReader reader = request.getReader();
	String rexParam = reader.readLine();
	
	rexParam = rexParam.replace("{","");
	rexParam = rexParam.replace("}","");
	rexParam = rexParam.replace("\"","");
	
	String[] strArr = rexParam.split(",");
	
	for(int i = 0; i< strArr.length; i++){
		if(i == 0){
			rtnString += "{";
		} else {
			rtnString += ", ";
		}
		
		String param = strArr[i];
		String[] paramSet = param.split(":");
		
		String key = paramSet[0];
		String value = paramSet[1];
		try{
			value = sc.decryptAsString(value, session_id.getBytes(), "UTF-8");  // 복호화 해서 문자로 받기
		}catch(ArrayIndexOutOfBoundsException aobe){
			value = paramSet[1]; // 복호화 실패한 경우, 원래 값 사용
		}
		
		
		rtnString += "\"" + key + "\":{\"value\":";
		rtnString += "\"" + value + "\"}";
		
		
	}
	if(strArr.length > 0){	
		rtnString += "}";
	}
	
	//System.out.println("rtnString /" + rtnString + "/");
	out.write(rtnString);
%>
