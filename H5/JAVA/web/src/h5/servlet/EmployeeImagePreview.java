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
 */
public class EmployeeImagePreview extends HttpServlet {
	
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
	 *
	 */
	public static final String IMAGE_TYPE_QRCODE = "Q";

	// 이미지 입력을 받아 올 스트림
	BufferedInputStream input = null;
	InputStream input_db = null;

	Connection con = null;
	PreparedStatement ps = null;
	ResultSet rs = null;
	
	@Override
	protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException { 
		// 옵션 변수 초기화
		String imageTableName = getInitParameter(PARAM_TABLE_NAME);
		String imageColumnName = getInitParameter(PARAM_IMAGE_COLUMN_NAME) == null ? "img_data":getInitParameter(PARAM_IMAGE_COLUMN_NAME);
		String imagePath = getInitParameter(PARAM_IMAGE_PATH) == null ? getServletContext().getRealPath("/employeeImage/"):getInitParameter(PARAM_IMAGE_PATH);
		String useDBImageString = getInitParameter(OPTION_USE_IMAGE_FROM_DB)==null ? "false" : getInitParameter(OPTION_USE_IMAGE_FROM_DB);
		// 이미지 타입
		String imageType = request.getParameter("image_type");
		String applId =  request.getParameter("appl_id");


		
		// 이미지를 가져올 방법을 분기한다.
		// 각 방법별로 이미지를 가져온다.
		
		if("Q".equalsIgnoreCase(imageType)){ // QR 코드인 경우 따로 처리함.
			//2018-05-09 김정현 수정 
			// QR코드 더이상 지원하지 않음.
			/*
			QRCodeWriter qrWriter = new QRCodeWriter();
			String qrText = getQrText(request.getParameter("emp_no"));
			System.out.println(qrText.toString().length());
			try {
				BitMatrix bm = qrWriter.encode(new String(qrText.getBytes("UTF-8"),"ISO-8859-1"), BarcodeFormat.QR_CODE, 200, 200);
				ServletOutputStream sos = response.getOutputStream();
				MatrixToImageWriter.writeToStream(bm, "png", sos);
				sos.flush();
				sos.close();
			} catch (WriterException e) {
				e.printStackTrace();
				writeNoImage(imageType,response);
			}
			*/
		}else{
			//System.out.println("asdfasdfasdf");

			if("true".equals(useDBImageString)){
				System.out.println("db방식으로");
				input_db = getImageFromDB(imageType,request, imageTableName, imageColumnName,applId);

			}else{
				input_db = getImageFromFile(imageType,request,imagePath);
			}

			input = new BufferedInputStream(input_db);

			try{
				// 이미지를 아웃 스트림으로 출력한다.
				byte[] buf = new byte[4*1024];
		        int len = 0;
				System.out.println("while 들어가기 전 ");
		        while((len = input.read(buf, 0, buf.length)) != -1){
		        	response.getOutputStream().write(buf, 0, len);
		        }
			}catch(Exception e){
				e.printStackTrace();
			}finally{
				if(input_db != null){
					input_db.close();
					input_db = null;
				}
				if(input != null){
					input.close();
					input = null;
				}
				try{
					if(rs != null) rs.close();
					if(ps != null) ps.close();
					if(con != null) con.close();
				}catch(Exception se){
				}
			}
		}
	}

