package h5.servlet;

import com.win.frame.server.ServerConfig;
import com.win.frame.server.ServerConfigFactory;
import com.win.rf.config.ConfigurationManager;
import com.win.rf.config.IConfigurationInfoProvider;
import com.win.rf.message.MessageSender;
import h5.biz.core.validator.Effectiveness;
import h5.ejb.session.facade.SessionFacade;
import h5.ejb.session.facade.SessionFacadeHome;
import h5.security.SeedCipher;
import h5.sys.command.AbsBusinessCommand;
import h5.sys.command.CommandExecuteException;
import h5.sys.context.IRequestContext;
import h5.sys.context.ResponseContext;
import h5.sys.context.TextBaseRequestContextBuilder;
import h5.sys.message.ServiceExecutionMessage;
import h5.sys.service.ServiceDef;
import h5.sys.service.ServiceDefItem;
import h5.sys.service.ServiceDefLoader;
import h5.sys.service.ServiceMessage;
import h5.sys.util.LanguageUtil;
import h5.sys.util.Logger;

import javax.naming.Context;
import javax.naming.InitialContext;
import javax.servlet.RequestDispatcher;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import javax.sql.DataSource;
import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.Enumeration;

/**
 * 
 * H5 의 웹 응용 프로그램(클라이언트)로 부터 하위 서비스를 호출하는 서블릿 클래스
 * 요청 메시지는 반드시 MessageSet의 형태로 전달(디시리얼라이즈)되어야 하며, 그 결과는 MessageSet의 형태로
 * 시리얼라이즈 된다.
 * 
 * MessageSet의 각 메시지는 (각 회사별)메시지정의에 대한 ID를 포함하고 있어야 한다.
 * doPost의 과정에서, ServiceRequestServle은 메시지 ID를 이용하여 메시지 시리얼라이즈 - 디 시리얼라이즈를 수행한다.
 * 
 * @author tykim
 *
 */  
public class ServiceRequestServlet extends HttpServlet {   

	// 클라이언트 프로그램에서 전달하는 데이터가 들어갈 필드 이름
	static final String PARAM_REQUEST_MSG = "request_message";
	// request 객체에 저장할 request context의 참조 키 값.
	static final String NAME_RESPONSE_CONTEXT = "RESPONSE_CONTEXT";
	// 서블릿 초기화 파라미터 중, 성공시 forward 할 url 값을 가져올 키 값.
	static final String INIT_PARAM_SUCCESS_URL = "success_url";
	// 서블릿 초기화 파라미터 중, 실패시 forward 할 url 값을 가져올 키 값.
	static final String INIT_PARAM_ERROR_URL = "error_url";
	// 에러 코드.
	static final String ERROR_CODE = "FRM.ERRORMSG_0000";

	static final String SUCCESS_MSG_KEY = "SUCCESS_MSG";
	static final String ERROR_MSG_KEY = "ERROR_MSG";

