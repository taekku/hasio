package mylabel;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileReader;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

public class MyFilesUtil {

	public static List<MyLabel> subDirList(String source) throws IOException {
		
		File dir = new File(source);
		File[] fileList = dir.listFiles();
		
		List<MyLabel> fileLabelList = new ArrayList<MyLabel>();
		
		
		for (int i = 0; i < fileList.length; i++) {
			File file = fileList[i];
			if (file.isFile()) {
				// 파일이 있다면 파일 이름 출력

				String fileName = file.getName();
				
				String ext = fileName.substring( fileName.lastIndexOf(".") + 1 );
				
				if ( ext.toUpperCase().contentEquals("JSP")) {


					fileLabelList.addAll ( readFile( file ) ) ;
				}
				
			} else if (file.isDirectory()) {

				// 서브디렉토리가 존재하면 재귀적 방법으로 다시 탐색
 
				fileLabelList.addAll( subDirList(file.getCanonicalPath().toString()) );
			}
		}
		
		return fileLabelList; 
		
	}
	
	private static List<MyLabel> readFile( File file ) throws IOException {
		
		FileReader fileReader = new FileReader(file);
		
		BufferedReader bufReader = new BufferedReader(fileReader);
		
		String line = "";
		
		//label="사원" labelCode="FRM.EMPLOYEE"
		List<MyLabel> fileLabels = new ArrayList<MyLabel>();
		
		
		while(( line = bufReader.readLine()) != null) {
			
			List<MyLabel> labelList = findLabels( line , file.getAbsolutePath());
			
			for ( int i = 0 ; i < labelList.size() ; i++ ) {
				
				
				MyLabel labelObj = labelList.get(i);
				
				if ( labelObj.resultCode.contentEquals("SUCCESS")) {
				
					String labelCocde = findLabelCode( line , i  );
					
					labelObj.labelCode = labelCocde;
				}
			}
			
			fileLabels.addAll(labelList);
		}
		
		bufReader.close();
		
		return fileLabels;
	}

	private static String findLabelCode(String line, int labelIndex ) {
		// TODO Auto-generated method stub
		
		String[] labelCodes = line.split("labelCode=\"");
		
		int currIndex = 0;
		for( int i = 0 ; i < labelCodes.length; i++ ) {
			
			if ( i % 2 != 0 ) {
				
				if ( currIndex == labelIndex) {
					
					try {
						
						String labelCode = labelCodes[i].substring(0 , labelCodes[i].indexOf("\""));		
						
						return labelCode;
						
					} catch( Exception e ) {
						
						return "";
					}
				}
			
				currIndex++;
			}
			
		}
		
		return "";
	}

	private static List<MyLabel> findLabels(String line , String fileName ) {
		// TODO Auto-generated method stub
		
		List<MyLabel> labelList = new ArrayList<MyLabel>();
		
		MyLabel labelObj = new MyLabel();
		
		String[] labels = line.split("label=\"");
		
		/* <h5:TitleBox label="콘도요금 업로드" labelCode="콘도요금 업로드"> */
		
		for( int i = 0 ; i < labels.length; i++ ) {
			
			if ( i % 2 != 0 ) {
				try {
					
					String label = labels[i].substring(0 , labels[i].indexOf("\""));		
					
					labelObj.label = label;
					labelObj.fileName = fileName;
					labelObj.resultCode = "SUCCESS";
					
					//System.out.println("label : " + label);
					
					labelList.add(labelObj);
				
				} catch( Exception e ) {
					//System.out.println("오류나는 라벨은 : " + labels[i]);
					
					labelObj.label = labels[i];
					labelObj.fileName = fileName;
					labelObj.resultCode = "FAILURE";
					
					labelList.add(labelObj);
				}
			}
		}
		
		return labelList;
	}
}
