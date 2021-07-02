package h5.servlet.util;

import java.io.IOException;
import java.io.InputStream;
import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

import org.apache.commons.fileupload.FileItem;

public class DWFileUtil {

	public Connection conn;
	
	public String uploadFile( FileItem fileItem , String emp_id ) throws SQLException, IOException {
		
		String fileId = getFileId();
		String filePathId = getFileId();
		
		createFrmFileStore( emp_id , fileId , fileItem );
		createFrmFileInfo( filePathId ,  fileId , fileItem , emp_id);
		
		return fileId;
	}

	private void createFrmFileInfo( String filePathId , String fileId, FileItem fileItem, String emp_id) throws SQLException {
		// TODO Auto-generated method stub
		
		StringBuffer sql = new StringBuffer();
		PreparedStatement ps = null;
	
		sql.append("INSERT INTO FRM_FILE_INFO (FILE_ID,FILE_PATH_ID,FILE_NM,PRINT_FILE_NM,FILE_SIZE,MOD_USER_ID,MOD_DATE,TZ_CD,TZ_DATE ) ");
		sql.append("VALUES ( ?, ?, ?, ?, ?, ?, dbo.XF_SYSDATE(0), 'KST', dbo.XF_SYSDATE(0) )");

		ps = conn.prepareStatement(sql.toString());
		ps.setBigDecimal(1, new BigDecimal(fileId));
		ps.setBigDecimal(2, new BigDecimal(filePathId));
		ps.setString(3, fileItem.getName());
		ps.setString(4, fileItem.getName());
		ps.setString(5, getFileSize(fileItem.getSize()));
		ps.setBigDecimal(6, new BigDecimal(emp_id));
		ps.executeUpdate();
		ps.close();
	}

	private String getFileId() throws SQLException {
		// TODO Auto-generated method stub
		StringBuffer sql = new StringBuffer();
		PreparedStatement ps = null;
		ResultSet rs = null;
		
		String fileId = null;
		sql = new StringBuffer();
		sql.append("SELECT NEXT VALUE FOR dbo.S_FRM_SEQUENCE as file_id");

		ps = conn.prepareStatement(sql.toString());
		rs = ps.executeQuery();
		if (rs.next()) {
			fileId = rs.getString("file_id");
		}
		rs.close();
		ps.close();
		
		return fileId;
	}

	private void createFrmFileStore( String emp_id , String fileId, FileItem fileItem) throws SQLException, IOException {
		// TODO Auto-generated method stub
		
		StringBuffer sql = new StringBuffer();
		InputStream is = null;
		PreparedStatement ps = null;
		sql.append(" INSERT INTO FRM_FILE_STORE ( FILE_ID, FILE_CONTENT, MOD_USER_ID, MOD_DATE, TZ_CD, TZ_DATE ) "
				 + " VALUES (?, ?, ?, GETDATE(),'KST',GETDATE())");

		ps = conn.prepareStatement(sql.toString());
		ps.setBigDecimal(1, new BigDecimal(fileId));
		ps.setBigDecimal(3, new BigDecimal(emp_id));

		is = fileItem.getInputStream();
		ps.setBinaryStream(2, is, (int) fileItem.getSize());
		ps.executeUpdate();

		ps.close();
		
		
	}
	
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
}
