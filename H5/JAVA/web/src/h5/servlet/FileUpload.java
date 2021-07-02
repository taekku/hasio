package h5.servlet;

import h5.servlet.util.AbsFileUpload;
import h5.servlet.util.FileUploadToDB;
import h5.servlet.util.FileUploadToFile;
import h5.servlet.vo.FileInfoVO;
import h5.sys.registry.RegistryItem;
import h5.sys.registry.SystemRegistry;

import java.io.File;
import java.io.IOException;
import java.util.Iterator;
import java.util.List;

import javax.servlet.RequestDispatcher;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.apache.commons.fileupload.FileItem;
import org.apache.commons.fileupload.FileUploadException;
import org.apache.commons.fileupload.disk.DiskFileItemFactory;
import org.apache.commons.fileupload.servlet.ServletFileUpload;
import org.json.simple.JSONArray;
import org.json.simple.JSONObject;

import com.win.frame.server.ServerConfig;
import com.win.frame.server.ServerConfigFactory;
import com.win.rf.config.ConfigurationManager;
import com.win.rf.config.IConfigurationInfoProvider;

/**
 * Servlet implementation class FileUploadTest
 */
public class FileUpload extends HttpServlet {
	private static final long serialVersionUID = 1L;

	/**
	 * @see HttpServlet#HttpServlet()
	 */
	public FileUpload() {
		super();
	}

	/**
	 * @see HttpServlet#doGet(HttpServletRequest request, HttpServletResponse response)
	 */
	@Override
	protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
		
		String storeType = ""; // 저장방식 FILE/DB
		String upload_type = "";
		String emp_id = "";
		
		//모바일 사용변수
		String elaFileUseYn = ""; //- Y/N 파일선택 사용여부
		String elaFileAgreeYn = "";//- Y/N 동의서첨부 사용여부
		String elaBtnEditable = "";
		
		List list = null; // 참부파일 request를 가지는 리스트 객체

		try {
			// 설정파일(h5_runtime_config.properties)로부터 서버 인코딩을 얻어낸다.
			// 한글파일이 깨지거나 한다면 설정파일(h5_runtime_config.properties)에 인코딩이 Euc-kr 등으로 되어있는지 확인해야한다.
			ServerConfig sConfig = ServerConfigFactory.getServerConfig();
			IConfigurationInfoProvider config = ConfigurationManager.getConfigurationInfoProvider();
			String encodingType = config.getItem("server.encoding").getValue();

			DiskFileItemFactory factory = new DiskFileItemFactory();
			factory.setSizeThreshold(1024 * 1024 * 2); // 2M까지는 메모리에 저장
			factory.setRepository(new File(this.getServletContext().getRealPath("/WEB-INF/uploadData"))); // 파일사이즈가 클경우 임시저장위치 지정

			// ServletFileUpload를 선언하고 파일크기를 지정한다.
			ServletFileUpload upload = new ServletFileUpload(factory); // Create a new file upload handler
			upload.setSizeMax(-1); // Sets the maximum allowed size of a complete request
			upload.setHeaderEncoding(encodingType); // 인코딩 지정.
			
			System.out.println("request : " + request);

			list = upload.parseRequest(request);
			
			System.out.println("list : " + list);

			Iterator itemItor = list.iterator();
			while (itemItor.hasNext()) {
				FileItem item = (FileItem) itemItor.next();
				
				System.out.println("item : " + item.getFieldName());
				if (item.isFormField() && "store_type".equals(item.getFieldName()))
						storeType = item.getString();
				if (item.isFormField() && "upload_type".equals(item.getFieldName()))
					upload_type = item.getString();
				if( item.isFormField() && "emp_id".equals(item.getFieldName()))
					emp_id = item.getString();
				if( item.isFormField() && "gv_file_use_yn".equals(item.getFieldName())) //모바일 전자결재에서 사용
					elaFileUseYn = item.getString();
				if( item.isFormField() && "gv_file_agree_yn".equals(item.getFieldName())) //모바일 전자결재에서 사용 
					elaFileAgreeYn = item.getString();
				if( item.isFormField() && "editable".equals(item.getFieldName())) //모바일 전자결재에서 사용 
					elaBtnEditable = item.getString();
				
			}
		} catch (FileUploadException e1) {
			e1.printStackTrace();
		}

		// 레지스트리에서 파일 저장 타입 가져오기.
		if(null == storeType || "".equals(storeType)){
			RegistryItem registryItem = SystemRegistry.getRegistryItem("GLOBAL_ATTR/SYSTEM_ENVIRONMENTS/NODES/FILESTORE/TYPE");
			if (registryItem != null) storeType = registryItem.getValue();
		}
		
		AbsFileUpload fileUpload = null;

		try{
			if("FILE".equals(storeType)){
				fileUpload = new FileUploadToFile();
				fileUpload.addFileInfo(request, list);
			}else if("DB".equals(storeType)){
				fileUpload = new FileUploadToDB();
				fileUpload.addFileInfo(request, list);			
			}
		}catch(Exception e){
			e.printStackTrace();
		}

		if( "aj".equals(upload_type)){
			
			response.setContentType("text/html;charset=UTF-8"); // 한글로 자료를 넘겨주기 위해서.
            java.io.PrintWriter pw = response.getWriter();
            
            List<FileInfoVO> fileIdList = fileUpload.getFileIdList();
            
            JSONArray jsArray = new JSONArray();
            
            for ( FileInfoVO k : fileIdList ){
            	
            	jsArray.add(k.getMap());
            }
            
            JSONObject obj = new JSONObject();
            obj.put("file_path_id", request.getAttribute("file_path_id"));
            obj.put("file_id_arr", jsArray);
			pw.print(obj.toJSONString());
			pw.flush();		
			
		} else if( "mobile".equals(upload_type)) {
			request.setAttribute("gv_file_use_yn", elaFileUseYn);
			request.setAttribute("gv_file_agree_yn", elaFileAgreeYn);
			request.setAttribute("editable", elaBtnEditable);
			RequestDispatcher dispatcher = request.getRequestDispatcher("/mhr/common/web/inc/fileView.jsp");
			dispatcher.forward(request, response);
		} else {
		
			RequestDispatcher dispatcher = request.getRequestDispatcher("/common/web/fileView.jsp");
			dispatcher.forward(request, response);
		}

	}

	/**
	 * @see HttpServlet#doPost(HttpServletRequest request, HttpServletResponse response)
	 */
	@Override
	protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
		// TODO Auto-generated method stub
		doPost(req, resp);
	}
}