	private String getQrText(String empNo) {
		
		Connection con = null;
	    PreparedStatement ps = null;
	    ResultSet rs = null;

        try{
        	IConfigurationInfoProvider config = ConfigurationManager.getConfigurationInfoProvider();
    		ServerConfig sConfig = ServerConfigFactory.getServerConfig();
    		String jdbcJndiPrefix = sConfig.getConfigValue("jdbcJndiPrefix");
    		String jdbcJndiName = jdbcJndiPrefix+config.getItem("h5prd.jdbc.jndi").getValue();
    		String dbType = sConfig.getConfigValue("dbType");
    		
		    Context ctx = new InitialContext();
		    DataSource ds = (DataSource) ctx.lookup(jdbcJndiName);
		    con = ds.getConnection();
		    
		    String sql;
		    if("oracle".equals(dbType)) {
			    sql =  "SELECT EMP_NM"+
		    		   "     , F_PHM_EMAIL(A.COMPANY_CD, A.LOCALE_CD, A.EMP_ID, '1', SYSDATE) as email"+
				       "     , F_FRM_ORM_ORG_NM(A.ORG_ID, A.LOCALE_CD, SYSDATE, '11') as org_nm"+
				       "     , F_FRM_CODE_NM(A.COMPANY_CD, A.LOCALE_CD, 'PHM_POS_GRD_CD', A.POS_GRD_CD, SYSDATE,'1') as title"+
				       "     , F_PHM_PHONE(A.COMPANY_CD, A.LOCALE_CD, A.EMP_ID, '20',SYSDATE) as phone_work"+
				       "     , F_PHM_PHONE(A.COMPANY_CD, A.LOCALE_CD, A.EMP_ID, '30',SYSDATE) as phone_cell"+
				       "  FROM VI_FRM_PHM_EMP A"+
				       " WHERE EMP_NO = ?";
		    } else {
			    sql =  "SELECT EMP_NM"+
		    		   "     , DBO.F_PHM_EMAIL(A.COMPANY_CD, A.LOCALE_CD, A.EMP_ID, '1', GETDATE()) as email"+
				       "     , DBO.F_FRM_ORM_ORG_NM(A.ORG_ID, A.LOCALE_CD, GETDATE(), '11') as org_nm"+
				       "     , DBO.F_FRM_CODE_NM(A.COMPANY_CD, A.LOCALE_CD, 'PHM_POS_GRD_CD', A.POS_GRD_CD, GETDATE(),'1') as title"+
				       "     , DBO.F_PHM_PHONE(A.COMPANY_CD, A.LOCALE_CD, A.EMP_ID, '20',GETDATE()) as phone_work"+
				       "     , DBO.F_PHM_PHONE(A.COMPANY_CD, A.LOCALE_CD, A.EMP_ID, '30',GETDATE()) as phone_cell"+
				       "  FROM VI_FRM_PHM_EMP A"+
				       " WHERE EMP_NO = ?";
		    }
		    
		    ps = con.prepareStatement(sql);
		    ps.setString(1, empNo);
		    
		    rs = ps.executeQuery();

		    if(rs.next()){
				StringBuffer sb = new StringBuffer();
				sb.append("BEGIN:VCARD\r\n");
				sb.append("VERSION:4.0\r\n");
				sb.append("N:;"+rs.getString("emp_nm")+"\r\n");
				sb.append("FN:"+rs.getString("emp_nm")+"\r\n");
				sb.append("ORG:"+rs.getString("org_nm")+"\r\n");
				sb.append("TITLE:"+rs.getString("title")+"\r\n");
				
				sb.append("TEL;TYPE=CELL;VALUE=uri:"+rs.getString("phone_cell")+"\r\n");
				sb.append("TEL;TYPE=WORK;VALUE=uri:"+rs.getString("phone_work")+"\r\n");
				sb.append("EMAIL:"+rs.getString("email")+"\r\n");

				sb.append("END:VCARD");
				
				return sb.toString();
		    	
		    }

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
		
	    return null;

	}

	/**
	 * 이미지 없음에 대한 이미지를 출력한다.
	 * @param imageType
	 * @param response
	 */
	private void writeNoImage(String imageType, HttpServletResponse response) {
		try {
			response.sendRedirect("/noImage.png");
		} catch (IOException e) {
			e.printStackTrace();
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
	 */
	protected InputStream getImageFromDB(String imageType, HttpServletRequest request, String imageTabelName, String imageColumnName,String applId){
		Connection con = null;
	    PreparedStatement ps = null;
	    ResultSet rs = null;

		try{
        	IConfigurationInfoProvider config = ConfigurationManager.getConfigurationInfoProvider();
    		ServerConfig sConfig = ServerConfigFactory.getServerConfig();
    		String jdbcJndiPrefix = sConfig.getConfigValue("jdbcJndiPrefix");
    		String jdbcJndiName = jdbcJndiPrefix+config.getItem("h5prd.jdbc.jndi").getValue();    		
    		String dbType = sConfig.getConfigValue("dbType");
    		
		    Context ctx = new InitialContext();
		    DataSource ds = (DataSource) ctx.lookup(jdbcJndiName);
		    con = ds.getConnection();
		    
    		String unitCd = request.getParameter("unitCd");
    		if("REM".equals(unitCd)){
    			String sql = "SELECT image as img_data FROM REM_image WHERE applicant_id = ?";
    			System.out.println("EmployeeImageDownload.java REM line sql ====>"+sql);
			    ps = con.prepareStatement(sql);			    
			    ps.setString(1, request.getParameter("emp_id"));
			    rs = ps.executeQuery();
				if(rs.next()){
					input = new BufferedInputStream(rs.getBinaryStream(imageColumnName));
					System.out.println("EmployeeImageDownload.java REM select end");
				} else {
					input_db = new FileInputStream(new File(this.getServletContext().getRealPath("/noimage.png")));
				}
    		} else {
	    		String sql = "SELECT " + imageColumnName + " FROM " + imageTabelName + " WHERE appl_id = ?";
	    		
			    ps = con.prepareStatement(sql);
			    //ps.setString(1, request.getParameter("emp_id"));
			    ps.setString(1, applId);
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
    		}

    		//input = new BufferedInputStream(input_db);

			//rs.close();
			//ps.close();
			//con.close();
			System.out.println("input : " + input);
			
			return input_db;
		}catch(Exception e){
			e.printStackTrace();
			return null;
		}
	}

	/**
	 * 이미지 정보를 파일 시스템으로부터 가져온다.
	 * @param imageType 이미지 타입
	 * @param request 웹 요청
	 * @param imagePath 이미지 ROOT 경로 (절대경로)
	 * @return
	 */
	protected InputStream getImageFromFile(String imageType, HttpServletRequest request, String imagePath){
		if(!imagePath.endsWith("/"))
			imagePath = imagePath +"/";
		String fullFileName =  imagePath + imageType+"/"+request.getParameter("emp_no")+".jpg";
		File imageFile = new File(fullFileName);
		if(!imageFile.exists())
			imageFile = new File(this.getServletContext().getRealPath("/noimage.png"));
		
		try {
			return new FileInputStream(imageFile);
		} catch (FileNotFoundException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
			return null;
		}
	}
	
}
