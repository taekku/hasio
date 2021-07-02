package hrms.intcom;

import h5.ejb.session.facade.SessionFacade;
import h5.ejb.session.facade.SessionFacadeHome;
import h5.sys.command.AbsBusinessCommand;
import h5.sys.context.HttpBaseRequestContext;
import h5.sys.context.IRequestContext;
import h5.sys.context.ResponseContext;
import h5.sys.message.DefaultListBaseMessage;
import h5.sys.message.IListBaseMessage;
import h5.sys.message.IMessageItem;

import java.util.HashMap;
import java.util.Iterator;
import java.util.List;

import javax.naming.Context;
import javax.naming.InitialContext;


public class MgrCall {

	public void exeMgr(String serviceID, HashMap map) throws Exception{
		HashMap map1 = (HashMap)map.get("map");
		HashMap map2 = (HashMap)map1.get("map");
		
		HttpBaseRequestContext context = (HttpBaseRequestContext) map2.get("request_context");
		
		// 신규 컨텍스트를 생성한다.... 생성은 전달받은 컨텍스트의 내용을 그대로 이어받는다.
		HttpBaseRequestContext cloneContext = new HttpBaseRequestContext();
		cloneContext.setCallId(context.getCallId());
		cloneContext.setSessionId(context.getSessionId());
		cloneContext.setHttpRequest(context.getHttpRequest());
		cloneContext.setHttpResponse(context.getHttpResponse());
		cloneContext.setRequestHeader(context.getRequestHeader());
		cloneContext.setServiceDef(context.getServiceDef());
		cloneContext.setContextValue("gInfoVO", map2.get("gInfoVO"));
		
		Iterator it = context.getSessionKeyIterator();
		
		if(it != null) {
			while(it.hasNext()) {
				String sessionKey = (String)it.next();
				cloneContext.setSessionValue(sessionKey, context.getSessionValue(sessionKey));
			}
		}
		
		// 전달받은 컨텍스트내의 메시지를 신규 컨텍스트에 담으면서 sta, end 값 추가하기....
		DefaultListBaseMessage oriMsg = (DefaultListBaseMessage)context.getMessage("ME_INT0014_01");
		
		oriMsg.addColumn("sta");
		oriMsg.addColumn("end");
		
		DefaultListBaseMessage newMsg = new DefaultListBaseMessage();
		newMsg.setMessageId(oriMsg.getMessageId());
		newMsg.setMessageTypeId(oriMsg.getMessageTypeId());
		
		newMsg.setColumnIndexMap(oriMsg.getColumnIndexMap());
		newMsg.setColumnOrder(oriMsg.getColumnOrder());
		newMsg.setEncColumnOrder(oriMsg.getEncColumnOrder());
		
		it = oriMsg.iterator();
		
		List list = oriMsg.getColumnOrder();
		if(it.hasNext()) {
			IMessageItem item = (IMessageItem)it.next();
			IMessageItem newItem = newMsg.getNewMessageItem(true);
			
			Iterator it2 = list.iterator();
			
			if(it2 != null) {
				while(it2.hasNext()) {
					String colNm = (String)it2.next();
//					System.out.println("colNm >> " + colNm);
					newItem.setElementValue(colNm, item.getElement(colNm));
				}
			}
			
			newItem.setElementValue("sta", ((String[]) map2.get("sta"))[0]);
			newItem.setElementValue("end", ((String[]) map2.get("end"))[0]);
			newItem.setElementValue("method_name", ((String[]) map2.get("method_name"))[0]);
		}
		
		//System.out.println("######sta######" + ((String[]) map2.get("sta"))[0]);
		//System.out.println("######end######" + ((String[]) map2.get("end"))[0]);
		
		cloneContext.setMessage(newMsg);
		
		AbsBusinessCommand command = (AbsBusinessCommand)hrms.intcom.executeClass.class.newInstance();
		command.init(cloneContext);

		String jdbcName = "h5/ejb/session/facade/SessionFacadeHome";
		Context ctx = new InitialContext();
		SessionFacadeHome home = (SessionFacadeHome)ctx.lookup(jdbcName);
		SessionFacade local = home.create();
		ResponseContext responseContext = local.executeCommand(command);
		
	}
}
