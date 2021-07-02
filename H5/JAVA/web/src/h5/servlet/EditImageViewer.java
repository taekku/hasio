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

import com.oreilly.servlet.MultipartRequest;
import com.oreilly.servlet.multipart.DefaultFileRenamePolicy;
import com.win.frame.server.ServerConfig;
import com.win.frame.server.ServerConfigFactory;
import com.win.rf.config.ConfigurationManager;
import com.win.rf.config.IConfigurationInfoProvider;

public class EditImageViewer extends HttpServlet {
	
	protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
		String rootPath = request.getSession().getServletContext().getRealPath("/").replace("\\", "/");
		String extPath = "common/editorImage/";
		String imagePath = rootPath+extPath;
		String file_id = request.getParameter("file_id");
		
		InputStream is = null;
		
		try {
			is = getImageFromFile(file_id , imagePath);			
		} catch (SQLException e1) {
			e1.printStackTrace();
		}			
		BufferedInputStream input = new BufferedInputStream(is);
		try{
			// 이미지를 아웃 스트림으로 출력한다.
			byte[] buf = new byte[4*1024];
			int len;
			while((len = input.read(buf, 0, buf.length)) != -1){
				response.getOutputStream().write(buf, 0, len);
			}
			response.setHeader("Content-Length", String.valueOf( len ) );
			is.close();
		}catch(Exception e){
			e.printStackTrace();
		}finally{
			if(is != null){
				is.close();
				is = null;
			}
			if(input != null){
				input.close();
				input = null;
			}
		}
	}
	
	@Override
	protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
		doGet(request,response);
	}
	
	protected InputStream getImageFromFile(String file_id ,  String imagePath) throws FileNotFoundException, ServletException, SQLException{
		String fullFileName = imagePath + file_id;
		
		File imageFile = new File(fullFileName);
		
		if ( !imageFile.exists()){
			System.err.println("파일이 존재하지 않습니다.(" + fullFileName +")");
			throw new FileNotFoundException("파일이 존재하지 않습니다.(" + fullFileName +")");
		}
		return new FileInputStream(imageFile);
	}
	
	
}
