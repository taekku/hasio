package h5.mobile;

import java.io.FileInputStream;
import java.util.Properties;

/**
 * 인증 키값 불러오기
 * @author User
 *
 */
public class PropertiesRead {
	public String readKey(String fileName) throws Exception {
		Properties pro = new Properties();
		
		try{
			pro.load(new FileInputStream("D:\\H5Application.ear\\H5WebApplication.war\\mhr\\common\\config\\"+fileName));
			//pro.load(new FileInputStream("/app/H5Mobile.ear/H5WebApplication.war/mhr/common/config/"+fileName));
		}catch(Exception e){
			e.printStackTrace();
		}
		
		String key  = pro.getProperty("useKey");
		return key;
	}
}
