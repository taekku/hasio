package h5.servlet.vo;

import java.util.HashMap;

public class FileInfoVO {

	private String file_id;
	
	private String file_nm;

	public FileInfoVO(String file_id, String file_nm) {
		super();
		this.file_id = file_id;
		this.file_nm = file_nm;
	}
	
	public HashMap<String,String> getMap(){
		
		HashMap<String, String> tmpMap = new HashMap<String, String>();
		tmpMap.put("file_id" , this.file_id);
		tmpMap.put("file_nm" , file_nm);
		
		return tmpMap;
	}
	
}
