package hrms.intcom;

import h5.sys.command.CommandExecuteException;

import java.io.File;
import java.io.FileInputStream;
import java.io.InputStream;
import java.util.HashMap;

import com.win.frame.invoker.GridResult;

import com.win.rf.invoker.SQLInvoker;

public class ClassLoaderHrms extends ClassLoader {
	
	static private HashMap classMap = new HashMap();
	static private HashMap class2Map = new HashMap();
	private String company_cd = "01";
	static private String org_dir = "";
	
	public ClassLoaderHrms(ClassLoader parent) {
		super(parent);
	}

	public ClassLoaderHrms(String company_cd) {
		super(ClassLoaderHrms.class.getClassLoader());
		this.company_cd = company_cd;
	}

	/**
	 * 
	 */
	protected Class findClass(String className) throws ClassNotFoundException {
//		System.out.println("className =================================>"+className);
		byte[] classBytes = null;
		Class loadClass = null;
		
		try{
			if(org_dir.equals(""))
			{
				HashMap pmap = new HashMap();
				pmap.put("company_cd",   this.company_cd);
				pmap.put("unit_cd",      "FRM");
				pmap.put("const_kind",   "CLASS_DIR");
				
				SQLInvoker invoker     = new SQLInvoker("frm_const_001", pmap);
			    GridResult gridResult   = (GridResult)invoker.doService();
			    
			    if (gridResult.next()) {
			    	org_dir = gridResult.getValueString(0);
			    }
			    else
			    {
			    	throw new CommandExecuteException("기본 인사영역에 업무구분 '시스템공통 (FRM)', 상수구분  'CLASS_DIR' 에 상수값을 등록 하세요. ");
			    }
			    
			    if (org_dir == null || org_dir.equals("")){
			    	throw new CommandExecuteException("기본 인사영역에 업무구분 '시스템공통 (FRM)', 상수구분  'CLASS_DIR' 에 상수값을 등록 하세요. ");
			    }
			    if(org_dir.charAt(org_dir.length()-1) != '/')
			    	org_dir = org_dir + "/";
			}
			String dir = org_dir;
			int idx = -1;
			int preidx = -1;
			String classFileName = "";
			while(true)
			{
				idx = className.indexOf(".", preidx+1);
				if(idx < 0)
					break;
				dir +=  className.substring(preidx+1,idx) + "/" ;
				preidx = idx;
			}
			
			if(preidx > 0)
				classFileName = className.substring(preidx+1);
			else 
				classFileName = className;
			File file = new File(dir, classFileName + ".class");
			Long lastModified = (Long)classMap.get(className); 
			Long lastModifiedCur = new Long(file.lastModified());
			//System.out.println("file =================================>"+dir+ classFileName);
			if (file.exists()) {
				if(lastModified == null || !lastModified.equals(lastModifiedCur))
				{
					loadClass = (Class)class2Map.get(className); 
					loadClass = null;
					classMap.put(className, lastModifiedCur);
					InputStream is = new FileInputStream(file);
					classBytes = new byte[is.available()];
					is.read(classBytes);
					//System.out.println(classBytes +  "======"+classBytes.length+" defineClass=================================>"+ className);
					loadClass = defineClass(className, classBytes, 0, classBytes.length);
					//System.out.println("Class 가 없거나 변경되었을때  load 하=================================>"+ className);
					
					class2Map.put(className, loadClass);
				}else
				{
					loadClass = (Class)class2Map.get(className); 
					//System.out.println(" Class 를 map 에서 가지고 오당 =================================>"+ className);
				}
			}else
			{
				throw new CommandExecuteException(className + " class 가 존재 하지 않습니다.");
			}

			return loadClass;
		}catch(Exception e)
		{
			e.printStackTrace();
			throw new ClassNotFoundException(e.getMessage());
		}
	}


}