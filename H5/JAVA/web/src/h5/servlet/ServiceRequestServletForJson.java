package h5.servlet;

import java.io.BufferedReader;
import java.io.IOError;
import java.io.IOException;

import javax.servlet.http.HttpServletRequest;

import h5.sys.context.JsonBaseRequestContextBuilder;
import h5.sys.context.TextBaseRequestContextBuilder;

public class ServiceRequestServletForJson extends ServiceRequestServlet {

	@Override
	protected TextBaseRequestContextBuilder getContextBuilder() {
		// TODO Auto-generated method stub
		return new JsonBaseRequestContextBuilder();
	}
	
	@Override
	protected String getRequestString(HttpServletRequest request)throws IOException{
		if(request.getParameterMap() != null && request.getParameterMap().containsKey(PARAM_REQUEST_MSG))
			return request.getParameter(PARAM_REQUEST_MSG);
		else if(request.getAttribute(PARAM_REQUEST_MSG) != null)
			return (String)request.getAttribute(PARAM_REQUEST_MSG);
		
		BufferedReader reader = request.getReader();
		String data = reader.readLine();
		return data;
	}
}
