package h5.servlet;

import java.io.BufferedInputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;

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

/**
 * 직원 이미지를 다운로드 하여 아웃풋 스트림으로 전송하는 클래스.
 * WEB.XML에 기술하는 여러 옵션을 가진다.
 * 직원정보 조회하는 쿼리를 수정해야 한다.
 * F_FRM_CONST_VALUE_C( A.LOCALE_CD, 'PHM', 'SERVER' ) || 'upload/phm/' || A.EMP_NO || '.jpg' AS EMP_IMG
 * '218.236.10.136:8088/employeeImage?emp_id=123&image_type=P' AS EMP_IMG
 *
 */
public class EmployeeImageDownload extends HttpServlet {

	
	/**
	 * 이미지를 데이터베이스로부터 가져와서 사용할 것인지를 체크하는 값, true/false로 기술된다
	 */
	public static final String OPTION_USE_IMAGE_FROM_DB = "useDBImage";
	
	/**
	 * 이미지 테이블 이름
	 */
	public static final String PARAM_TABLE_NAME = "imageTableName"; 
	
	/**
	 * 이미지 테이블의 이미지 컬럼 이름
	 */
	public static final String PARAM_IMAGE_COLUMN_NAME = "imageColumnName";
	
	/**
	 * 이미지를 파일경로로 사용할 경우, 이미지 경로 (이미지의 ROOT 경로)
	 */
	public static final String PARAM_IMAGE_PATH = "imagePath";
	
	
	/**
	 * 이미지 유형 - 사진
	 */
	public static final String IMAGE_TYPE_PICTURE = "P";
	
	/**
	 * 이미지 유형 - 서명
	 */
	public static final String IMAGE_TYPE_SIGNATURE = "S";
	
	/**
	 * 이미지 유형 - QR 코드
	 */
	public static final String IMAGE_TYPE_QRCODE = "Q";
	
	@Override
	protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
		// 옵션 변수 초기화
		String imageColumnName = getInitParameter(PARAM_IMAGE_COLUMN_NAME) == null ? "img_data":getInitParameter(PARAM_IMAGE_COLUMN_NAME);
		// 이미지 타입
		String imageType = request.getParameter("image_type");
		String imageTable = request.getParameter("image_table");
		
		BufferedInputStream input = null;
		
		Connection con = null;
	    PreparedStatement ps = null;
	    ResultSet rs = null;
		InputStream input_db = null;
		
		try{
			IConfigurationInfoProvider config = ConfigurationManager.getConfigurationInfoProvider();
    		ServerConfig sConfig = ServerConfigFactory.getServerConfig();
    		String jdbcJndiPrefix = sConfig.getConfigValue("jdbcJndiPrefix");
    		String jdbcJndiName = jdbcJndiPrefix+config.getItem("h5prd.jdbc.jndi").getValue();    		
    		String dbType = sConfig.getConfigValue("dbType");
    		
		    Context ctx = new InitialContext();
		    DataSource ds = (DataSource) ctx.lookup(jdbcJndiName);
		    con = ds.getConnection();
		    
		    if("PEH".equals(request.getParameter("gb_query"))){
	    		if("SUCCESSION".equals(request.getParameter("table_id"))){//승계후보자관리
	    			String sql = "SELECT S_IMAGE AS IMG_DATA FROM " + "PEH_SUCCESSION_MANAGE" + " WHERE NO_SUC = ?";
				    ps = con.prepareStatement(sql);
				    ps.setString(1, request.getParameter("no_suc"));
				    
	    		}else if("REG".equals(request.getParameter("table_id"))){//등기임원관리
	    			String sql = "SELECT " + imageColumnName + " FROM " + "PEH_REG_MEMBER" + " WHERE reg_member = ?";
				    ps = con.prepareStatement(sql);
				    ps.setString(1, request.getParameter("reg_member"));
	    		}
		    }else{
		    	imageTable = imageTable != null ? imageTable + "_IMAGE" : "PHM_IMAGE" ; 
		    	
	    		String sql = "SELECT " + imageColumnName + " FROM " + imageTable + " WHERE type_cd = ? AND emp_id = ?";
	    		
			    ps = con.prepareStatement(sql);
			    ps.setString(1, imageType);
			    ps.setString(2, request.getParameter("emp_id"));
		    }

		    rs = ps.executeQuery();
			if(rs.next()){
				if (dbType.equals("oracle")) {
					input_db = new BufferedInputStream(rs.getBinaryStream(imageColumnName));
				} else {
					input_db = new BufferedInputStream(rs.getBlob(imageColumnName).getBinaryStream());
				}
			} else {
				input_db = new FileInputStream(new File(this.getServletContext().getRealPath("/noimage.png")));
			}
			
			input = new BufferedInputStream(input_db);
			
			response.setContentType("image/jpeg");
			
			// 이미지를 아웃 스트림으로 출력한다.
			byte[] buf = new byte[4*1024];
	        int len;
	        while((len = input.read(buf, 0, buf.length)) != -1){
	        	response.getOutputStream().write(buf, 0, len);
	        }
	        
	        
	        
		}catch(Exception e){
			e.printStackTrace();
		}finally{
		
			if(input != null){
				input.close();
				input = null;
			}
			
			if(input_db != null){
				input_db.close();
				input_db = null;
			}
			
			try{
				if(rs != null) rs.close();
				if(ps != null) ps.close();
				if(con != null) con.close();
			}catch(Exception se){
			}
		}
	}


	@Override
	protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
		doGet(request,response);

	}
	
}