	protected void doPost(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {
		// 1. H5 5.0의 서비스 구동 설정 정보를 이용하여, 디시리얼라이즈 과정에서 인코딩을 쓸 것인지 등의 여부를 판단한다.
		IConfigurationInfoProvider provider = ConfigurationManager.getConfigurationInfoProvider();
		ServerConfig config = ServerConfigFactory.getServerConfig();
		String jdbcJndiPrefix = config.getConfigValue("jdbcJndiPrefix");
		// RequestContext를 선언한다. 여기서는 HttpBaseRequestContext를 이용한다.
		// 즉 request로 넘어 온 객체 중 PARAM_MSG_MAP에 대한 값을 이용하여 텍스트-오브젝트화 과정을 수행할 때,
		// Http 프로토콜을 이용하여 전달 된 값은 HttpBaseRequestContext로 시리얼라이즈 한다. 
		IRequestContext context = null;
		context = (IRequestContext)request.getAttribute("REQUEST_CONTEXT");

		// 반환할 결과를 담는 결과 컨텍스트
		ResponseContext responseContext = null;
		String security_errcd = (String)request.getAttribute("security_errcd");
		boolean securityErrorFlag = true;
		if(security_errcd != null && "SEC-001".equals(security_errcd)) {
			String security_errmsg = (String)request.getAttribute("security_errmsg");
			
			if( security_errmsg == null || "".equals(security_errmsg) ) {
				security_errmsg = "SECURITY_ERRMSG";
			}
			
			securityErrorFlag = false;
			request.setAttribute("REQUEST_CONTEXT", context);
			responseContext = context.getResponseContext();
			
			if( "DUPLICATE_LOGIN_ERR".equals(security_errmsg) ) {
				responseContext.setResultType("DUPLICATE_LOGIN_ERROR");
			} else {
				responseContext.setResultType("SECURITY_ERROR");
			}
			responseContext.setResultCode(ERROR_MSG_KEY);
			responseContext.setResultMessage(LanguageUtil.getLocaleValue(security_errmsg, context.getRequestHeader().getLangCd()));
			request.setAttribute(NAME_RESPONSE_CONTEXT, responseContext);
			String redirectURL = getInitParameter(INIT_PARAM_SUCCESS_URL);
			RequestDispatcher dispatcher = request.getRequestDispatcher(redirectURL);
			dispatcher.forward(request, response);
		}
		
		// 쿼리를 사용하는 데 사용할 커넥션 및 기타등등..
		Connection con = null;
		PreparedStatement stmt = null;
		ResultSet rset = null;

		String successCode = "";
		String errorCode = "";

		boolean hasSession = true;

		// 효정추가 세션 및 권한체크
		HttpSession sessionAuth = request.getSession(false);
		String emp_id = null;
		String session_id = null;
		String login_date = null;
		try
		{

			// 세션에 값이 없으면, DB로 부터 읽어서 채우고, 다시 세션 값으로 할당한다.
			String jndiName = jdbcJndiPrefix + provider.getItem("h5prd.jdbc.jndi").getValue();

			Context ctx = new InitialContext();
			DataSource ds = (DataSource)ctx.lookup(jndiName);
			con = ds.getConnection();

			boolean ignoreSession = false;
			// 시작하자마자 세션을 체크한다!
			if (sessionAuth != null) {
				emp_id = (String)sessionAuth.getAttribute("session_emp_id");
				session_id = (String)sessionAuth.getAttribute("session_id");
				login_date = (String)sessionAuth.getAttribute("session_login_date");
				if (((String)sessionAuth.getAttribute("ignore_session") != null) && ("Y".equalsIgnoreCase((String)sessionAuth.getAttribute("ignore_session")))) {
					ignoreSession = true;
				}

			}
			
			if (!ignoreSession){ // 세션 체크 부분 시작
				if ((emp_id == null) || ("".equals(emp_id))) {
					CommandExecuteException com = new CommandExecuteException();
					com.setErrCode("SYSERROR_001");
					com.setSessionFlag("Y");
					throw com;
				} else {
					SeedCipher sc = new SeedCipher();
					emp_id = sc.decryptAsString(emp_id, session_id.getBytes(), "UTF-8");
					String passYn = null;
					// 세션id를 수정했음 아니 아니 아니되오!
					// 세션id로 로그인시간을 체크해보자!
					StringBuffer sb = new StringBuffer();
					sb.append(" select case when count(*) = 2 then 'Y' else 'N' end loginYn ");
					sb.append("  from FRM_WORK_SESSION a  ");
					sb.append("   , FRM_USER_SESSION_ATTRIBUTE b  ");
					sb.append("   where a.session_id = b.session_id and a.user_id = b.user_id and a.session_id = ? ");
					sb.append("   and ((b.session_attribute = 'session_emp_id' and b.session_value = ? )  ");
					sb.append("   or (b.session_attribute = 'session_login_date' and b.session_value = ?))  ");

					stmt = con.prepareStatement(sb.toString());

					stmt.setString(1, session_id);
					stmt.setString(2, emp_id);
					stmt.setString(3, login_date);
					rset = stmt.executeQuery();

					if (rset.next()) {
						passYn = rset.getString(1);
					}

					if ("N".equals(passYn)){
						// 세션값이 다르다!! 다른짓 하지마삼!!
						CommandExecuteException com = new CommandExecuteException();
						com.setErrCode("SYSERROR_002");
						com.setSessionFlag("Y");
						throw com;
					}

					if (rset != null) {
						rset.close();
						rset = null;
					}
					if (stmt != null) {
						stmt.close();
						stmt = null;
					}
				}
				
				// 세션 값이 할당되어 있다면 그 세션 값을 사용하도록 한다.
				String sessionId = context.getRequestHeader().getSessionId();
				
				// 세션 아이디가 널이 아니라면 컨텍스트에 그 값을 넣어서 전달한다.
				if (sessionId != null) {
					HttpSession session = request.getSession();

					session.getAttribute("session_id");

					if (session.getAttribute("session_id") == null) {
						hasSession = false;
					}
					stmt = con.prepareStatement("SELECT * FROM FRM_USER_SESSION_ATTRIBUTE WHERE SESSION_ID = ?");
					stmt.setString(1, sessionId);
					rset = stmt.executeQuery();

					while (rset.next()) {
						String key = rset.getString("session_attribute");
						String value = rset.getString("session_value");
						SeedCipher sc = new SeedCipher();
						if ((key.indexOf("emp_id") > -1) || (key.indexOf("user_id") > -1)) {
							value = sc.encryptAsString(value, sessionId.getBytes(), "UTF-8");
						}
						
						// 2018.08.01 (JSM) 테마 적용
						if ( "session_theme".equals(key) ){
							String theme = (String) session.getAttribute("session_theme");
							context.setSessionValue(key, theme);
						} else if( "session_layout_type".equals(key) ) {
							String layoutType = (String) session.getAttribute("session_layout_type");
							context.setSessionValue(key, layoutType);
						} else if ( "session_company_cd".equals(key) ) {
							//2020.10.15 상진 : 계열사 코드 변경시 context에도 변경 된 company_cd값 반영 시켜 주기.
							String session_company_cd = (String) session.getAttribute("session_company_cd");
							context.setSessionValue(key, session_company_cd);
						} else if ( "session_company_nm".equals(key) ) {
							String session_company_nm = (String) session.getAttribute("session_company_nm");
							context.setSessionValue(key, session_company_nm);
						} else {
							session.setAttribute(key, value);
							context.setSessionValue(key, value);
						}
					}
					String session_manager_yn = (String)session.getAttribute("session_manager_yn");
					String session_manager_mode_yn = (String)session.getAttribute("session_manager_mode_yn");
					context.setSessionValue("session_manager_yn", session_manager_yn);
					context.setSessionValue("session_manager_mode_yn", session_manager_mode_yn);

					if (rset != null) {
						rset.close();
						rset = null;
					}
					if (stmt != null) {
						stmt.close();
						stmt = null;
					}

				}

				// 세션을 체크하여 세션이 없으면 에러를 발생시킨다.
				if (!hasSession) {
					CommandExecuteException com = new CommandExecuteException();
					com.setErrCode("SYSERROR_003");
					com.setSessionFlag("Y");
					throw com;
				}

				// ServiceRequestServlet.PARAM_REQUEST_MSG 의 이름으로 넘어오지 않은 파라미터들을
				// context의 contextValue로 할당한다.
				Enumeration<String> paramNameEnum = request.getParameterNames();

				while ((paramNameEnum != null) && (paramNameEnum.hasMoreElements())) {
					String paramName = (String)paramNameEnum.nextElement();
					String[] parameterValues = request.getParameterValues(paramName);
					if (context != null) {
						Logger.log("paramName setting ... " + paramName + ", value:" + parameterValues[0]);
						context.setContextValue(paramName, parameterValues);
					}
				}
			} else { // sesison check 부분 끝
				HttpSession session = request.getSession();
				Enumeration  enum1 = session.getAttributeNames();
				
				while( enum1.hasMoreElements()){
					String keyName = ( String)enum1.nextElement();
					String value1 = (String) session.getAttribute(keyName);
					context.setSessionValue(keyName, value1);
				}
			}
			
			ServiceDef serviceDef = ServiceDefLoader.loadService(context.getRequestHeader().getCompanyCd(), context.getRequestHeader().getServiceId());

			// 성공과 실패 메시지를 가져온다.
			successCode = serviceDef.getSvAttrValue(SUCCESS_MSG_KEY);
			errorCode = serviceDef.getSvAttrValue(ERROR_MSG_KEY);

			// 커맨드를 찾아 호출한다.
			ServiceDefItem item = serviceDef.getServiceDefItem();
			if (item != null) {
				Boolean isAsync = Boolean.valueOf(item.isAsyncYn());
				if ((isAsync != null) && ("true".equalsIgnoreCase(isAsync.toString()))) {
					ServiceExecutionMessage messageData = new ServiceMessage();
					messageData.setContext(context);
					MessageSender sender = MessageSender.createBizMessageSender();
					sender.setMessageType(0);
					sender.setMessageData(messageData);
					sender.send();
					responseContext = context.getResponseContext();
					responseContext.setResultType("SUCCESS");
					//responseContext.setResultMessage(LanguageUtil.getLocaleValue("ALERT_BACKGROUND_WORK_OK1", context.getRequestHeader().getLocaleCd()));
					// 2016.07.20 LHS 다국어처리를 위해 수정.
					responseContext.setResultMessage(LanguageUtil.getLocaleValue("ALERT_BACKGROUND_WORK_OK1", context.getRequestHeader().getLangCd()));
				} else {
					String commandClassName = serviceDef.getCmdClassNm();
					Class commandClass = Class.forName(commandClassName);
					Object commandInstance = commandClass.newInstance();

					AbsBusinessCommand command = null;

					context.setServiceDef(serviceDef);
					if( securityErrorFlag ) {
						if (commandInstance != null) {
							command = (AbsBusinessCommand)commandInstance;
							//TODO 여기서 메시지를 바인딩 해 가꼬, 넘겨 온 이름하고, 실제 메시지의 이름하고를 바인딩 해야 한다. 
							command.init(context);
	
							Effectiveness e = new Effectiveness();
	
							e.effectiveness(context);
	
							// 롤백을 해야 하는 경우는 세션빈을 호출해서 실행하고,
							if (serviceDef.isTxSupportYn()){
								// Jboss용
								// String jdbcName = "java:comp/env/h5/SessionFacade";
								// Jeus용
								String jdbcName = "java:comp/env/h5/ejb/session/facade/SessionFacadeHome";
	
								ctx = new InitialContext();
								SessionFacadeHome home = (SessionFacadeHome)ctx.lookup(jdbcName);
								SessionFacade local = home.create();
								responseContext = local.executeCommand(command);
							} else { // 아니면, 그냥 실행한다.
								responseContext = command.run();
							}
	
							// 2016.07.21. LHS 다국어처리를 위해 수정.
							//e.effectiveness(responseContext, context.getRequestHeader().getLocaleCd());
							e.effectiveness(responseContext, context.getRequestHeader().getLangCd());
						}
					}
				}

			}

			// 응답 메시지를 화면으로 전달한다.
			// 응답 컨텍스트를 리퀘스트 스코프로 담는다.
			if (responseContext != null)
				request.setAttribute(NAME_RESPONSE_CONTEXT, responseContext);
			else {
				return;
			}
			
			if (ResponseContext.RESULT_TYPE_SUCCESS.equals(responseContext.getResultType())) { // 처리 결과가 성공이다..
				if ((successCode != null) && (!"".equals(successCode))) {
					responseContext.setResultCode(successCode);
					// 2016.07.20. LHS 다국어처리를 위해 수정.
					String successMsg = LanguageUtil.getLocaleValue(successCode, context.getRequestHeader().getLangCd());

					if ((successMsg == null) || ("".equals(successMsg))) {
						successMsg = successCode;
					}
					responseContext.setResultMessage(successMsg);
				}

				// 결과 처리를 위임할 jsp 페이지를 지정한다.
				String redirectURL = getInitParameter(INIT_PARAM_SUCCESS_URL);
				RequestDispatcher dispatcher = request.getRequestDispatcher(redirectURL);
				dispatcher.forward(request, response);
			} else { // 아니면 무조건 에러...
				processException(request, response);
			}
		} catch (Exception e) {
			e.printStackTrace();

			String sessionFlag = "";

			if (e instanceof CommandExecuteException) {
				if ((errorCode == null) || ("".equals(errorCode)))
					errorCode = ((CommandExecuteException)e).getErrCode();
				sessionFlag = ((CommandExecuteException)e).getSessionFlag();
			}

			if ((errorCode == null) || ("".equals(errorCode))) {
				errorCode = ERROR_CODE;
			}
			// 2016.07.20. LHS 다국어처리를 위해 수정.
			String errorMsg = LanguageUtil.getLocaleValue(errorCode, context.getRequestHeader().getLangCd());

			if ((errorMsg == null) || ("".equals(errorMsg))) {
				errorMsg = errorCode;
			}
			String tmpErr = e.getMessage();
			if (tmpErr != null) {
				int idx = tmpErr.indexOf("::");
				if (idx > -1) {
					tmpErr = tmpErr.substring(idx + 2, idx + 7);
					// 2016.07.20. LHS 다국어처리를 위해 수정.
					tmpErr = LanguageUtil.getLocaleValue(tmpErr, context.getRequestHeader().getLangCd());
					if ((tmpErr != null) && (!"".equals(tmpErr))) {
						errorMsg = tmpErr;
					}
				}
			}
			System.out.println("\terrorCode >> " + errorCode);
			System.out.println("\terrorMsg >> " + errorMsg);

			request.setAttribute("REQUEST_CONTEXT", context);
			responseContext = context.getResponseContext();
			if ("Y".equals(sessionFlag))
				responseContext.setResultType("SESSION_LOG_OUT");
			else {
				responseContext.setResultType(ResponseContext.RESULT_TYPE_ERROR);
			}
			responseContext.setResultCode(errorCode);
			responseContext.setResultMessage(errorMsg);
			request.setAttribute(NAME_RESPONSE_CONTEXT, responseContext);
			processException(request, response);
		}
		finally {
			try {
				if (rset != null) {
					rset.close();
					rset = null;
				}
				if (stmt != null) {
					stmt.close();
					stmt = null;
				}
				if (con != null) {
					con.close();
					con = null;
				}
			} catch (Exception e) {
				e.printStackTrace();
			}
		}
	}

	protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
		doPost(request, response);
	}

	private void processException(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
		String redirectURL = getInitParameter(INIT_PARAM_ERROR_URL);
		RequestDispatcher dispatcher = request.getRequestDispatcher(redirectURL);
		dispatcher.forward(request, response);
	}

	/**
	 * 리퀘스트로부터 요청 전문에 대한 스트링을 반환받는다.
	 * @param request
	 * @return
	 */
	protected String getRequestString(HttpServletRequest request)
			throws IOException
	{
		return request.getParameter(PARAM_REQUEST_MSG);
	}
	/**
	 * 컨텍스트 빌더를 반환한다.
	 * @return
	 */
	protected TextBaseRequestContextBuilder getContextBuilder(){
		return new TextBaseRequestContextBuilder();
	}
}