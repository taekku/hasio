package h5.servlet;

import h5.sys.registry.RegistryItem;
import h5.sys.registry.SystemRegistry;

import java.io.BufferedInputStream;
import java.io.BufferedOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.math.BigDecimal;
import java.net.URLEncoder;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

import javax.naming.Context;
import javax.naming.InitialContext;
import javax.servlet.ServletConfig;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.sql.DataSource;

import com.win.frame.server.ServerConfig;
import com.win.frame.server.ServerConfigFactory;
import com.win.rf.config.ConfigurationManager;
import com.win.rf.config.IConfigurationInfoProvider;

/**
 * Servlet implementation class FileDownloadTest
 */
public class FileDownload extends HttpServlet {
	private static final long serialVersionUID = 1L;
    private String jdbcJndiName = "";
    private String dir = "";
    private String os_type = "";

	// 클라이언트 프로그램에서 전달하는 데이터가 들어갈 필드 이름
	static final String PARAM_FILE_ID      = "file_id";

    /**
     * @see HttpServlet#HttpServlet()
     */
    public FileDownload() {
        super();
        // TODO Auto-generated constructor stub
    }

	/**
	 * @see HttpServlet#doPost(HttpServletRequest request, HttpServletResponse response)
	 */
	protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
		// TODO Auto-generated method stub

		System.out.println("============= doPost ===============");
		
		String fileId = request.getParameter(PARAM_FILE_ID);
		String path   = "";
		String fileNm = "";
		String store_type = "DB"; // DB OR FILE

	    RegistryItem registryItem =  SystemRegistry.getRegistryItem("GLOBAL_ATTR/SYSTEM_ENVIRONMENTS/NODES/FILESTORE/TYPE");
	    store_type = registryItem.getValue();
	    
	    System.out.println("store_type : " + store_type);

		// 저장구분(DB, FILE)
		if (store_type == null || "".equals(store_type)) {
			store_type = "DB";
		}

		// Find file namd and file path
        StringBuffer sql = new StringBuffer();
		sql.append("SELECT A.FILE_PATH, B.FILE_NM FROM FRM_FILE_PATH A, FRM_FILE_INFO B WHERE A.FILE_PATH_ID = B.FILE_PATH_ID AND B.FILE_ID = " + fileId + " ");

		System.out.println("sql : " + sql);
		
	    Connection con = null;
	    PreparedStatement ps = null;
	    ResultSet rs = null;

        try{
		    Context ctx = new InitialContext();
		    DataSource ds = (DataSource) ctx.lookup(jdbcJndiName);
		    con = ds.getConnection();

		    ps = con.prepareStatement(sql.toString());
		    rs = ps.executeQuery();

		    if(rs.next()){

		    	path = rs.getString("file_path");
		    	fileNm = rs.getString("file_nm");
		    }

			System.out.println("path : " + path);
			System.out.println("file_nm : " + fileNm);

		    rs.close();
		    ps.close();
		    con.close();

	    }catch(Exception e){
	        e.printStackTrace();
	    }finally{
	    	try{
		        if(ps != null) ps.close();
		        if(con != null) con.close();
	    	}catch(SQLException se){}
	    }
	    
