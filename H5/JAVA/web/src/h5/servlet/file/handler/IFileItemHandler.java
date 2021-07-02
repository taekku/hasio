package h5.servlet.file.handler;

import h5.servlet.file.exception.FileHandlerException;

import java.util.HashMap;
import java.util.List;

import javax.servlet.http.HttpSession;

import org.apache.commons.fileupload.FileItem;

public interface IFileItemHandler {
	
	public HttpSession getSession();
	
	public HashMap<String, String> getParamMap();
	
	public String getParamValue(String key);
	
	public List<FileItem> getFileList();
	
	public void run() throws FileHandlerException;
}
