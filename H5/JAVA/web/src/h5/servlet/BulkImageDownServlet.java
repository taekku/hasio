//package h5.servlet;
//
//import h5.sys.util.DBUtil;
// 
//import java.io.BufferedInputStream;
//import java.io.BufferedOutputStream;
//import java.io.File;
//import java.io.FileInputStream;
//import java.io.FileOutputStream;
//import java.io.IOException;
//import java.math.BigDecimal;
//import java.sql.Connection;
//import java.sql.PreparedStatement;
//import java.sql.ResultSet;
//import java.sql.SQLException;
//
//import javax.servlet.ServletException;
//import javax.servlet.http.HttpServlet;
//import javax.servlet.http.HttpServletRequest;
//import javax.servlet.http.HttpServletResponse;
//
//import net.sf.jazzlib.CRC32;
//import net.sf.jazzlib.ZipEntry;
//import net.sf.jazzlib.ZipOutputStream;
//
//import com.win.rf.config.ConfigurationManager;
//import com.win.rf.config.IConfigurationInfoProvider;
//
//public class BulkImageDownServlet extends HttpServlet {
//
//
//	@Override
//	protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
//		doPost(request,response);
//	}
//
//	@Override
//	protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
//		/******************************/
//		/* 입사 지원자(최종합격자) 사진을 벌크로 내려받는 JSP   */
//		/* 공고ID에 대한 합격자 사진을 공고명.zip 파일로 다운로드 하고, */
//		/* 각 지원자의 사진은 이름_주민번호 앞자리.jpg 로 내려준다. */
//
//			StringBuffer sb = new StringBuffer();
//
//			sb.append("SELECT F_REM_APPLICANT_NM(B.APPLICANT_ID, '01','1') AS APPLICANT_NM, ");
//			sb.append("      SUBSTR(B.APPL_CTZ_NO,1,6) AS CTZ_NO, ");
//			sb.append("       A.IMAGE AS IMG_DATA");
//			sb.append(" FROM REM_IMAGE A, ");
//			sb.append("      REM_APPLICANT B, ");
//			sb.append("      ( ");
//			sb.append("      SELECT CC.APPLICANT_ID, ");
//			sb.append("              STEP_SEQ, ");
//			sb.append("              AA.REM_EVAL_STEP_ID, ");
//			sb.append("              BB.ANNO_ID ");
//			sb.append("         FROM REM_EVAL_STEP AA, ");
//			sb.append("              REM_ANNO_CLASS BB, ");
//			sb.append("              REM_STEP_RESULT CC ");
//			sb.append("        WHERE AA.REM_ANNO_CLASS_ID = BB.REM_ANNO_CLASS_ID ");
//			sb.append("          AND AA.REM_EVAL_STEP_ID = CC.REM_EVAL_STEP_ID ");
//			//sb.append("          AND AA.STEP_SEQ = (SELECT MAX(STEP_SEQ) FROM REM_EVAL_STEP WHERE END_YN = 'Y' AND REM_ANNO_CLASS_ID = AA.REM_ANNO_CLASS_ID) ");
//			sb.append("          AND AA.STEP_SEQ = (SELECT MAX(STEP_SEQ) FROM REM_EVAL_STEP WHERE REM_ANNO_CLASS_ID = AA.REM_ANNO_CLASS_ID) ");
//			sb.append("      )C ");
//			sb.append(" WHERE A.APPLICANT_ID = B.APPLICANT_ID ");
//			sb.append("  AND B.APPLICANT_ID = C.APPLICANT_ID ");
//			sb.append("  AND B.ANNO_ID = C.ANNO_ID ");
//			sb.append("  AND B.ABANDON_YN <> 'Y' ");
//			sb.append("  AND B.ANNO_ID = ? ");
//
//
//			PreparedStatement stmt = null;
//			Connection con = null;
//			ResultSet rset = null;
//
//			FileInputStream fis = null;
//			FileOutputStream fos = null;
//
//			ZipOutputStream zos = null;
//
//			BufferedInputStream input = null;
//			BufferedOutputStream bofs = null;
//
//			try{
//				con = DBUtil.getConnection();
//				stmt = con.prepareStatement(sb.toString());
//				stmt.setBigDecimal(1,new BigDecimal(request.getParameter("anno_id")));
//
//				rset = stmt.executeQuery();
//
//				// 결과를 임시로 저장할 zip 파일을 하나 만든다.
//				String tempZipFileName = ""+ new java.util.Date().getTime()+".zip";
//
//				File zipFile = new File(getServletContext().getRealPath("/temp_images/" +tempZipFileName));
//				File upDir = zipFile.getParentFile();
//				if(!upDir.isFile()&&!upDir.isDirectory()){
//					upDir.mkdirs();
//				}
//				fos = new FileOutputStream(zipFile);
//				zos = new ZipOutputStream(fos);
//
//				CRC32 crc = new CRC32(); // CRC32 에러 대비 변수
//
//		        IConfigurationInfoProvider config1 = ConfigurationManager.getConfigurationInfoProvider();
//				String os_type = config1.getItem("os.type").getValue();
//
//				while(rset.next()){
//					String applicantNm = rset.getString("applicant_nm");
//					String ctzNo = rset.getString("ctz_no");
//					String fileName= applicantNm+"_"+ctzNo+".jpg";
//					//String fileName= ctzNo+".jpg";
//
//					//System.out.println(fileName);
//
//					/*
//					if (os_type != null && os_type.equals("ms949")) {
//						fileName = new String(fileName.getBytes("UTF-8"),"ISO8859-1");
//					} else{
//						fileName = new String(fileName.getBytes("UTF-8"),"ISO8859-1");
//					//System.out.println(fileName);
//					}*/
//
//					input = new BufferedInputStream(rset.getBinaryStream("img_data"));
//
//					// 하나의 파일을 쓴다.
//
//					File file = new File(getServletContext().getRealPath("/temp_images/" +fileName));
//					bofs = new BufferedOutputStream(new FileOutputStream(file));
//
//					byte buffer[] = new byte[102400];
//
//					int bytesRead = 0;
//
//					while((bytesRead = input.read(buffer))>0){
//						bofs.write(buffer,0,bytesRead);
//					}
//
//					bofs.flush();
//					bofs.close();
//
//					// 쓴 파일을 열어서 압축 파일에 집어 넣는다.(이 전 과정이 중복이므로, 이후 중복을 제거해 보자...
//					input = new BufferedInputStream(new FileInputStream(file));
//
//					crc.reset();
//
//
//					while((bytesRead = input.read(buffer))>0){
//						crc.update(buffer,0,bytesRead);
//					}
//
//					input.close();
//
//					input = new BufferedInputStream(new FileInputStream(file));
//
//					//zipentry생성
//					ZipEntry entry = new ZipEntry(fileName);
//					entry.setMethod(ZipEntry.STORED);
//		            entry.setCompressedSize(file.length());
//		            entry.setSize(file.length());
//		            entry.setCrc(crc.getValue());
//
//		            // entry 추가
//		            zos.putNextEntry(entry);
//
//		            // 아카이브 파일  쓰기
//		            while((bytesRead = input.read(buffer))>0){
//		            	zos.write(buffer,0,bytesRead);
//		            }
//
//		            input.close();
//		            if(file!= null && file.exists() && file.isFile())
//		            	file.delete();
//				}
//
//				zos.close();
//
//				fis = new FileInputStream(zipFile);
//				input = new BufferedInputStream(fis);
//				byte[] buf = new byte[4*1024];
//		        int len;
//
//		        if (os_type != null && os_type.equals("ms949")) {
//		        	tempZipFileName = new String(tempZipFileName.getBytes("UTF-8"),"ISO8859-1");
//
//					response.setHeader("Content-Type", "application/zip");
//					response.setHeader("Content-Disposition", "attachment;filename=" + tempZipFileName + ";");
//				} else {
//					response.setHeader("Content-Type", "application/zip");
//					response.setHeader("Content-Disposition", "attachment;filename=" + java.net.URLEncoder.encode(tempZipFileName, "UTF-8") + ";");
//				}
//
//		        while((len = input.read(buf, 0, buf.length)) != -1){
//		        	response.getOutputStream().write(buf, 0, len);
//		        }
//		        input.close();
//		        fis.close();
//		        if(zipFile != null && zipFile.exists() && zipFile.isFile())
//		        	zipFile.delete();
//
//			}catch(Exception e){
//				e.printStackTrace();
//			}finally{
//				try{
//		    		if(rset != null) rset.close();
//			        if(stmt != null) stmt.close();
//			        if(con != null) con.close();
//
//
//			        if(fis != null) fis.close();
//			        if(fos != null) fos.close();
//
//					if(zos != null) zos.close();
//
//					if(input != null) input.close();
//					if(bofs != null) bofs.close();
//
//		    	}catch(SQLException se){}
//			}
//
//	}
//}