	    if (fileNm != null) {
	    	if (store_type.equals("FILE")) {
	    		fileDownload(request, response, path, fileNm);
	    	} else {
	    		dbDownload(request, response, fileId, fileNm);
	    	}
	    }
	}

	protected void fileDownload(HttpServletRequest request, HttpServletResponse response, String path, String fileNm) throws ServletException, IOException {

		System.out.println("============= fileDownload ===============");

		if (os_type != null && os_type.equals("ms949")) {
			fileNm = new String(fileNm.getBytes("UTF-8"),"ISO8859-1");

			response.setContentType("application/unknown;");
			response.setHeader("Content-Disposition", "attachment;filename=" + fileNm + ";");
		} else {
			response.setHeader("Content-Disposition", "attachment;filename=" + java.net.URLEncoder.encode(fileNm, "UTF-8") + ";");
		}

		System.out.println("os_type : " + os_type);
		
//		response.setContentType("application/unknown;");
////		response.setHeader("Content-Disposition", "attachment;filename=" + java.net.URLEncoder.encode(fileNm, "UTF-8") + ";");
//		response.setHeader("Content-Disposition", "attachment;filename=" + fileNm + ";");

//		response.setContentType("application/octet-stream");
//		response.setHeader("Content-Disposition", "attachment;filename="+fileNm+";");

		String file_url = dir + path + fileNm;
		
		System.out.println("file_url : " + file_url);
		
		File file = new File(file_url);

		System.out.println("file_length : " + file.length());
		
		if(file.exists()) {
			byte[] bytestream = new byte[(int)file.length()];

			BufferedInputStream  fin  = new BufferedInputStream(new FileInputStream(file));
			BufferedOutputStream fouts = new BufferedOutputStream(response.getOutputStream(), 4096);

			int read = 0;
			try {	
				while ((read = fin.read(bytestream)) != -1) {
					fouts.write(bytestream, 0, read);
				}

//				fouts.close();
//				fin.close();
			}
			catch (Exception e) {
				System.out.println(e.getMessage());
			}
			finally {
				if(fouts!=null) fouts.close();
				if(fin!=null) fin.close();
			}
		}
	}

	protected void dbDownload(HttpServletRequest request, HttpServletResponse response, String fileId, String fileNm) throws ServletException, IOException {

		System.out.println("============= dbDownload ===============");
		
//		fileNm = new String(fileNm.getBytes("ISO8859-1"),"UTF-8");
		fileNm= URLEncoder.encode(fileNm, "UTF-8"); 
		response.setContentType("application/unknown;");
		response.setHeader("Content-Disposition", "attachment;filename=" + fileNm + ";");

        BufferedInputStream input = null;

	    Connection con = null;
	    PreparedStatement ps = null;
	    ResultSet rs = null;

        try{
		    Context ctx = new InitialContext();
		    DataSource ds = (DataSource) ctx.lookup(jdbcJndiName);
		    con = ds.getConnection();

		    StringBuffer sql = new StringBuffer();
		    
		    sql.append("SELECT FILE_CONTENT FROM FRM_FILE_STORE WHERE FILE_ID = ? ");

		    ps = con.prepareStatement(sql.toString());
		    ps.setBigDecimal(1, new BigDecimal(fileId));
		    rs = ps.executeQuery();

		    if(rs.next()){

		    	input = new BufferedInputStream(rs.getBinaryStream("file_content"));
		        byte[] buf = new byte[4*1024];
		        int len;
		        while((len = input.read(buf, 0, buf.length)) != -1){
		        	response.getOutputStream().write(buf, 0, len);
		        }
		    }

		    rs.close();
		    ps.close();
		    con.close();

            input.close();
	    }catch(Exception e){
	        e.printStackTrace();
	    }finally{
	    	try{
		        if(ps != null) ps.close();
		        if(con != null) con.close();
		        if(input != null) input.close();
	    	}catch(SQLException se){}
	    }

	}

	/**
	 * @see HttpServlet#doGet(HttpServletRequest request, HttpServletResponse response)
	 */
	protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
		// TODO Auto-generated method stub
		System.out.println("============= doGet ===============");
		doPost(request, response);
	}

	/* (non-Java-doc)
	 * @see javax.servlet.Servlet#init(ServletConfig arg0)
	 */
	public void init(ServletConfig arg0) throws ServletException {
		IConfigurationInfoProvider config = ConfigurationManager.getConfigurationInfoProvider();
		ServerConfig sConfig = ServerConfigFactory.getServerConfig();
		String jdbcJndiPrefix = sConfig.getConfigValue("jdbcJndiPrefix");
		jdbcJndiName = jdbcJndiPrefix+config.getItem("h5prd.jdbc.jndi").getValue();
		dir = config.getItem("dir.fileUploadPath").getValue();
		os_type = config.getItem("os.type").getValue();
	}

}
