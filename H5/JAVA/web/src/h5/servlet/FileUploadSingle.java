package h5.servlet;

import h5.servlet.util.AbsFileUpload;
import h5.servlet.util.AbsFileUpload_PEH;
import h5.servlet.util.FileUploadToDB;
import h5.servlet.util.FileUploadToDB_PEH;
import h5.servlet.util.FileUploadToFile;
import h5.sys.registry.RegistryItem;
import h5.sys.registry.SystemRegistry;

import java.io.File;
import java.io.IOException;
import java.io.PrintWriter;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import h5.sys.util.Logger;
import org.apache.commons.fileupload.FileItem;
import org.apache.commons.fileupload.FileUploadException;
import org.apache.commons.fileupload.disk.DiskFileItemFactory;
import org.apache.commons.fileupload.servlet.ServletFileUpload;

import com.win.frame.server.ServerConfig;
import com.win.frame.server.ServerConfigFactory;
import com.win.rf.config.ConfigurationManager;
import com.win.rf.config.IConfigurationInfoProvider;

/**
 * Servlet implementation class FileUploadTest
 */
public class FileUploadSingle extends HttpServlet {
	private static final long serialVersionUID = 1L;

	/**
	 * @see HttpServlet#HttpServlet()
	 */
	public FileUploadSingle() {
		super();
	}

	/**
	 * @see HttpServlet#doGet(HttpServletRequest request, HttpServletResponse response)
	 */
	@Override
	protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
		HashMap<String, String> paramMap = new HashMap<String, String>();
		String storeType = ""; // 파일타입 FILE/DB
		List list = null; // 참부파일 request를 가지는 리스트 객체
		try {
			// 설정파일(h5_runtime_config.properties)로부터 서버 인코딩을 얻어낸다.
			ServerConfig sConfig = ServerConfigFactory.getServerConfig();
			IConfigurationInfoProvider config = ConfigurationManager.getConfigurationInfoProvider();
			String encodingType = config.getItem("server.encoding").getValue();
			
			DiskFileItemFactory factory = new DiskFileItemFactory();
			factory.setSizeThreshold(1024 * 1024 * 2); // 2M까지는 메모리에 저장
			factory.setRepository(new File(this.getServletContext().getRealPath("/WEB-INF/uploadData"))); // 

			// ServletFileUpload를 선언하고 파일크기를 지정한다.
			ServletFileUpload upload = new ServletFileUpload(factory); // Create a new file upload handler
			upload.setSizeMax(-1); // Sets the maximum allowed size of a complete request
			upload.setHeaderEncoding(encodingType); // 인코딩 지정.

			list = upload.parseRequest(request);
			
			System.out.println("chkchk");
			System.out.println(list);
			
			Iterator itemItor = list.iterator();
			while (itemItor.hasNext()) {
				FileItem item = (FileItem) itemItor.next();
				System.out.println("item 값들 : " + item.getString());
				
				if(item.isFormField()) {
					paramMap.put(item.getFieldName(), item.getString());
					
				}
				if (item.isFormField() && "store_type".equals(item.getFieldName()))
						storeType = item.getString();
			}
		} catch (FileUploadException e1) {
			e1.printStackTrace();
		}

		// 레지스트리에서 파일 저장 타입 가져오기.
		if(null == storeType || "".equals(storeType)){
			RegistryItem registryItem = SystemRegistry.getRegistryItem("GLOBAL_ATTR/SYSTEM_ENVIRONMENTS/NODES/FILESTORE/TYPE");
			if (registryItem != null) storeType = registryItem.getValue();
		}
		 
		try{
			if("FILE".equals(storeType)){
				AbsFileUpload fileUpload = new FileUploadToFile();
				fileUpload.setParamMap(paramMap);
				fileUpload.addFileInfo(request, list);
			}else if("DB".equals(storeType)){
				System.out.println("storeType : " + storeType);
				
				AbsFileUpload fileUpload = new FileUploadToDB();
				fileUpload.setParamMap(paramMap);
				fileUpload.addFileInfo(request, list);
			}else if("PEH_FILE".equals(storeType)){//사외이사 사진등록 로직추가
				AbsFileUpload_PEH fileUpload = new FileUploadToDB_PEH();
				fileUpload.setParamMap(paramMap);
				fileUpload.addFileInfo(request, list);
			}
		}catch(Exception e){
			e.printStackTrace();
			sendScript(request, response);
		}
		sendScript(request, response);
	}

	/**
	 * @see HttpServlet#doPost(HttpServletRequest request, HttpServletResponse response)
	 */
	@Override
	protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
		// TODO Auto-generated method stub
		doPost(req, resp);
	}
	
	private void sendScript(HttpServletRequest request, HttpServletResponse response){
		try{
			HttpSession session = request.getSession();
			response.setContentType("text/html; charset=utf-8");
			PrintWriter out =response.getWriter();
			System.out.println("file_path_id : " + request.getAttribute("file_path_id"));
			System.out.println("retCode : " + request.getAttribute("retCode"));
			System.out.println("retMessage : " + request.getAttribute("retMessage"));
			System.out.println("file_id : " + request.getAttribute("file_id"));
			
			out.println("<script>parent.uploadEnd('"+request.getAttribute("file_path_id")+"','"+request.getAttribute("retCode")+"','"+request.getAttribute("retMessage")+"','"+request.getAttribute("file_id")+"')</script>");
			out.close();
		}catch(Exception e){
			e.printStackTrace();
		}
	}
}
