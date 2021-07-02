package h5.mobile;
import java.io.BufferedInputStream;
import java.io.BufferedOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.URLEncoder;
import java.sql.Blob;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

import javax.naming.Context;
import javax.naming.InitialContext;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.sql.DataSource;

import com.win.frame.server.ServerConfig;
import com.win.frame.server.ServerConfigFactory;
import com.win.rf.config.ConfigurationManager;
import com.win.rf.config.IConfigurationInfoProvider;



public class ReportFileView extends HttpServlet{

	@Override
	protected void doGet(HttpServletRequest req, HttpServletResponse resp)
			throws ServletException, IOException {
		doPost(req, resp);
	}

	@Override
	protected void doPost(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {
		
		
		String fileId = (String) request.getParameter("fileId");
		String fileName = (String) request.getParameter("fileName");
		
		IConfigurationInfoProvider provider = ConfigurationManager.getConfigurationInfoProvider();
		ServerConfig sConfig = ServerConfigFactory.getServerConfig();
		String jdbcJndiPrefix = sConfig.getConfigValue("jdbcJndiPrefix");
		String jndiName =jdbcJndiPrefix+ provider.getItem("h5prd.jdbc.jndi").getValue();
		 
		
		Connection con = null;
		PreparedStatement ps = null;
		ResultSet rs = null;
		
		
		BufferedInputStream input = null;
		InputStream is = null;
		StringBuffer sql = new StringBuffer();
		
		OutputStream out = null;
		BufferedOutputStream bos = null;
		
		try{
			fileName = URLEncoder.encode(fileName, "UTF-8");
			// 데이터베이스 커넥션을 얻는다.
			Context ctx = new InitialContext();
			DataSource ds = (DataSource) ctx.lookup(jndiName);
			con = ds.getConnection();
			
			response.setContentType("application/octet-stream");
			//response.setContentType("application/pdf");
			response.setHeader("Content-Disposition", "attachment;filename=" + fileName +".pdf");
			response.setHeader("Content-Transfer-Encoding", "binary");
			
			sql.append(" SELECT FILE_CONTENT ");
			sql.append("   FROM FRM_FILE_STORE ");
			sql.append("  WHERE FILE_ID = ? ");
			
			ps = con.prepareStatement(sql.toString());
			ps.setString(1, fileId);                         
			rs = ps.executeQuery();
			
			if(rs.next()){
				Blob b = rs.getBlob("FILE_CONTENT");
				input = new BufferedInputStream(rs.getBlob("FILE_CONTENT").getBinaryStream());
				response.setHeader("Content-Length", ""+b.length());
			}
			
			
			//아웃스트림으로 출력
			byte[] buf = new byte[4*1024];
			int len;
			
			while((len = input.read(buf, 0, buf.length)) != -1){
				response.getOutputStream().write(buf, 0, len);
			}
			
			input.close();
			rs.close();
			ps.close();
			con.close();
		}catch(Exception e){
			e.printStackTrace();
			is = new FileInputStream(new File(getServletContext().getRealPath("/noimage.png")));
		}finally{
			try{
				if(input != null){
					input.close();
					input = null;
				}
				
				if(out != null){
					out.close();
					out = null;
				}
				
				if(is != null){
					is.close();
					is = null;
				}
				
				if(rs != null) rs.close();
				if(ps != null) ps.close();
				if(con != null) con.close();
			}catch(Exception e){
				e.printStackTrace();
			}
		}
	}
	
	private InputStream getFileFromDB2(String fileType, HttpServletRequest request, int filePathId, int empId){
		IConfigurationInfoProvider provider = ConfigurationManager.getConfigurationInfoProvider();
		ServerConfig sConfig = ServerConfigFactory.getServerConfig();
		String jdbcJndiPrefix = sConfig.getConfigValue("jdbcJndiPrefix");
		String jndiName =jdbcJndiPrefix+ provider.getItem("h5prd.jdbc.jndi").getValue();
		
		
		Connection con = null;
		PreparedStatement ps = null;
		ResultSet rs = null;
		
		BufferedInputStream input = null;
		InputStream is = null;
		StringBuffer sql = new StringBuffer();
		FileOutputStream fos = null;
		
		try{
			// 데이터베이스 커넥션을 얻는다.
			Context ctx = new InitialContext();
			DataSource ds = (DataSource) ctx.lookup(jndiName);
			con = ds.getConnection();
			
			
			sql.append(" SELECT FILE_CONTENT ");
			sql.append("   FROM FRM_FILE_STORE ");
			sql.append("  WHERE FILE_ID = ? ");
		    
		    ps =  con.prepareStatement(sql.toString());
		    ps.setInt(2, filePathId);
		    
		    rs = ps.executeQuery();
		    
		    
		    if(rs.next()){
		    	is = rs.getBlob(1).getBinaryStream();
		    	//is = new BufferedInputStream(rs.getBinaryStream("file_content"));
		    	//is = new BufferedInputStream(new FileInputStream(new File(rs.get)));
		    }else{
		    	is = new FileInputStream(new File(this.getServletContext().getRealPath("/noimage.png")));
		    }
			
			return is;
		}catch(Exception e){
			e.printStackTrace();
			return null;
		}

	}
	
	
	private InputStream getFileFromDB(String fileType, HttpServletRequest request, int filePathId, int empId){
		IConfigurationInfoProvider provider = ConfigurationManager.getConfigurationInfoProvider();
		ServerConfig sConfig = ServerConfigFactory.getServerConfig();
		String jdbcJndiPrefix = sConfig.getConfigValue("jdbcJndiPrefix");
		String jndiName =jdbcJndiPrefix+ provider.getItem("h5prd.jdbc.jndi").getValue();
		
		
		Connection con = null;
		PreparedStatement ps = null;
		ResultSet rs = null;
		
		InputStream is = null;
		StringBuffer sql = new StringBuffer();
		
		try{
			// 데이터베이스 커넥션을 얻는다.
			Context ctx = new InitialContext();
			DataSource ds = (DataSource) ctx.lookup(jndiName);
			con = ds.getConnection();
			
			
			sql.append(" SELECT C.FILE_CONTENT ");
			sql.append("   FROM FRM_FILE_PATH A ");
			sql.append("  INNER JOIN FRM_FILE_INFO B ");
			sql.append("     ON A.FILE_PATH_ID = B.FILE_PATH_ID ");
			sql.append("  INNER JOIN FRM_FILE_STORE C ");
			sql.append("     ON B.FILE_ID = C.FILE_ID");
			sql.append("  WHERE A.EMP_ID = ? ");
			sql.append("    AND A.FILE_PATH_ID = ? ");
			
			ps =  con.prepareStatement(sql.toString());
			ps.setInt(1, empId);
			ps.setInt(2, filePathId);
			
			rs = ps.executeQuery();
			
			if(rs.next()){
				//is = new BufferedInputStream(rs.getBinaryStream("file_content"));
				//is = new BufferedInputStream(new FileInputStream(new File(rs.get)));
			}else{
				is = new FileInputStream(new File(this.getServletContext().getRealPath("/noimage.png")));
			}
			
			return is;
		}catch(Exception e){
			e.printStackTrace();
			return null;
		}
		
	}
	
}
