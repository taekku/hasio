package h5.servlet.util;

import h5.ejb.session.facade.SessionFacade;
import h5.ejb.session.facade.SessionFacadeHome;
import h5.sys.command.AbsBusinessCommand;
import h5.sys.context.HttpBaseRequestContext;
import h5.sys.context.IRequestContext;
import h5.sys.context.RequestHeader;
import h5.sys.context.ResponseContext;
import h5.sys.message.DefaultListBaseMessage;
import h5.sys.message.IListBaseMessage;
import h5.sys.message.IMessageItem;
import h5.sys.service.ServiceDef;
import h5.sys.service.ServiceDefLoader;
import h5.sys.util.Logger;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.Enumeration;
import java.util.HashMap;
import java.util.Iterator;
import java.util.Set;

import javax.naming.Context;
import javax.naming.InitialContext;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpSession;
import javax.sql.DataSource;

import com.win.frame.server.ServerConfig;
import com.win.frame.server.ServerConfigFactory;
import com.win.rf.config.ConfigurationManager;
import com.win.rf.config.IConfigurationInfoProvider;

/**
 * html 폼 기반의 전송으로부터 IRequestContext를 만들어 반환하는 일을 수행한다.
 * @author tykim
 *
 */
public class JspFormContextBuilder {

	HttpServletRequest request;
	HttpSession session;
	
	/**
	 * 생성자, 웹 요청과 세션 값으로부터 빌더를 초기화한다.
	 * @param request
	 * @param session
	 */
	public JspFormContextBuilder(HttpServletRequest request, HttpSession session){
		this.request = request;
		this.session = session;
		
	}
	
