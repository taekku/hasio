package h5.servlet;

import java.io.BufferedInputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.InputStream;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.HashMap;

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
import com.win.rf.invoker.SQLInvoker;


public class FrmImageViewer extends HttpServlet {

	@Override
	protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
		// 옵션 변수 초기화
		String imageTableName = "FRM_FILE_STORE";
		String imageColumnName = "file_content";
		String imagePath = getServletContext().getRealPath("/");
		String store_type = request.getParameter("store_type");
		String file_id = request.getParameter("file_id");
		String file_type = request.getParameter("file_type");
		
		String ext_name = "";
		String file_nm = "";
		BufferedInputStream input = null;
		
		HashMap paramMap = new HashMap();
		paramMap.put( "file_id" , file_id );
		
		com.win.rf.invoker.SQLInvoker invoker = new SQLInvoker("FRM_EXT_NAME_GET", paramMap);
		com.win.frame.invoker.GridResult result = null;
		
		try {
			result = (com.win.frame.invoker.GridResult)invoker.doService();
			
			if (result.next()){
				
				ext_name = result.getValueString(0);
				file_nm = result.getValueString(1);
				file_type = ext_name;
			}
		} catch (Exception e1) {
			e1.printStackTrace();
		}
		
		boolean isDownLoadContents = false;
		
		if (file_type.equals("hwp")){
		  response.setContentType("application/x-hwp");
		  isDownLoadContents = true;
		} else if (file_type.equals("pdf")){
		  response.setContentType("application/pdf");
		} else if (file_type.equals("ppt") || file_type.equals("pptx")){
		  response.setContentType("application/vnd.ms-powerpoint");
		  isDownLoadContents = true;
		} else if (file_type.equals("doc") || file_type.equals("docx")){
		  response.setContentType("application/msword");
		  isDownLoadContents = true;
		} else if (file_type.equals("xls") || file_type.equals("xlsx")){
		  response.setContentType("application/vnd.ms-excel");
		  isDownLoadContents = true;
		} else if (file_type.equals("img")){
		  response.setContentType("image/jpeg");
		} else if (file_type.equals("xlsm")){
			response.setContentType("application/vnd.ms-excel.sheet.macroEnabled.12");
			isDownLoadContents = true;
		}else {
		  response.setContentType("application/octet-stream");
		  isDownLoadContents = true;
		} 
		
		if ( isDownLoadContents){
			response.setHeader("Content-Disposition", "attachment; filename="+java.net.URLEncoder.encode(file_nm, "UTF-8")+";");
		}
		
		InputStream is = null;
		
