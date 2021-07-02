package mylabel;

import java.io.IOException;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.List;

public class MyFindLabelCodeTest {

	public static void main(String[] args) throws IOException  {
		
		String srcDir = "D:\\\\DW_REP\\\\H5WebApplication\\\\WebContent\\\\pay";
		List<MyLabel> labelList = MyFilesUtil.subDirList(srcDir);
		
		labelList.stream().filter(MyLabel::isFailure).forEach(System.out::println);
		
		System.out.println("남아있는파일갯수:" + labelList.stream().filter(MyLabel::isFailure).map(MyLabel::getFileName).distinct().count());
		
	}
}
