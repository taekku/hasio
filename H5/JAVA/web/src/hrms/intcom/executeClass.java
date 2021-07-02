package hrms.intcom;

import h5.biz.command.common.MultiSaveCommand;
import h5.security.SeedCipher;
import h5.sys.command.CommandExecuteException;
import h5.sys.context.IRequestContext;
import h5.sys.context.ResponseContext;
import h5.sys.message.IListBaseMessage;
import h5.sys.message.IMessageItem;
import h5.sys.message.MessageMap;
import h5.sys.service.ServiceDef;
import h5.sys.service.ServiceFunctionItem;

import java.io.UnsupportedEncodingException;
import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Set;

import com.win.frame.invoker.GridResult;
import com.win.frame.invoker.Result;

public class executeClass extends MultiSaveCommand{
	// 업무단의 저장을 한다.
	protected ResponseContext execute(IRequestContext requestContext) throws CommandExecuteException{
		
		
		ResponseContext rCtx = null;
		// 등록된 서비스가 있는지 검사
		boolean serviceEmpty = true;
		
		/* 
		 * 
		 * 이후에 후처리를 한다.
		 * 
		 * 
		 */
		// requestContext로 부터 서비스 정의를 가져온다.
		ServiceDef serviceDef = requestContext.getServiceDef();
		
		// serviceDef의 기능 목록을 가져온다.
		Iterator<ServiceFunctionItem> fIterator = serviceDef.getFunctionIterator();
		
		List<String> serviceMsgs = new ArrayList<String>();
		
		while(fIterator != null && fIterator.hasNext()){
			serviceEmpty = false;
			ServiceFunctionItem functionItem = fIterator.next();
			serviceMsgs.add(functionItem.getRequestMessageName());
			serviceMsgs.add(functionItem.getResponseMessageName());
		}
		
		// 등록된 서비스가 있다면 전처리를 한다.
		if(!serviceEmpty){
			rCtx = super.execute(requestContext);
		// 등록된 서비스가 없으면 결과 메세지를 생성한다.
		}else{
			rCtx = requestContext.getResponseContext();
			rCtx.setResultType(ResponseContext.RESULT_TYPE_SUCCESS);
		}
				
		MessageMap msgMap = requestContext.getMessageMap();
		
		Set<String> keySet = msgMap.keySet();
		Iterator<String> keyIter = keySet.iterator();
		
		
		HashMap requestMap= new HashMap();
				
		while(keyIter.hasNext()){
			String intCallMsgName = keyIter.next();
			if(!serviceMsgs.contains(intCallMsgName)){
				System.out.println("intCallMsgName:" + intCallMsgName);
				
				IListBaseMessage baseMessage = (IListBaseMessage)requestContext.getMessage(intCallMsgName);
				Iterator<IMessageItem> itor = baseMessage.iterator();
				
				while(itor.hasNext()){
					IMessageItem lineItem = itor.next(); 
					
					Iterator<String> elementNameItor = lineItem.getElementNamesIterator();
					
					while(elementNameItor.hasNext()){
						
						String key = elementNameItor.next();
						String value = (String)lineItem.getElement(key);
						String[] values = {value};
						requestMap.put(key, values);
					}
				}				
			}
		}
		
		if(requestMap != null) {
			requestMap.put("gInfoVO", requestContext.getContextValue("gInfoVO"));
		}
		
		String modUserId = requestContext.getSessionValue("user_id");
		
		SeedCipher sc = new SeedCipher();
		String session_id = (String)requestContext.getSessionValue("id");
		try {
			modUserId = sc.decryptAsString(modUserId, session_id.getBytes(), "UTF-8");
		} catch (UnsupportedEncodingException e1) {
			e1.printStackTrace();
		}
		
		requestMap.put("mod_user_id", new String[]{modUserId});
		requestMap.put("mod_date", null);
		requestMap.put("request_context",requestContext);
		
		System.out.println("requestMap:" + requestMap.toString());
				
		try{
			String company_cd = requestContext.getSessionValue("company_cd");		
		    String class_name = ((String[])requestMap.get("class_name"))[0];
		    String method_name = ((String[])requestMap.get("method_name"))[0];

		    System.out.println("class_name >> " +class_name);
		    System.out.println("method_name >> " +method_name);
			ClassLoaderHrms loader = new ClassLoaderHrms(company_cd);
			Class aClass = loader.loadClass(class_name);
			
			Object obj = aClass.newInstance();
	
		      Object[] objectParameters = { requestMap };
		      System.out.println("objectParameters_________" + objectParameters);
		      Class[] classParameters = { HashMap.class };
		      System.out.println("classParameters________________" + classParameters);
		      Method theMethod = aClass.getDeclaredMethod(method_name, classParameters);
		      System.out.println("#############theMethod_________________" + theMethod);
		      Object ret = theMethod.invoke(obj, objectParameters);
		      if ((ret != null) && (((ret instanceof Result)) || ((ret instanceof GridResult))))
		      {
		    	  return rCtx;
		      }
		} catch(InvocationTargetException ite) {
			ite.printStackTrace();
			CommandExecuteException e2 = new CommandExecuteException(ite.getTargetException());
			e2.setErrCode(ite.getTargetException().getMessage());
			
			throw e2;
		} catch (Exception e){
			e.printStackTrace();
			String int_ec_list_id = ((String[])requestMap.get("int_ec_list_id"))[0];
			if(int_ec_list_id != null){
				System.out.println("int_ec_list_id>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"+int_ec_list_id);
			}
			//System.out.println("//////////////////" + e.getMessage() + "//////////////////");
			CommandExecuteException e2 = new CommandExecuteException(e);
			e2.setErrCode(e.getMessage());
			
			throw e2;
		}
		return rCtx;
	}
}
