package h5.servlet.util;

import com.win.commonlib.jrlib.jrTools;
import com.win.frame.server.ServerConfig;
import com.win.frame.server.ServerConfigFactory;
import com.win.rf.config.ConfigurationManager;
import com.win.rf.config.IConfigurationInfoProvider;

import h5.security.SeedCipher;
import h5.sys.registry.RegistryItem;
import h5.sys.registry.SystemRegistry;
import h5.sys.util.Logger;

import org.apache.commons.fileupload.FileItem;

import javax.naming.Context;
import javax.naming.InitialContext;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpSession;
import javax.sql.DataSource;

import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
 
/**
 * 첨부파일을 파일 혹은 DB로 저장한다.
 * @author crystal
 */
public abstract class AbsFileUpload_PEH {
	// 클라이언트 프로그램에서 전달하는 데이터가 들어갈 필드 이름
	static final String PARAM_SESSION_ID   = "session_id";
	static final String PARAM_FILE_PATH    = "file_path";
	static final String PARAM_FILE_PATH_ID = "file_path_id";
	static final String PARAM_FILE_ID      = "file_id";
	static final String PARAM_EMP_ID       = "emp_id";
	static final String PARAM_UNIT_PATH    = "unit_dir";
	// fileView.jsp로 forward될 때 보이는 상태를 정해주기 위한 값(넘겨받은 값을 그대로 사용함)
	static final String PARAM_EDIT_MODE    = "editable";
	
	String jdbcJndiName = "";
	
	HashMap<String, String> paramMap = null;
	
	public String getParamMap(String key) {
		String returnVal = null;
		if(paramMap != null && paramMap.containsKey(key)) {
			returnVal = paramMap.get(key);
		}
		
		return returnVal;


	}

	public void setParamMap(HashMap<String, String> paramMap) {
		this.paramMap = paramMap;
	}

