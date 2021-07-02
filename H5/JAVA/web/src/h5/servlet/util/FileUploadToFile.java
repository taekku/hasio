package h5.servlet.util;

import org.apache.commons.fileupload.FileItem;

import java.io.File;

/**
 * 첨부파일을 파일로 저장한다.
 * @author crystal
 *
 */
public class FileUploadToFile extends AbsFileUpload {
	protected void fileUpload(String fileId, String filePath, FileItem fileItem, String empId, String unitCd) throws Exception{
		try{
			String fileName = fileItem.getName();
			int index = fileName.lastIndexOf("\\");
			if(index == -1) index = fileName.lastIndexOf("/");
			fileName = fileName.substring(index + 1);

			File file = new File(filePath + fileName );
			File upDir = file.getParentFile();

			if (!upDir.isFile() && !upDir.isDirectory()) {
				upDir.mkdirs();
			}

			fileItem.write(file);

		} catch (Exception e) {
			e.printStackTrace();
			throw e;
		}
	}
}