	/**
	 * 요청 컨텍스트를 만들어 반환한다.
	 * @return
	 */
	public IRequestContext getRequestContext(String msgName){
System.err.println("HtmlFormContextBuilder.java 68 line msgName==>"+msgName);
		HashMap <String,IListBaseMessage> messageMap = new HashMap<String,IListBaseMessage>();

		// 1. request 객체로부터 파라미터 이름을 받는다.
		//    파라미터 이름은 '.' 로 구분되어 좌측은 메시지 명, 우측은 메시지의 컬럼 명으로 분류된다.
		Enumeration <String>names = request.getParameterNames();
		while(names.hasMoreElements() ){                 // 서브밋 된 모든 파라미터의 이름 수 만큼 반복한다.

			String name = names.nextElement();
			if(!messageMap.containsKey(msgName)){      // 기존에 이 이름을 가지고 만들어진 메시지가 이미 등록되었는지 찾아본다.
				IListBaseMessage newMessage = new DefaultListBaseMessage(); // 없으면, 하나 만들고 
				messageMap.put(msgName, newMessage);                    // 새로 등록한다.
			}
			
			IListBaseMessage selectedMessage = messageMap.get(msgName); // 주어진 이름으로 이미 등록된 메시지를 하나 얻어낸다.
			if(selectedMessage == null){                                     // 얻어 낸 메시지가 널이라면 (이럴리는 없을 듯 하나)
				continue;                                                      // 아무것도 하지 않는다.
			}

			// 3. 얻어진 이름으로다가 메시지의 컬럼을 구성한다.
			//     selectedMessage에 addColumn을 수행한다.
			if(!selectedMessage.contains(name))      // 메시지에 컬럼 이름이 존재하지 않는다면
				selectedMessage.addColumn(name);       // 메시지에 앞에서 얻어낸 컬럼이름을 집어 넣는다.
			
		} // 이 반복이 종료되면, 모든 필요한 메시지와 각 메시지 컬럼의 구성이 완료 된 것이다.

		// 4. 메시지에 컬럼의 '값'을 입력한다.
		//    반복의 횟수는 메시지의 이름을 포함하고 있는 sStatus 파라미터의 길이가 기준이 된다.
		Set <String>nameSet = messageMap.keySet();               // 앞선 메시지 맵에서 key 만 골라낸다. 이게 메시지 이름이니깐..
		
		Iterator <String>messageNameItor = nameSet.iterator();
		
		while(messageNameItor.hasNext()){
			String messageName = messageNameItor.next(); // 요게 메시지 이름임.
			IListBaseMessage message = messageMap.get(messageName); // 요건 메시지임
			
			// 지금부터 메시지 이름과 컬럼 이름을 이용하여 값을 채워 넣는다.
			// 반복의 기준은 sStatus라는 파라미터의 값의 길이가 될 것임.
			String[] sStatusValues = request.getParameterValues("sStatus");
			
			for(int i=0; sStatusValues != null && i< sStatusValues.length ;i++){
				IMessageItem item = message.getNewMessageItem(true);  // 메시지 하나를 새로 생성하여 받는다.
				snapMessageItemFromRequest(item,messageName,i);       // 아이템의 값을 request로 부터 채워 넣는다.
				
			}
			
		}
		
		
		// 5. IRequestContext 객체를 하나 만든다.
		// 생성된 모든 메시지를 추가하고, 세션 오브젝트 및 세션 ID를 추가한다.
		IRequestContext context = null;
		context = new HttpBaseRequestContext();
		
		nameSet = messageMap.keySet();
		messageNameItor = nameSet.iterator();
		
		while(messageNameItor.hasNext()){
			String messageName = messageNameItor.next();
			IListBaseMessage message = messageMap.get(messageName);
			context.setMessage(messageName, message);
// Logger.log(messageName+"을 메시지로 넣습니다.");
		}
		
		RequestHeader requestHeader = new RequestHeader();
		
		// * 주의 할 점 *
		// 웹 폼 기반의 Request에서는 다음의 항목을 반드시 넘겨주어야 한다.
		// 
		// _call_id : 매 호출 마다의 유니크한 아이디.
		// _service_id : 어떤 서비스를 호출 할 것인지에 대한 서비스 ID
		// _company_cd : 인사영역 코드
		// _session_id : 세션 아이디, 워크벤치 초기화시에 이미 할당 된 값이다.

		// 서비스 처리를 위한 공통 항목들을 집어 넣는다.
		requestHeader.setCallId(request.getParameter("_call_id"));
		requestHeader.setCompanyCd(request.getParameter("_company_cd"));
		requestHeader.setServiceId(request.getParameter("_service_id"));
		String sessionId = request.getParameter("_session_id");
		requestHeader.setSessionId(sessionId);
		
		context.setRequestHeader(requestHeader);
		
		// 6. 호출된 서비스ID에 대한 서비스 정의를 구성한다.
		ServiceDef serviceDef = ServiceDefLoader.loadService(context.getRequestHeader().getCompanyCd(), context.getRequestHeader().getServiceId());
		context.setServiceDef(serviceDef);

		// 7. 세션 값을 읽어 와서, 세션 변수로 추가한다.
		//    이 과정은 직접 SQL을 실행하여 이루어진다.
		IConfigurationInfoProvider provider = ConfigurationManager.getConfigurationInfoProvider();
		ServerConfig config = ServerConfigFactory.getServerConfig();
		String jdbcJndiPrefix = config.getConfigValue("jdbcJndiPrefix");
		
		String jndiName = jdbcJndiPrefix+provider.getItem("h5prd.jdbc.jndi").getValue();
		
		
		// 쿼리를 사용하는 데 사용할 커넥션 및 기타등등..
		Connection con = null;
		PreparedStatement stmt = null;
		ResultSet rset = null;
		
		try{
			
			Context ctx = new InitialContext();
			DataSource ds = (DataSource)ctx.lookup(jndiName);
			con = ds.getConnection();
			stmt = con.prepareStatement("SELECT * FROM FRM_USER_SESSION_ATTRIBUTE WHERE SESSION_ID = ?");
// Logger.log("SELECT * FROM FRM_USER_SESSION_ATTRIBUTE WHERE SESSION_ID = '"+sessionId+"'");					
			stmt.setString(1,sessionId);
			rset = stmt.executeQuery();
			
			while(rset.next()){
				String key = rset.getString("session_attribute");
				String value = rset.getString("session_value");
				session.setAttribute(key, value);
				context.setSessionValue(key, value);
			}
			
		}catch(Exception e){
			e.printStackTrace();
		}finally{
			try{
				if(rset != null){
					rset.close();
					rset = null;
				}
				if(stmt != null){
					stmt.close();
					stmt = null;
				}
				if(con != null){
					con.close();
					con = null;
				}
			}catch(Exception e){
				e.printStackTrace();
			}
		}
		return context;
	}
	