	/**
	 * 기본정보를 FRM_FILE_PATH(파일경로:사원ID,파일경로), FRM_FILE_INFO(파일정보:파일명,파일사이즈)에 저장
	 */
	public void addFileInfo(HttpServletRequest request, List list) throws Exception {
		String unitDir      = ""; // 단위업무
		String fileId       = ""; // 파일ID  
		String sessionId    = ""; // 세션ID  
		String fileLen      = ""; // 파일크기
		String allowExt     = ""; // 허용된 확장자
		String warPath      = ""; //C\:/H5Ent/H5EntPkg.ear/WebApplication.war
		String fileType     = ""; // 파일의 종류(IMG), 이미지 파일의 크기를 제약하기 위해.
		String unitCd       = ""; // 단위업무
		String gbQuery      = "";
		String noMember      = "";
		
		String allowImgExt	= "";
		
		StringBuffer sql  = null;
		long fileMaxSize  = 1024 * 1024; // 파일 최대 크기, MB로 변환하기 위해.
		long imageMaxSize = 1024; // 이미지 파일 최대 크기, KB로 변환하기 위해

		Connection con = null;
		PreparedStatement ps = null;
		ResultSet rs = null;

		// 레지스트리정보(FILEMAXSIZE 파일크기)를 가져온다.
		RegistryItem registryItem = SystemRegistry.getRegistryItem("GLOBAL_ATTR/SYSTEM_ENVIRONMENTS/NODES/FILESTORE/FILEMAXSIZE");
		if(registryItem != null) fileMaxSize = fileMaxSize * new Long(registryItem.getValue());

		// 레지스트리정보(FILEMAXSIZE 파일크기)를 가져온다.
		registryItem = SystemRegistry.getRegistryItem("GLOBAL_ATTR/SYSTEM_ENVIRONMENTS/NODES/FILESTORE/IMAGEMAXSIZE");
		if(registryItem != null) imageMaxSize = imageMaxSize * new Long(registryItem.getValue());
		
		// 설정파일(h5_runtime_config.properties)로부터 업로드 경로를 얻어낸다.
		ServerConfig sConfig = ServerConfigFactory.getServerConfig();
		IConfigurationInfoProvider config = ConfigurationManager.getConfigurationInfoProvider();
		warPath = config.getItem("dir.fileUploadPath").getValue();

		// 레지스트리 정보(TYPE-DB/FILE, EXTENSION-JPG,HWP,XLS,XLSX,DOC,DOCX,PPT,PPTX,PDF)를 가져온다 
		registryItem = SystemRegistry.getRegistryItem("GLOBAL_ATTR/SYSTEM_ENVIRONMENTS/NODES/FILESTORE/EXTENSION");
		if(registryItem != null) allowExt = registryItem.getValue();
		
		registryItem = SystemRegistry.getRegistryItem("GLOBAL_ATTR/SYSTEM_ENVIRONMENTS/NODES/FILESTORE/IMG_EXT");
		if(registryItem != null) allowImgExt = registryItem.getValue();
		

		try {
			// Request 객체로부터 변수값 읽어오기
			Iterator itemItor = list.iterator();
			while (itemItor.hasNext()) {
				FileItem item = (FileItem) itemItor.next();

				if (item.isFormField()) {
					if (PARAM_SESSION_ID.equals(item.getFieldName())) {
						sessionId = item.getString();
					}else if (PARAM_FILE_ID.equals(item.getFieldName())) {
						fileId = item.getString();
						request.setAttribute("file_id", fileId);
					}  else if (PARAM_UNIT_PATH.equals(item.getFieldName())) {
						unitDir = item.getString();
					} else if (PARAM_EDIT_MODE.equals(item.getFieldName())) {
						request.setAttribute(PARAM_EDIT_MODE, item.getString());
					} else if ("unit_cd".equals(item.getFieldName())){
						unitCd = item.getString();
					} else if ("file_type".equals(item.getFieldName())){
						fileType = item.getString();
					} else if ("gb_query".equals(item.getFieldName())){
						gbQuery = item.getString();
					}else if ("no_member".equals(item.getFieldName())){
						noMember = item.getString();
					}
				}
			}
			String emp_id = "";
			if(sessionId == null || "".equals(sessionId)){
				// 효정추가 세션 및 권한체크
				HttpSession sessionAuth = request.getSession(false);
				sessionId = (String)sessionAuth.getAttribute("session_id");
				emp_id = (String)sessionAuth.getAttribute("session_emp_id");
			}
			
			// emp_id 복호화
			SeedCipher sc = new SeedCipher();

			
			
			emp_id = sc.decryptAsString(emp_id, sessionId.getBytes(), "UTF-8");  // 복호화 해서 문자로 받기
			
			// JNDI 이름을 얻는다.
			String jdbcJndiPrefix = sConfig.getConfigValue("jdbcJndiPrefix");
			jdbcJndiName = jdbcJndiPrefix + config.getItem("h5prd.jdbc.jndi").getValue();

			// 데이터베이스 커넥션을 얻는다.
			Context ctx = new InitialContext();
			DataSource ds = (DataSource) ctx.lookup(jdbcJndiName);
			con = ds.getConnection();
			// 리스트에는 파일업로드 폼 객체의 변수와 파일이 담겨있다.
			for (int i = 0, ii = list.size(); i < ii; i++) {

				FileItem fileItem = (FileItem) list.get(i);
				String fileName = fileItem.getName();
				if (fileItem != null && fileName != null && !("".equals(fileName))) { // 파일이면.

					// 파일명과 파일크기를 구한다.
					int index = fileName.lastIndexOf("\\");
					if(index == -1) index = fileName.lastIndexOf("/");
					fileName = fileName.substring(index + 1);
					fileLen = getFileSize(fileItem.getSize());

					if(new Long(fileItem.getSize()) > ("IMG".equals(fileType) ? imageMaxSize : fileMaxSize) ){
						request.setAttribute("retCode", "FAIL!");
						request.setAttribute("retMessage", "파일이 너무 커서 업로드할 수 없습니다.");
						con.close();
						return;
					}

					// �솗�옣�옄瑜� �솗�씤�븳�떎
					String fileExt = fileName.substring(fileName.lastIndexOf(".")+1).toUpperCase();
					if(allowExt.indexOf(fileExt) < 0){
						request.setAttribute("retCode", "FAIL!");
						//request.setAttribute("retMessage", "FRM.ERRFILEEXT");
						request.setAttribute("retMessage", "업로드할 수 없는 파일 유형입니다.");
						con.close();
						return;
					}
					
					if ( "IMG".equals(fileType)){
						if(allowImgExt.indexOf(fileExt) < 0){
							request.setAttribute("retCode", "FAIL!");
							//request.setAttribute("retMessage", "FRM.ERRFILEEXT");
							request.setAttribute("retMessage", "이미지 형식의 파일이 아닙니다.");
							con.close();
							return;
						}
					}

										
					// 파일경로 만들기.		
					String tmpPath = getFilePath();
					if(tmpPath == null || "".equals(tmpPath))
						tmpPath = warPath;										
					
					fileUpload(noMember, tmpPath, fileItem, unitCd , gbQuery , emp_id);
				}
			}

			con.close();
			request.setAttribute("retCode", "SUCCESS!");
			request.setAttribute("retMessage", "업로드에 성공하였습니다.");
		} catch (Exception e) {
			request.setAttribute("retCode", "FAIL!");
			request.setAttribute("retMessage", "관리자에게 문의하십시오.");
			e.printStackTrace();
			throw e;
		} finally {
			try {
				if (rs != null)
					rs.close();
				if (ps != null)
					ps.close();
				if (con != null)
					con.close();
			} catch (SQLException se) {
				se.printStackTrace();
			}
		}
	}

