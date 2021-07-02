package h5.servlet.filters;

import h5.sys.context.HttpBaseRequestContext;
import h5.sys.context.IRequestContext;
import h5.sys.context.JsonBaseRequestContextBuilder;
import h5.sys.context.TextBaseRequestContextBuilder;

import java.io.BufferedReader;
import java.io.IOException;
import java.net.URLDecoder;

import javax.servlet.Filter;
import javax.servlet.FilterChain;
import javax.servlet.FilterConfig;
import javax.servlet.ServletException;
import javax.servlet.ServletRequest;
import javax.servlet.ServletResponse;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.json.simple.JSONObject;
import org.json.simple.parser.JSONParser;

import com.win.rf.config.ConfigurationManager;
import com.win.rf.config.IConfigurationInfoProvider;

/**
 * JSON 형태의 데이터를 파싱하여 requestContext로 만들어 request scope에 넣는 필터
 * @author win
 *
 */
public class RequestMessageFilter implements Filter {

	// 클라이언트 프로그램에서 전달하는 데이터가 들어갈 필드 이름
	static final String PARAM_REQUEST_MSG = "request_message";
	// request 객체에 저장할 request context의 참조 키 값.
	static final String NAME_RESPONSE_CONTEXT = "RESPONSE_CONTEXT";
	
	@Override
	public void destroy() {
	}

	@Override
	public void doFilter(ServletRequest request, ServletResponse response,	FilterChain chain) throws IOException, ServletException {
		// RequestContext를 선언한다. 여기서는 HttpBaseRequestContext를 이용한다.
		// 즉 request로 넘어 온 객체 중 PARAM_MSG_MAP에 대한 값을 이용하여 텍스트-오브젝트화 과정을 수행할 때,
		// Http 프로토콜을 이용하여 전달 된 값은 HttpBaseRequestContext로 시리얼라이즈 한다. 
		IRequestContext context = null;
		context = new HttpBaseRequestContext();
		
		String requestMsgString = getRequestString((HttpServletRequest)request);
		
		try {
			JSONParser jsonPs = new JSONParser();
			JSONObject jsonObj = (JSONObject)jsonPs.parse(requestMsgString);
			System.out.println("----------------------- RequestMsg ----------------------->"
							 		+ "\n RequestMsg HEADER : " + jsonObj.get("HEADER") 
							 		+ "\n RequestMsg BODY : "   + jsonObj.get("BODY"));
			
			if(requestMsgString == null) {
				throw new NullPointerException("Received message map is Null");
			}
			
			// 1. H5 5.0의 서비스 구동 설정 정보를 이용하여, 디시리얼라이즈 과정에서 인코딩을 쓸 것인지 등의 여부를 판단한다.
			IConfigurationInfoProvider provider = ConfigurationManager.getConfigurationInfoProvider();
			
			// encode는 전달과정에서 사용할 스트링의 인코딩을 하겠는냐는 값이고,
			// encoding은 스트링의 인코딩 값이 무어냐는 것에 대한 답이다.(EUC-KR, 또는 UTF-8과 같이)
			String encode = provider.getItem("server.encode").getValue();
			String encoding = provider.getItem("server.encoding").getValue();
			
			if(requestMsgString != null) {
				// Flex에서 엔터를 처리하는 방식이 문제가 있으므로 이 구문이 추가됨.
				requestMsgString = requestMsgString.replaceAll("\r", "\n"); 
			}
			
			// 인코딩을 해야 할 상황이라면, 인코딩을 수행한다.
			if("true".equalsIgnoreCase(encode)){
				requestMsgString = new String(URLDecoder.decode(requestMsgString,"UTF-8").getBytes(encoding),"ISO8859-1");
			}
			
			TextBaseRequestContextBuilder builder = getContextBuilder();
			context = (IRequestContext)builder.parse(requestMsgString,(HttpServletRequest)request);
			
			((HttpBaseRequestContext)context).setHttpRequest((HttpServletRequest)request);
			((HttpBaseRequestContext)context).setHttpResponse((HttpServletResponse)response);
			
			request.setAttribute("REQUEST_CONTEXT", context);
			
		} catch(Exception e) {
			e.printStackTrace();
			throw new ServletException(e);
		}
		
		chain.doFilter(request, response);

	}

	@Override
	public void init(FilterConfig config) throws ServletException {

	}
	
	protected String getRequestString(HttpServletRequest request)throws IOException{
		if(request.getParameterMap() != null && request.getParameterMap().containsKey(PARAM_REQUEST_MSG)){
			return request.getParameter(PARAM_REQUEST_MSG);
		} else if(request.getAttribute(PARAM_REQUEST_MSG) != null) {
			return (String)request.getAttribute(PARAM_REQUEST_MSG);
		}
		
		BufferedReader reader = request.getReader();
		String data = reader.readLine();
		return data;
	}
	
	protected TextBaseRequestContextBuilder getContextBuilder() {
		return new JsonBaseRequestContextBuilder();
	}

}
