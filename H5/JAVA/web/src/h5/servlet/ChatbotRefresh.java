package h5.servlet;

import java.io.IOException;
import java.util.HashMap;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import h5.servlet.util.ChatbotUtil;
import h5.sys.context.ResponseContext;
import h5.sys.message.DefaultListBaseMessage;
import h5.sys.message.IListBaseMessage;
import h5.sys.message.IMessageItem;

public class ChatbotRefresh extends HttpServlet {
	
	@Override
	protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
		doPost(req, resp);
	}
	
	@Override
	protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
		ChatbotRequest.chatbotMap = null;
		ChatbotRequest.chatbotMap = new HashMap<>();
		ChatbotRequest.chatbotMap.put("E", new ChatbotUtil("E"));
	}
}

