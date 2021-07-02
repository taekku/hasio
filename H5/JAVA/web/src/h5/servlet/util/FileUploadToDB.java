package h5.servlet.util;


import com.win.frame.server.ServerConfig;
import com.win.frame.server.ServerConfigFactory;
import org.apache.commons.fileupload.FileItem;
import javax.naming.Context;
import javax.naming.InitialContext;
import javax.sql.DataSource;
import h5.sys.util.Logger;
import java.io.InputStream;
import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.SQLException;

/**
 * 첨부파일을 DB에 저장한다.
 * 
 * @author crystal
 */
public class FileUploadToDB extends AbsFileUpload {
	protected void fileUpload(String fileId, String filePath, FileItem fileItem, String empId, String unitCd) throws Exception {
		System.out.println("fileId : " + fileId);
		System.out.println("filePath : " + filePath);
		System.out.println("fileItem : " + fileItem);
		System.out.println("empId : " + empId);
		System.out.println("unitCd : " + unitCd);
		
		
		Connection con = null;
		PreparedStatement ps = null;
		InputStream is = null;

		ServerConfig conf = ServerConfigFactory.getServerConfig();
		String dbType = conf.getConfigValue("dbType");
		String dbVersion = conf.getConfigValue("dbVersion");

		try {
			StringBuffer sql = new StringBuffer();
			Context ctx = new InitialContext();
			DataSource ds = (DataSource) ctx.lookup(jdbcJndiName);
			con = ds.getConnection();
			if ("REM".equals(unitCd)) {
				sql.append("DELETE FROM REM_IMAGE WHERE applicant_id = ? ");
				ps = con.prepareStatement(sql.toString());
				ps.setBigDecimal(1, new BigDecimal(empId));
				ps.executeUpdate();

				ps.close();

				if ("oracle".equals(dbType)) {
					sql.append(" INSERT INTO REM_IMAGE ( APPLICANT_ID, IMAGE, MOD_USER_ID, MOD_DATE ) "
							 + " VALUES (?, ?, ?, SYSDATE) ");
				} else {
					sql.append(" INSERT INTO REM_IMAGE ( APPLICANT_ID, IMAGE, MOD_USER_ID, MOD_DATE ) "
							 + " VALUES (?, ?, ?, GETDATE()) ");
				}

				sql = new StringBuffer();

				ps = con.prepareStatement(sql.toString());
				ps.setBigDecimal(1, new BigDecimal(empId));
				ps.setBigDecimal(3, new BigDecimal(empId));

				is = fileItem.getInputStream();
				ps.setBinaryStream(2, is, (int) fileItem.getSize());

				ps.executeUpdate();

				ps.close();
			} else if ("REM_PEOPLE".equals(unitCd)) {
				String fileTypeCd = getParamMap("file_type_cd");
				/** 기존 이미지 삭제 **/
				sql = new StringBuffer();

				if ("oracle".equals(dbType)) {
					sql.append(" INSERT INTO REM_FILE_UPLOAD ( REM_FILE_UPLOAD_ID, APPLICANT_ID, FILE_TYPE_CD, FILE_NAME, FILE_PATH_ID, MOD_USER_ID, MOD_DATE) "
							 + " VALUES ( S_REM_SEQUENCE.NEXTVAL, ?, ?, ?, ?, ?, SYSDATE)");
				} else {
					if ("2012".equals(dbVersion)) { // mssql 2012버전인 경우
						sql.append(" INSERT INTO REM_FILE_UPLOAD ( REM_FILE_UPLOAD_ID, APPLICANT_ID, FILE_TYPE_CD, FILE_NAME, FILE_PATH_ID, MOD_USER_ID, MOD_DATE ) "
								 + " VALUES ( NEXT VALUE FOR dbo.S_FRM_SEQUENCE, ?, ?, ?, ?, ?, GETDATE() )");
					} else {
						sql.append(" INSERT INTO REM_FILE_UPLOAD ( REM_FILE_UPLOAD_ID, APPLICANT_ID, FILE_TYPE_CD, FILE_NAME, FILE_PATH_ID, MOD_USER_ID, MOD_DATE ) "
								 + " VALUES ( dbo.S_FRM_SEQUENCE(), ?, ?, ?, ?, ?, GETDATE() )");
					}
				}

				ps = con.prepareStatement(sql.toString());
				ps.setBigDecimal(1, new BigDecimal(empId));
				ps.setString(2, fileTypeCd);

				String fileName = fileItem.getName();
				int index = fileName.lastIndexOf("\\");
				if (index == -1)
					index = fileName.lastIndexOf("/");
				fileName = fileName.substring(index + 1);

				ps.setString(3, fileName);
				ps.setBigDecimal(4, new BigDecimal(fileId));
				ps.setBigDecimal(5, new BigDecimal(empId));
				ps.executeUpdate();

				ps.close();
				ps = null;
				sql = null;

				sql = new StringBuffer();

				if ("oracle".equals(dbType)) {
					sql.append(" INSERT INTO FRM_FILE_STORE ( FILE_ID, FILE_CONTENT, MOD_USER_ID, MOD_DATE, TZ_CD, TZ_DATE ) "
							 + " VALUES (?, ?, ?, SYSDATE, 'KST', SYSDATE)");
				} else {
					sql.append(" INSERT INTO FRM_FILE_STORE ( FILE_ID, FILE_CONTENT, MOD_USER_ID, MOD_DATE, TZ_CD, TZ_DATE ) "
							 + " VALUES (?, ?, ?, GETDATE(), 'KST', GETDATE())");
				}

				ps = con.prepareStatement(sql.toString());
				ps.setBigDecimal(1, new BigDecimal(fileId));
				ps.setBigDecimal(3, new BigDecimal(empId));

				is = fileItem.getInputStream();
				ps.setBinaryStream(2, is, (int) fileItem.getSize());
				ps.executeUpdate();

				ps.close();
			} else if ("PHM01".equals(unitCd)) {
				/** 기존 이미지 삭제 **/
				sql.append("DELETE FROM PHM_IMAGE WHERE EMP_ID = ? AND TYPE_CD = 'P' ");
				ps = con.prepareStatement(sql.toString());
				ps.setBigDecimal(1, new BigDecimal(empId));
				ps.executeUpdate();

				ps.close();

				sql = new StringBuffer();

				if ("oracle".equals(dbType)) {
					sql.append(" INSERT INTO PHM_IMAGE ( PHM_IMAGE_ID, EMP_ID, PERSON_ID, TYPE_CD, IMG_DATA, MOD_USER_ID, MOD_DATE, TZ_CD, TZ_DATE ) "
							 + " VALUES ( S_PHM_SEQUENCE.NEXTVAL, ?, ?, 'P', ?, ?, SYSDATE,'KST',SYSDATE )");
				} else {
					if ("2012".equals(dbVersion)) { // mssql 2012버전인 경우
						sql.append(" INSERT INTO PHM_IMAGE ( PHM_IMAGE_ID, EMP_ID, PERSON_ID, TYPE_CD, IMG_DATA, MOD_USER_ID, MOD_DATE, TZ_CD, TZ_DATE ) "
								 + " VALUES ( NEXT VALUE FOR dbo.S_PHM_SEQUENCE, ?, ?, 'P', ?, ?, GETDATE(),'KST',GETDATE())");
					} else {
						sql.append(" INSERT INTO PHM_IMAGE ( PHM_IMAGE_ID, EMP_ID, PERSON_ID, TYPE_CD, IMG_DATA, MOD_USER_ID, MOD_DATE, TZ_CD, TZ_DATE ) "
								 + " VALUES ( dbo.S_PHM_SEQUENCE(), ?, ?, 'P', ?, ?, GETDATE(),'KST',GETDATE())");
					}
				}

				ps = con.prepareStatement(sql.toString());
				ps.setBigDecimal(1, new BigDecimal(empId));
				ps.setBigDecimal(2, new BigDecimal(empId));
				ps.setBigDecimal(4, new BigDecimal(empId));

				is = fileItem.getInputStream();
				ps.setBinaryStream(3, is, (int) fileItem.getSize());
				ps.executeUpdate();

				ps.close();
			} else if ("PHM02".equals(unitCd)) {
				sql.append("DELETE FROM PHM_IMAGE WHERE EMP_ID = ? AND TYPE_CD = 'A' ");
				ps = con.prepareStatement(sql.toString());
				ps.setBigDecimal(1, new BigDecimal(empId));
				ps.executeUpdate();

				ps.close();

				sql = new StringBuffer();
				
				if ("oracle".equals(dbType)) {
					sql.append(" INSERT INTO PHM_IMAGE ( PHM_IMAGE_ID, EMP_ID, PERSON_ID, TYPE_CD, IMG_DATA, MOD_USER_ID, MOD_DATE, TZ_CD, TZ_DATE ) "
							 + " VALUES ( S_PHM_SEQUENCE.NEXTVAL, ?, ?, 'A', ?, ?, SYSDATE, 'KST', SYSDATE )");
				} else {
					if ("2012".equals(dbVersion)) { // mssql 2012버전인 경우
						sql.append(" INSERT INTO PHM_IMAGE ( PHM_IMAGE_ID, EMP_ID, PERSON_ID, TYPE_CD, IMG_DATA, MOD_USER_ID, MOD_DATE, TZ_CD, TZ_DATE ) "
								 + " VALUES ( NEXT VALUE FOR dbo.S_PHM_SEQUENCE, ?, ?, 'A', ?, ?, GETDATE(), 'KST', GETDATE())");
					} else {
						sql.append(" INSERT INTO PHM_IMAGE ( PHM_IMAGE_ID, EMP_ID, PERSON_ID, TYPE_CD, IMG_DATA, MOD_USER_ID, MOD_DATE, TZ_CD, TZ_DATE ) "
								 + " VALUES ( dbo.S_PHM_SEQUENCE(), ?, ?, 'A', ?, ?, GETDATE(), 'KST', GETDATE())");
					}
				}
				
				ps = con.prepareStatement(sql.toString());
				ps.setBigDecimal(1, new BigDecimal(empId));
				ps.setBigDecimal(2, new BigDecimal(empId));
				ps.setBigDecimal(4, new BigDecimal(empId));
				is = fileItem.getInputStream();
				ps.setBinaryStream(3, is, (int) fileItem.getSize());
				ps.executeUpdate();

				ps.close();
			} else { 
				if ("oracle".equals(dbType)) {
					sql.append(" INSERT INTO FRM_FILE_STORE ( FILE_ID, FILE_CONTENT, MOD_USER_ID, MOD_DATE, TZ_CD, TZ_DATE ) "
							 + " VALUES (?, ?, ?, SYSDATE,'KST',SYSDATE)");
				} else {
					sql.append(" INSERT INTO FRM_FILE_STORE ( FILE_ID, FILE_CONTENT, MOD_USER_ID, MOD_DATE, TZ_CD, TZ_DATE ) "
							 + " VALUES (?, ?, ?, GETDATE(),'KST',GETDATE())");
				}

				ps = con.prepareStatement(sql.toString());
				ps.setBigDecimal(1, new BigDecimal(fileId));
				ps.setBigDecimal(3, new BigDecimal(empId));

				is = fileItem.getInputStream();
				ps.setBinaryStream(2, is, (int) fileItem.getSize());
				ps.executeUpdate();

				ps.close();
			}

			if (is != null) {
				is.close();
				is = null;
			}

			ps.close();

		} catch (Exception e) {
			e.printStackTrace();
			throw e;
		} finally {
			try {
				if (is != null)
					is.close();
				if (ps != null)
					ps.close();
				if (con != null)
					con.close();
			} catch (SQLException se) {
			}
		}
	}
}
