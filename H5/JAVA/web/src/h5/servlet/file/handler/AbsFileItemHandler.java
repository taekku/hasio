package h5.servlet.file.handler;

import h5.servlet.file.exception.FileHandlerException;

import java.util.HashMap;
import java.util.List;

import javax.servlet.http.HttpSession;

import org.apache.commons.fileupload.FileItem;

public abstract class AbsFileItemHandler implements IFileItemHandler {

	private List<FileItem> fileList = null;
	private HashMap<String, String> paramMap = null;
	private HttpSession session = null;
	
	@Override
	public HttpSession getSession() {
		return session;
	}
	
	public void setSession(HttpSession session) {
		this.session = session;
	}
	
	@Override
	public List<FileItem> getFileList() {
		return this.fileList;
	}
	
	public void setFileList(List<FileItem> fileList) {
		this.fileList = fileList;
	}
	
	@Override
	public HashMap<String, String> getParamMap() {
		return this.getParamMap();
	}
	
	public void setParamMap(HashMap<String, String> paramMap) {
		this.paramMap = paramMap;
	}
	
	@Override
	public String getParamValue(String key) {
		if(paramMap != null && paramMap.containsKey(key))
			return paramMap.get(key);
		
		return null;
	}
	
	abstract protected void init() throws FileHandlerException;
	abstract protected void execute() throws FileHandlerException;
	
	@Override
	public void run() throws FileHandlerException {
		init();
		execute();
	}
}