	/**
	 * requeset로 부터 생성된 requestContext를 이용하여,
	 * serviceDef에 정의된 대로 서비스를 호출한다.
	 * 
	 * 서비스 호출의 트랜잭션 처리 규칙은 service 정의기에 정의한 대로 이뤄진다.
	 * 즉, 이 시점에서, session facade를 이용한 처리와, 일반 처리를 분기하여 처리한다.
	 * 
	 * @param requestContext 요청 컨텍스트
	 * @return
	 * @throws Exception
	 */
	public ResponseContext runService(IRequestContext context)throws Exception{
		
		// 커맨드를 찾아 호출한다.
		//System.out.println("context.getRequestHeader().getCompanyCd() : "+context.getRequestHeader().getCompanyCd());
		ServiceDef serviceDef = ServiceDefLoader.loadService(context.getRequestHeader().getCompanyCd(), context.getRequestHeader().getServiceId());
		String commandClassName = serviceDef.getCmdClassNm();
		
		Class commandClass = Class.forName(commandClassName);
		Object commandInstance = commandClass.newInstance();
		
		// 반환할 결과를 담는 결과 컨텍스트 
		ResponseContext responseContext = null;
		
		if(commandInstance != null){
			// 작업을 실행할 커맨드 클래스...
			AbsBusinessCommand command = null;
			command = (AbsBusinessCommand)commandInstance;
			//TODO 여기서 메시지를 바인딩 해 가꼬, 넘겨 온 이름하고, 실제 메시지의 이름하고를 바인딩 해야 한다. 
			
			command.init(context);
			
			// 롤백을 해야 하는 경우는 세션빈을 호출해서 실행하고,
			if(serviceDef.isTxSupportYn()){
				//String jdbcName = "java:comp/env/h5/SessionFacade";
				String jdbcName = "java:comp/env/ejb/h5/session/facade/SessionFacadeHome";
				Context ctx = new InitialContext();
		        SessionFacadeHome home = (SessionFacadeHome)ctx.lookup(jdbcName);
		        SessionFacade local = home.create();
		        responseContext = local.executeCommand(command);
		        
			}else{ // 아니면, 그냥 실행한다.
				responseContext = command.run();
				
			}

		}

		return responseContext;
	}
	
	protected void snapMessageItemFromRequest(IMessageItem item, String messageName, int index){
		
		Iterator <String> messageColumnNameItor = item.getElementNamesIterator();
		while(messageColumnNameItor != null && messageColumnNameItor.hasNext()){
			String columnName = messageColumnNameItor.next();
			try{
// Logger.log(messageName+"에 컬럼 "+columnName+" 의 값을 "+request.getParameterValues(columnName)[index]+" 로 세팅합니다.");
System.err.println(messageName+"에 컬럼 "+columnName+" 의 값을 "+request.getParameterValues(columnName)[index]+" 로 세팅합니다.");
				item.setElementValue(columnName, request.getParameterValues(columnName)[index]);
			}catch(Exception e){
				e.printStackTrace();
				continue; // 오류가 나도 계속 수행한다.
			}
		}
	}
}
