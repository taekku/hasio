package h5.servlet;

import java.io.IOException;
import java.io.PrintWriter;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.HashMap;
import java.util.List;
import java.util.regex.Pattern;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import org.json.simple.JSONArray;
import org.json.simple.JSONObject;

import com.win.frame.invoker.GridResult;
import com.win.rf.invoker.SQLInvoker;

import h5.servlet.util.ChatbotUtil;
import h5.servlet.vo.ChatbotItem;
import jeus.util.regex.Matcher;

public class ChatbotRequest extends HttpServlet {

	public static HashMap<String, ChatbotUtil> chatbotMap;
	PreparedStatement stmt = null;
	ResultSet rset = null;

	@Override
	public void init() throws ServletException {
		chatbotMap = new HashMap<>();
		
		chatbotMap.put("I", new ChatbotUtil("I"));
		chatbotMap.put("X", new ChatbotUtil("X"));
		chatbotMap.put("T", new ChatbotUtil("T"));
		chatbotMap.put("C", new ChatbotUtil("C"));
		chatbotMap.put("F", new ChatbotUtil("F"));
		chatbotMap.put("H", new ChatbotUtil("H"));
		chatbotMap.put("M", new ChatbotUtil("M"));
		chatbotMap.put("Y", new ChatbotUtil("Y"));
		chatbotMap.put("S", new ChatbotUtil("S"));
		chatbotMap.put("W", new ChatbotUtil("W"));
		chatbotMap.put("A", new ChatbotUtil("A"));
		chatbotMap.put("E", new ChatbotUtil("E"));
		chatbotMap.put("R", new ChatbotUtil("R"));
		chatbotMap.put("B", new ChatbotUtil("B"));
		chatbotMap.put("U", new ChatbotUtil("U"));
		

		super.init();
	}

	@Override
	protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
		String requestText = req.getParameter("requestText");
		String pkId = null;
		
		resp.setContentType("application/x-json; charset=UTF-8");
		PrintWriter pw = resp.getWriter();
		JSONObject obj = new JSONObject();

		HttpSession session = req.getSession();

		String company_cd = (String) session.getAttribute("session_company_cd");

		try {
			// 버튼을 눌러서 들어왔을 때
			pkId = req.getParameter("pk_id");
		} catch (Exception e) {
			pkId = null;
		}

		if (pkId != null) {
			// 버튼을 눌러서 들어옴
			ChatbotItem resultItem = chatbotMap.get(company_cd).findItemById(pkId);
			obj = chatbotMap.get(company_cd).processResult(resultItem);
		} else {
			// 검색 키워드로 타는 쪽
			List<ChatbotItem> resultItems = chatbotMap.get(company_cd).findItem(requestText);
			
			obj = chatbotMap.get(company_cd).processResult(resultItems);
		}
		pw.print(obj);
		pw.flush();
	}
}
