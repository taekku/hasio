package h5.servlet;


import h5.servlet.vo.FileInfoVO;
import h5.sys.registry.RegistryItem;
import h5.sys.registry.SystemRegistry;

import java.io.File;
import java.io.IOException;
import java.io.PrintWriter;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.List;

import javax.naming.Context;
import javax.naming.InitialContext;
import javax.servlet.ServletException;
import javax.servlet.ServletOutputStream;
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

/**
 * Servlet implementation class FileUploadTest
 */
public class FileDelete extends HttpServlet {
	private static final long serialVersionUID = 1L;
    private String dir = "";

	// 클라이언트 프로그램에서 전달하는 데이터가 들어갈 필드 이름
	static final String PARAM_SESSION_ID   = "session_id";
	static final String PARAM_FILE_PATH_ID = "file_path_id";
	static final String PARAM_FILE_ID      = "file_id";
	
    /**
     * @see HttpServlet#HttpServlet()
     */
    public FileDelete() {
        super();
        // TODO Auto-generated constructor stub
    }

	/**
	 * @see HttpServlet#doGet(HttpServletRequest request, HttpServletResponse response)
	 */
    @Override
	protected void doPost(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {
		// Delete Directory

		String[] filePathIds = null;
		String[] fileIds     = null;
		String[] sessionIds  = null;

		String filePathId = "";
		String fileNm     = "";
		String store_type = "DB"; // DB OR FILE
		String sessionId  = null;
		String realPath   = "";
		String referer    = "";
		String fileId     = null;

		StringBuffer sql  = null;

	    Connection con = null;
	    PreparedStatement ps = null;
	    ResultSet rs = null;
	    //ServletOutputStream out = null;
 		try {
 			
 			
 			sessionIds  = request.getParameterValues(PARAM_SESSION_ID);
 			filePathIds = request.getParameterValues(PARAM_FILE_PATH_ID);
 			fileId      = request.getParameter(PARAM_FILE_ID);
 			String upload_type      = request.getParameter("upload_type");
 			
 			if (fileId != null && !"".equals(fileId)) {
				fileIds = fileId.split("&");
 			}
 			
 			referer = request.getHeader("REFERER");
 			
 			if (sessionIds != null && sessionIds.length > 0) {
 				sessionId = sessionIds[0];
 			}
 			if (filePathIds != null && filePathIds.length > 0) {
 				filePathId = filePathIds[0];
 			}

 		    RegistryItem registryItem =  SystemRegistry.getRegistryItem("GLOBAL_ATTR/SYSTEM_ENVIRONMENTS/NODES/FILESTORE/TYPE");
 		    store_type = registryItem.getValue();
 		    
			// 저장구분(DB, FILE)
			if (store_type == null || "".equals(store_type)) {
				store_type = "DB";
			}

 			// sessionId가 존재하지 않으면 오류를 발생한다.
//			if (sessionId==null||"".equals(sessionId)) {
//				processException(request,response);
//			}

			// 데이터소스로부터 저장을 위한 커넥션을 얻어낸다.
			IConfigurationInfoProvider config = ConfigurationManager.getConfigurationInfoProvider();
			ServerConfig sConfig = ServerConfigFactory.getServerConfig();
			String jdbcJndiPrefix = sConfig.getConfigValue("jdbcJndiPrefix");
			String jdbcJndiName = jdbcJndiPrefix+config.getItem("h5prd.jdbc.jndi").getValue();
			dir = config.getItem("dir.fileUploadPath").getValue();
			
		    Context ctx = new InitialContext();
		    DataSource ds = (DataSource) ctx.lookup(jdbcJndiName);
		    con = ds.getConnection();
		    
			for (int i=0,ii=fileIds.length;i<ii;i++) {
				
		    	if (store_type.equals("FILE")) {

					// 파일경로와 파일명을 조회한다.
					sql = new StringBuffer();
					
					sql.append("SELECT A.FILE_PATH, B.FILE_NM FROM FRM_FILE_PATH A, FRM_FILE_INFO B WHERE A.FILE_PATH_ID = B.FILE_PATH_ID AND B.FILE_ID = " + fileIds[i] + " ");
					
				    ps = con.prepareStatement(sql.toString());
				    
				    rs = ps.executeQuery();
	
				    if(rs.next()){
				    	realPath = rs.getString("file_path");
				    	fileNm   = rs.getString("file_nm");
				    }
		
					String file_url = dir + realPath + fileNm;
					
					File file = new File(file_url);
		
					if(file.delete()) {
						System.out.println(fileNm + " are deleted completely!!!");
					} else {
						request.setAttribute("retCode", "FAIL!");
						request.setAttribute("retMessage", "삭제에 실패하였습니다.");
						System.out.println(fileNm + " delete Error!!!");
					}
		    	} else {
				    sql = new StringBuffer();
					
					// Delete a file information 
					sql.append("DELETE FROM FRM_FILE_STORE ");
					sql.append("WHERE FILE_ID = " + fileIds[i] + " ");
		
				    ps = con.prepareStatement(sql.toString());
				    ps.executeUpdate();
		
					ps.close();
		    	}
					
			    sql = new StringBuffer();
	
				// Delete a file information 
				sql.append("DELETE FROM FRM_FILE_INFO ");
				sql.append("WHERE FILE_ID = " + fileIds[i] + " ");
	
			    ps = con.prepareStatement(sql.toString());
			    ps.executeUpdate();
	
				ps.close();
			}
		    con.close();

			String outDsStr = "file_path_id="+filePathId+"&file_path="+realPath;
			
			//out = response.getOutputStream();
			//out.write(outDsStr.getBytes("UTF-8"));

			con.close();
			request.setAttribute("retCode", "SUCCESS!");
			request.setAttribute("retMessage", "삭제되었습니다.");

			if( "aj".equals(upload_type)){
				response.setContentType("text/html;charset=UTF-8"); // 한글로 자료를 넘겨주기 위해서.
	            java.io.PrintWriter pw = response.getWriter();
	            
	            JSONArray jsArray = new JSONArray();
	            
	          
	            JSONObject obj = new JSONObject();
	            obj.put("result", "ok");
				pw.print(obj.toJSONString());
				pw.flush();		
			} else if("mobile".equals(upload_type)){
				request.setAttribute("file_path_id", request.getParameter("file_path_id"));
				sendScript(request, response);
			}else {
				sendScript(request, response);
			}
		} catch (Exception e) {
			request.setAttribute("retCode", "FAIL!");
			request.setAttribute("retMessage", "관리자에게 문의하십시오.");
			e.printStackTrace();

			sendScript(request, response);
			throw new ServletException(e.getCause());
		}finally{
			//out.flush();
			try{
		        if(ps != null) ps.close();
		        if(con != null) con.close();
			}catch(SQLException se){}
		}
	}
    
	/**
	 * @see HttpServlet#doPost(HttpServletRequest request, HttpServletResponse response)
	 */
    @Override
	protected void doGet(HttpServletRequest req, HttpServletResponse resp)
			throws ServletException, IOException {
		// TODO Auto-generated method stub
		doPost(req, resp);
	}
    
    private void sendScript(HttpServletRequest request, HttpServletResponse response){
		try{
			HttpSession session = request.getSession();
			response.setContentType("text/html; charset=utf-8");
			PrintWriter out2 =response.getWriter();
			out2.println("<script>parent.deleteEnd('"+request.getAttribute("file_path_id")+"','"+request.getAttribute("retCode")+"','"+request.getAttribute("retMessage")+"')</script>");
			out2.close();
		}catch(Exception e){
			e.printStackTrace();
		}
	}
}
