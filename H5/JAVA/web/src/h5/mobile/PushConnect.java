package h5.mobile;

import java.io.BufferedOutputStream;
import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.URL;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.HashMap;

import javax.naming.Context;
import javax.naming.InitialContext;
import javax.net.ssl.HttpsURLConnection;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import javax.sql.DataSource;

import org.json.simple.JSONArray;
import org.json.simple.JSONObject;

import com.win.frame.server.ServerConfig;
import com.win.frame.server.ServerConfigFactory;
import com.win.rf.config.ConfigurationManager;
import com.win.rf.config.IConfigurationInfoProvider;

public class PushConnect extends HttpServlet{
	//Firebase Poroject 서버 키 
	private static final String FIREBASE_SERVER_KEY = "key=AAAAWdDkBrU:APA91bE1NiAeMtzIhHmXJR_gNNL5fyuHoxfMby25hN1hY5hJKwXduQn4xS2tDVSm3MmvZ3AclCkjQJyoffl5Z22FAaCaSfB8YxaoOGgoxXrFmkZeEmewNmZc5ui19jzLw2ZUkjEC6tKD";
	//Firebase API URL
	private static final String FIREBASE_API_URL = "https://fcm.googleapis.com/fcm/send";
	
	
	@Override
	protected void doGet(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {
		
		String FCM_TOKEN = "";
		String DEVICE_TYPE = "";
		
		HttpSession session = request.getSession();
		String sessionEmpNo = (String) session.getAttribute("session_emp_no");
		String sessionCompanyCd = (String) session.getAttribute("session_company_cd");
		
		String title = (String)request.getParameter("title");
		String content = (String)request.getParameter("content");
		String objectId = (String)request.getParameter("object_id");
		String objectPath = (String)request.getParameter("path");
		
		System.out.println("## PushConnect -- title : "+title);
		System.out.println("## PushConnect -- content : "+content);
		System.out.println("## PushConnect -- objectId : "+objectId);
		System.out.println("## PushConnect -- objectPath : "+objectPath);
		
		
		URL url = null;
		HttpURLConnection connection = null;
		BufferedOutputStream bos = null;
		BufferedReader reader = null;
		
		HashMap<String, String> map = new HashMap<String, String>();
		
		
		try{
			url = new URL(FIREBASE_API_URL);
			connection = FIREBASE_API_URL.startsWith("https://")? (HttpsURLConnection) url.openConnection() 
					: (HttpURLConnection) url.openConnection();
			
			connection.setRequestProperty("Content-Type", "application/json; charset=utf-8");
			connection.setRequestProperty("cache-control", "no-cache");
			connection.setRequestProperty("Authorization", FIREBASE_SERVER_KEY);
			
			connection.setDoOutput(true);
			connection.setDoInput(true);
			
			connection.connect();
			
			bos = new BufferedOutputStream(connection.getOutputStream());
			
			map = getUserFcmToken(sessionEmpNo, sessionCompanyCd);
			
			FCM_TOKEN = map.get("fcmKey");
			DEVICE_TYPE = map.get("dtype");
			
			//System.out.println("## FCM_TOKEN : "+FCM_TOKEN);
			//System.out.println("## DEVICE_TYPE : "+DEVICE_TYPE);
			
			String data =  "\"data\": {\r\n" + "  \"object_id\": \""+objectId+"\",\r\n" + "  \"path\": \""+objectPath+"\"\r\n" + " }";
			String notification = "\"notification\" : {\r\n"
					+ "  \"body\" : \""+content+"\",\r\n"
					+ "  \"title\" : \""+title+"\"\r\n" 
					+ " }";
			
			
			// Android, iOS 인지에 따라 메세지 가공이 달라진다.
			String message = null;
			if( "iOS".equals(DEVICE_TYPE.trim()) ) {
				
				message = "{\"to\" : \""+ FCM_TOKEN+"\", "
						+ "\"priority\" : \"high\", "
						+ "  \"content_available\" : true"
				        +data+","
						+notification+"}";
				
			}else if( "Android".equals(DEVICE_TYPE.trim()) ) {
				
				message = "{\"to\" : \""+ FCM_TOKEN+"\", "
						+data+","
						+notification+"}";
				
			}
			
			System.out.println("###"+DEVICE_TYPE);
			System.out.println("### message : "+message);
			//메세지 가공
			//String data = "\"data\": {\r\n" + "  \"object_id\": \""+objectId+"\",\r\n" + "  \"ko\": \"가나다\"\r\n" + " }";
			//String data = "\"priority\": \"high\" ,"; 
			
			
			bos.write(message.getBytes("UTF-8"));
			
			bos.flush();
			bos.close();
			
			int responseCode = connection.getResponseCode();
			String responseMessage = connection.getResponseMessage();
			
			StringBuffer buffer = null;
			
			if(responseCode == HttpURLConnection.HTTP_OK){
				buffer = new StringBuffer();
				reader = new BufferedReader(new InputStreamReader(connection.getInputStream(), "UTF-8"));
				String temp = null;
				while((temp = reader.readLine()) != null){
					buffer.append(temp);
				}
				reader.close();
			}
			
			connection.disconnect();
			
			System.out.println("## PushConnect.java -- "+String.format("Response : %d, %s", responseCode, responseMessage));
			System.out.println("Response Data :");
			System.out.println(buffer == null ? "NULL " : buffer.toString());
			
			
		}catch(Exception e){
			e.printStackTrace();
		}
	}
	
	

	@Override
	protected void doPost(HttpServletRequest req, HttpServletResponse resp)
			throws ServletException, IOException {
		doGet(req, resp);
	}
	
	
	public HashMap<String, String> getUserFcmToken(String empNo, String companyCd){
		IConfigurationInfoProvider provider = ConfigurationManager.getConfigurationInfoProvider();
		ServerConfig sConfig = ServerConfigFactory.getServerConfig();
		String jdbcJndiPrefix = sConfig.getConfigValue("jdbcJndiPrefix");
		String jndiName =jdbcJndiPrefix+ provider.getItem("h5prd.jdbc.jndi").getValue();
		Connection con = null;
		PreparedStatement stmt = null;
		ResultSet rset = null;
		
		String fcmKey = null;
		String dtype = null;
		
		HashMap<String, String> map = new HashMap<String,String>();
		try{
			Context ctx = new InitialContext();
			Object o = ctx.lookup(jndiName);
			DataSource ds = (DataSource) o;
			con = ds.getConnection();
			
			StringBuffer sb = new StringBuffer();
			sb.append(" SELECT FCM_KEY ");
			sb.append("      , DEVICE_TYPE ");
			sb.append("   FROM FRM_USER ");
			sb.append("  WHERE LOGIN_ID = ? ");
			sb.append("    AND COMPANY_CD = ? ");
			
			stmt = con.prepareStatement(sb.toString());
			stmt.setString(1, empNo);
			stmt.setString(2, companyCd);
			
			rset = stmt.executeQuery();
			if(rset.next()){
				fcmKey = rset.getString("fcm_key");
				dtype = rset.getString("device_type");
			}
			
			map.put("fcmKey", fcmKey);
			map.put("dtype", dtype);
			
			
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
			}catch(Exception ee){
				ee.printStackTrace();
			}
		}
		return map;
	}
	
}
