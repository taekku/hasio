package h5.servlet.util;

import h5.security.SeedCipher;
import h5.sys.util.Logger;

import java.io.InputStream;
import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.SQLException;

import javax.naming.Context;
import javax.naming.InitialContext;
import javax.servlet.http.HttpServletRequest;
import javax.sql.DataSource;

import org.apache.commons.fileupload.FileItem;

import com.win.frame.server.ServerConfig;
import com.win.frame.server.ServerConfigFactory;
 
/**
 * 첨부파일을 DB에 저장한다.
 * 
 * @author crystal
 */
public class FileUploadToDB_PEH extends AbsFileUpload_PEH {
	protected void fileUpload(String noMember, String filePath, FileItem fileItem, String unitCd, String gbQuery, String empId) throws Exception {
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
			int ei = Integer.parseInt(empId);
			if ("PEH0022_01".equals(unitCd)) {
				if("modi".equals(gbQuery)){
						int noMemberInt = Integer.parseInt(noMember);
	
						sql = new StringBuffer();
						
						sql.append(" UPDATE PEH_REG_MEMBER SET IMG_DATA = ? WHERE REG_MEMBER = ?");
						
						ps = con.prepareStatement(sql.toString());
						ps.setInt(2, noMemberInt);
						is = fileItem.getInputStream();
						ps.setBinaryStream(1, is, (int) fileItem.getSize());
					}
					ps.executeUpdate();
					ps.close();
			}else if("PEH0210_04".equals(unitCd)){
				int noMemberInt = Integer.parseInt(noMember);

				sql = new StringBuffer();
				
				sql.append(" UPDATE PEH_ORG_MEMBER SET IMG_DATA = ? WHERE NO_MEMBER = ?");
				
				ps = con.prepareStatement(sql.toString());
				ps.setInt(2, noMemberInt);
				is = fileItem.getInputStream();
				ps.setBinaryStream(1, is, (int) fileItem.getSize());
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