		try{
//			System.out.println("########### store_type : " + store_type);
//			System.out.println("########### imagePath : " + imagePath);
			if("db".equals(store_type)){
//				is = getImageFromDB(file_id, imageTableName, imageColumnName);

				Connection con = null;
			    PreparedStatement ps = null;
			    ResultSet rs = null;

				try{
		        	IConfigurationInfoProvider config = ConfigurationManager.getConfigurationInfoProvider();
		    		ServerConfig sConfig = ServerConfigFactory.getServerConfig();
		    		String jdbcJndiPrefix = sConfig.getConfigValue("jdbcJndiPrefix");
		    		String jdbcJndiName = jdbcJndiPrefix+config.getItem("h5prd.jdbc.jndi").getValue();    		
		    		
				    Context ctx = new InitialContext();
				    DataSource ds = (DataSource) ctx.lookup(jdbcJndiName);
				    con = ds.getConnection();
				    
				    String dbType = sConfig.getConfigValue("dbType");
		    	
		    		String sql = "SELECT " + imageColumnName + " FROM " + imageTableName + " WHERE file_id = ?";
		    		
				    ps = con.prepareStatement(sql);
				    ps.setString(1, file_id);
				    rs = ps.executeQuery();
					if(rs.next()){
						if( dbType.equals("oracle")){
							is = new BufferedInputStream(rs.getBinaryStream(imageColumnName));
						} else {
							/** MS-SQL stream is closed 수정 **/
							is = new BufferedInputStream(rs.getBlob(imageColumnName).getBinaryStream());
						}
					} 
					
					input = new BufferedInputStream(is);

					// 이미지를 아웃 스트림으로 출력한다.
					byte[] buf = new byte[4*1024];
					int len;
					while((len = input.read(buf, 0, buf.length)) != -1){
						response.getOutputStream().write(buf, 0, len);
					}
					rs.close();
					ps.close();
					con.close();
					
				}catch(Exception e){
					e.printStackTrace();
					throw e;
				}finally{
					
					if(input != null){
						input.close();
						input = null;
					}
					
					if(is != null){
						is.close();
						is = null;
					}
					if(rs != null) rs.close();
					if(ps != null) ps.close();
					if(con != null) con.close();
				}
				
			}else if("file".equals(store_type)){
				is = getImageFromFile(file_id , imagePath);
			}else{
				System.err.println("해당하는 저장유형이 존재하지 않습니다.("  + store_type + ")");
			}
		}catch(Exception e){
			e.printStackTrace();
			is = new FileInputStream(new File(getServletContext().getRealPath("/noimage.png")));
		}
	}

	@Override
	protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
		doGet(request,response);

	}
	
	/**
	 * 이미지 정보를 DB에서부터 가져온다.
	 * @param imageType 이미지 타입
	 * @param request 웹 요청
	 * @param imageTabelName 이미지 테이블 이름
	 * @param imageColumnName 이미지 컬럼 이름
	 * @return
	 * @throws Exception 
	 */
	protected InputStream getImageFromDB(String file_id , String imageTabelName, String imageColumnName) throws Exception{
		Connection con = null;
	    PreparedStatement ps = null;
	    ResultSet rs = null;

		InputStream input = null;
		try{
        	IConfigurationInfoProvider config = ConfigurationManager.getConfigurationInfoProvider();
    		ServerConfig sConfig = ServerConfigFactory.getServerConfig();
    		String jdbcJndiPrefix = sConfig.getConfigValue("jdbcJndiPrefix");
    		String jdbcJndiName = jdbcJndiPrefix+config.getItem("h5prd.jdbc.jndi").getValue();    		
    		
		    Context ctx = new InitialContext();
		    DataSource ds = (DataSource) ctx.lookup(jdbcJndiName);
		    con = ds.getConnection();
		    
		    String dbType = sConfig.getConfigValue("dbType");
    	
    		String sql = "SELECT " + imageColumnName + " FROM " + imageTabelName + " WHERE file_id = ?";
    		
		    ps = con.prepareStatement(sql);
		    ps.setString(1, file_id);
		    rs = ps.executeQuery();
			if(rs.next()){
				if( dbType.equals("oracle")){
					input = new BufferedInputStream(rs.getBinaryStream(imageColumnName));
				} else {
					/** MS-SQL stream is closed 수정 **/
					input = new BufferedInputStream(rs.getBlob(imageColumnName).getBinaryStream());
				}
			} 

			rs.close();
			ps.close();
			con.close();
			
			return input;
		}catch(Exception e){
			e.printStackTrace();
			throw e;
		}finally{
			if(rs != null) rs.close();
			if(ps != null) ps.close();
			if(con != null) con.close();
		}
	}


	protected InputStream getImageFromFile(String file_id ,  String imagePath) throws FileNotFoundException, ServletException, SQLException{

		Connection con = null;
	    PreparedStatement ps = null;
	    ResultSet rs = null;
	    
	    String file_path = "";
	    String file_nm = "";

		try{
        	IConfigurationInfoProvider config = ConfigurationManager.getConfigurationInfoProvider();
    		ServerConfig sConfig = ServerConfigFactory.getServerConfig();
    		String jdbcJndiPrefix = sConfig.getConfigValue("jdbcJndiPrefix");
    		String jdbcJndiName = jdbcJndiPrefix+config.getItem("h5prd.jdbc.jndi").getValue();    		
    		
		    Context ctx = new InitialContext();
		    DataSource ds = (DataSource) ctx.lookup(jdbcJndiName);
		    con = ds.getConnection();
    	
    		String sql = "SELECT file_path,							" +
    				     "       file_nm							" +
    				     "  FROM FRM_FILE_INFO A					" +
    				     "       INNER JOIN FRM_FILE_PATH B ON ( A.FILE_PATH_ID = B.FILE_PATH_ID )			" +
    				     " WHERE A.FILE_ID = ? 						" ;
    		
		    ps = con.prepareStatement(sql);
		    ps.setString(1, file_id);
		    rs = ps.executeQuery();
			if(rs.next()){
				file_path = rs.getString("file_path");
				file_nm = rs.getString("file_nm");
			}else{
				System.err.println("파일정보가 존재하지 않습니다.(" + file_id +")");
				throw new SQLException("파일정보가 존재하지 않습니다.");
			}

			rs.close();
			ps.close();
			con.close();
			
		}catch(Exception e){
			e.printStackTrace();
			throw new ServletException(e.getMessage());
			
		}finally{
			if(rs != null) rs.close();
			if(ps != null) ps.close();
			if(con != null) con.close();
		}
		
		String fullFileName = imagePath + file_path + file_nm;
		
		//fullFileName.replaceAll("/", "\\");
		
		File imageFile = new File(fullFileName);
		
		if ( !imageFile.exists()){
			System.err.println("파일이 존재하지 않습니다.(" + fullFileName +")");
			throw new FileNotFoundException("파일이 존재하지 않습니다.(" + fullFileName +")");
		}
		
		return new FileInputStream(imageFile);
	
	}
	
}