	// 실제 파일을 파일 또는 DB에 저장한다.
	protected abstract void fileUpload(String noMember, String filePath, FileItem fileItem, String unitCd, String gbQuery, String empId) throws Exception;
	
	private String filePath = null;
	public String getFilePath() {
		return this.filePath;
	}
	public void setFilePath(String filePath) {
		this.filePath = filePath;
	}

	// 파일의 크기를 KB, MB로 계산하여 반환한다.
	private String getFileSize(double fileLen) {
		String fileSize = "0";
		if (fileLen >= 1024 * 1024) {
			fileSize = (Math.round(fileLen / (1024 * 1024))) + "MB";
		} else if (fileLen >= 1024) {
			fileSize = (Math.round(fileLen / 1024)) + "KB";
		} else {
			fileSize = Math.ceil(fileLen / 1024) + "KB";
		}
		return fileSize;
	}

	// 신규로 File Path 테이블을 저장하고 ID값을 리턴한다.
	private String newFilePath(String empId, String filePath) {
		StringBuffer sql = new StringBuffer();
		String filePathId = "0";

		Connection con = null;
		PreparedStatement ps = null;
		ResultSet rs = null;

		try {
			Context ctx = new InitialContext();
			DataSource ds = (DataSource) ctx.lookup(jdbcJndiName);
			con = ds.getConnection();
			// Create a PK value
			ServerConfig config = ServerConfigFactory.getServerConfig();
			String dbType = config.getConfigValue("dbType");
			String dbVersion = config.getConfigValue("dbVersion");
			
			if("oracle".equals(dbType)){
				sql.append("SELECT S_FRM_SEQUENCE.NEXTVAL AS pk_id FROM DUAL");
			}else{
				
				if("2012".equals(dbVersion)){ // mssql 2012버전인 경우
					
					sql.append("SELECT NEXT VALUE FOR dbo.S_FRM_SEQUENCE AS pk_id");
				}else{
					
					sql.append("SELECT dbo.S_FRM_SEQUENCE() AS pk_id");
				}
			}
			
			ps = con.prepareStatement(sql.toString());
			rs = ps.executeQuery();
			if (rs.next()) filePathId = rs.getString("pk_id");
			rs.close();
			ps.close();

		} catch (Exception e) {
			e.printStackTrace();
		} finally {
			try {
				if (rs != null)
					rs.close();
				if (ps != null)
					ps.close();
				if (con != null)
					con.close();
			} catch (SQLException se) {
				se.printStackTrace();
			}
		}

		return filePathId;
	}
}
