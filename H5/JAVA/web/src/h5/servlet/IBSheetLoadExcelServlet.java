package h5.servlet;

import h5.servlet.vo.IBSheetExcelData;
import h5.servlet.vo.IBSheetExcelDataItem;

import java.io.File;
import java.io.IOException;
import java.io.PrintWriter;
import java.text.DecimalFormat;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.Iterator;
import java.util.List;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.apache.commons.fileupload.FileItem;
import org.apache.commons.fileupload.disk.DiskFileItemFactory;
import org.apache.commons.fileupload.servlet.ServletFileUpload;
import org.apache.poi.hssf.usermodel.HSSFDateUtil;
import org.apache.poi.ss.usermodel.Cell;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Sheet;
import org.apache.poi.ss.usermodel.Workbook;
import org.apache.poi.ss.usermodel.WorkbookFactory;

import com.win.frame.server.ServerConfig;
import com.win.frame.server.ServerConfigFactory;
import com.win.rf.config.ConfigurationManager;
import com.win.rf.config.IConfigurationInfoProvider;

public class IBSheetLoadExcelServlet extends HttpServlet {
	final String COLUMN_TAG_NAME = "ColumnTag";
	IBSheetExcelData excelData = null;
	
	protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
		List list = null; // 참부파일 request를 가지는 리스트 객체
		StringBuffer sb = new StringBuffer();
		Workbook workBook = null;
		
		response.setHeader("Cache-Control","no-store");
		response.setHeader("Pragma", "no-cache");
		response.setDateHeader("Expires", 0);
		response.setContentType("text/html; charset=utf-8");
		
		if(request.getProtocol().equals("HTTP/1.1"))
			response.setHeader("Cache-Control", "no-cache");
		
		PrintWriter out = response.getWriter();
		
		String contentType = request.getContentType();

		if ((contentType == null)) {
			out.println("<script>try{parent.document.getElementById('IBSheetLoadExcelFileFinder').click();}catch(e){}</script>");
		}
		
		if ((contentType == null) || (contentType.indexOf("multipart/form-data") < 0)) {
			return;
		}
		
		try {
			// 설정파일(h5_runtime_config.properties)로부터 서버 인코딩을 얻어낸다.
			ServerConfig sConfig = ServerConfigFactory.getServerConfig();
			IConfigurationInfoProvider config = ConfigurationManager.getConfigurationInfoProvider();

			DiskFileItemFactory factory = new DiskFileItemFactory();
			factory.setSizeThreshold(1024 * 1024 * 2); // 2M까지는 메모리에 저장
			factory.setRepository(new File(this.getServletContext().getRealPath("/WEB-INF/uploadData"))); // 파일사이즈가 클경우 임시저장위치 지정

			// ServletFileUpload를 선언하고 파일크기를 지정한다.
			ServletFileUpload upload = new ServletFileUpload(factory); // Create a new file upload handler
			upload.setSizeMax(-1); // Sets the maximum allowed size of a complete request

			// upload.setHeaderEncoding(encodingType); // 인코딩 지정.
			// upload.setHeaderEncoding("utf-8); // 인코딩 지정.

			list = upload.parseRequest(request);
			Iterator itemItor = list.iterator();

			MyData data = new MyData();
			
			// 준비 완료 이제 넘어온걸 뺑뻉이 돌리면서 필요한 정보들을 챙기자
			while (itemItor.hasNext()) {
				FileItem item = (FileItem) itemItor.next();
				String fieldName = item.getFieldName();

				// IBSheet에서 날라오는 파라미터는 몽땅 저분께서 들고 계시는듯 하다... 고로 저놈만 처리하는거얍~~
				if (fieldName != null && COLUMN_TAG_NAME.equals(fieldName)) {
					// TODO: (hys) 여긴 난중에 인코딩 처리로 바꾸세!!!
					String columnTagValue = new String(item.getString().getBytes("ISO8859-1"), "UTF-8");
//					System.out.println("columnTag >> " + columnTagValue);

					// 곱게 넘어오신 설정 정보들을 갈기 갈기 찢어버리자!!!
					data.ColList = columnTagValue;
					data.Mode = getPropValue(data.ColList, "Mode");
					data.SearchMode = getPropValue(data.ColList, "SearchMode");
					data.OrgColList = data.ColList;
					data.MaxCols = Integer.parseInt(getPropValue(data.ColList, "MaxCols"));
					data.headerRows = Integer.parseInt(getPropValue(data.ColList, "HeaderRows"));
					if (data.Mode.equals("NoHeader") || data.Mode.equals("NOHEADER")) {
						data.headerRows = 0;
					}
					data.saveName = new String[512]; // 최대 512 개의 엑셀 컬럼 로딩을 지원함
					data.colType = new String[512];
					data.colFormat = new String[512];

					data.ColumnMapping = getPropValue(data.ColList, "ColumnMapping").split("\\|");
					data.StatusCol = getPropValue(data.ColList, "StatusCol");
					data.saveNameOrg = getPropValue(data.ColList, "SaveNames").split("\\|");
					// out.println("<<"+getPropValue(data.ColList,"SaveNames")+">>");
					if (getPropValue(data.ColList, "ColumnMapping").equals(""))
						data.isColumnMapping = false;
					else
						data.isColumnMapping = true;

					data.WorkSheetName = getPropValue(data.ColList, "WorkSheetName");
					data.WorkSheetNo = Integer.parseInt(getPropValue(data.ColList, "WorkSheetNo"));
					data.StartRow = Integer.parseInt(getPropValue(data.ColList, "StartRow"));
					// data.bUnMatchColHidden = Integer.parseInt(getPropValue(data.ColList,"UnMatchColHidden"));

					if (data.StartRow < 1) {
						data.StartRow = 1;
					}
					data.EndRow = Integer.parseInt(getPropValue(data.ColList, "EndRow"));

					String HeaderText = getPropValue(data.ColList, "HeaderText");
					String SaveName = getPropValue(data.ColList, "SaveNames");
					String RecordType = getPropValue(data.ColList, "RecordType");
					String RecordFormat = getPropValue(data.ColList, "RecordFormat");
					String DatePattern = getPropValue(data.ColList, "DatePattern");

					String[] temp = RecordType.split("\\^");
					data.SaveName = new String[temp.length][];
					data.RecordType = new String[temp.length][];
					data.RecordFormat = new String[temp.length][];
					data.DatePattern = new String[temp.length][];

					data.fileSaveName = new String[temp.length][];
					data.fileRecordType = new String[temp.length][];
					data.fileRecordFormat = new String[temp.length][];
					data.fileDatePattern = new String[temp.length][];

					for (int r = 0; r < temp.length; r++) {
						String temp2 = temp[r];
						data.RecordType[r] = temp2.split("\\|", data.MaxCols);
					}
					temp = RecordFormat.split("\\^");
					for (int r = 0; r < temp.length; r++) {
						String temp2 = temp[r];
						data.RecordFormat[r] = temp2.split("\\|", data.MaxCols);
					}
					temp = DatePattern.split("\\^");
					for (int r = 0; r < temp.length; r++) {
						String temp2 = temp[r];
						data.DatePattern[r] = temp2.split("\\|", data.MaxCols);
					}
					temp = SaveName.split("\\^");
					for (int r = 0; r < temp.length; r++) {
						String temp2 = temp[r];
						data.SaveName[r] = temp2.split("\\|", data.MaxCols);
					}
					temp = HeaderText.split("\\^");
					data.HeaderText = new String[temp.length][];
					for (int r = 0; r < temp.length; r++) {
						String temp2 = temp[r];
						data.HeaderText[r] = temp2.split("\\|", data.MaxCols);
					}

					data.HeaderMatch = new boolean[data.RecordType[0].length];
					for (int r = 0; r < data.HeaderMatch.length; r++) {
						data.HeaderMatch[r] = false;
					}

					data.extendParam = getPropValue(data.ColList, "ExtendParam");
				}

				// 여기는 넘어온 파일 객체로 엑셀 객체를 만드는거야~~
				String fileName = item.getName();

				if (fileName != null && !"".equals(fileName)) {
					workBook = WorkbookFactory.create(item.getInputStream());
				}
			}
			
			if(workBook == null)
				return;
			
			sb.append("<html><head><script>var targetWnd = null; if(opener!=null) {targetWnd = opener;} else {targetWnd = parent;} targetWnd.gJson='{data:[");
			//sb.append(LoadExcel(out, data, workBook));
			LoadExcel(out, data, workBook);
			dataProcessing(excelData, data.extendParam);
			sb.append(excelData.toString());

			String sUnMatchColumn = "";
			
			sb.append("]}';" + ((data.SearchMode.equals("3")) ? "targetWnd.Grids[targetWnd.gTargetExcelSheetID].SetTotalRows(" + data.LoadRowCount + ");" : "") + "targetWnd.Grids[targetWnd.gTargetExcelSheetID].DoSearchScript('gJson','EXCEL');");

			if (data.bUnMatchColHidden == 1) {
				sb.append("targetWnd.Grids[targetWnd.gTargetExcelSheetID].mUnMatchColHidden('" + sUnMatchColumn + "');");
			}
			sb.append("</script></head></body></html>");

			out.println(sb.toString());
		} catch (Exception e) {
			e.printStackTrace();
		} finally {
			excelData = null;
		}
	}
	
	/**
	 * 데이터 가공이 필요할 경우 재구현하여 데이터를 조작한다.
	 * 
	 * @param excelData 생성된 데이터 객체
	 * @param extendParam 화면에서 무언가의 처리 규칙을 명시한 파라미터
	 */
	protected void dataProcessing(IBSheetExcelData excelData, String extendParam) {
		
	}
	
	private String LoadExcel(PrintWriter out, MyData data, Workbook workBook) throws Exception {
		StringBuffer sb = new StringBuffer();
		
		Sheet sheet = null;
		Row row = null;
		Cell cell = null;
		
		DecimalFormat df = new DecimalFormat("#.#################");
		String TheText = "";
		String TheText2 = "";
		String TheText3 = "";
		boolean isDate = false;
		
		int sheetNum = workBook.getNumberOfSheets();

		for(int k=0;k<sheetNum;k++)
		{
			if(!data.WorkSheetName.equals(""))
			{
				if(!data.WorkSheetName.equals(workBook.getSheetName(k)))
					continue;
			} else if(data.WorkSheetNo!=0) {
				if(k!=data.WorkSheetNo-1)
					continue;
			}

			sheet = workBook.getSheetAt(k);
			int rows = sheet.getLastRowNum();

			data.UsedCol = new boolean[512];
			for (int r = 0; r < data.SaveName.length; r++)
			{
				data.fileSaveName[r] = new String[512];
				data.fileRecordType[r] = new String[512];
				data.fileRecordFormat[r] = new String[512];
				data.fileDatePattern[r] = new String[512];
			}
			
			for(int r=data.StartRow-1;r<=rows;r++)
			{
				if(excelData == null) {
					excelData = new IBSheetExcelData();
					excelData.setStatusCol(data.StatusCol);
				}
				
				excelData.newDataItem();
				
				if(data.EndRow!=0)
				{
					if(r>data.EndRow-1) break;
				}

				row = sheet.getRow(r);
				int cells = 0;
				if(row!=null)
				{
					//cells = row.getLastCellNum();//getPhysicalNumberOfCells();
					//cells = data.MaxCols;
					cells = row.getLastCellNum();
				}

				//레코드 1개의 시작
				if(r>=data.headerRows+data.StartRow-1)
				{
					sb.append("{");
				}

				if (r < data.headerRows+data.StartRow-1 || (data.Mode.equals("NoHeader") || data.Mode.equals("NOHEADER")) && r==data.StartRow-1) // 헤더자료면 헤더-컬럼속성 자료 준비
				{
					//헤더제외
				}
				else
				{
					if(cells<=0) //빈문서인 경우
					{
						if(!data.StatusCol.equals(""))
						{
							sb.append(data.StatusCol+":\"I\"");
							
							excelData.getCurrentItem().setData(data.StatusCol, "I");
						}
					}
				}

				data.isFirst = true;
				for(int c=0;c<cells;c++)
				{
					isDate = false;

					if(row!=null)
					{
							TheText = "";
							TheText2 = "";
							TheText3 = "";
						cell = row.getCell(c);
						if(cell== null)
						{
							TheText = "";
							TheText2 = "";
							TheText3 = "";
						}
						else
						{
							switch(cell.getCellType())
							{
								case 0: // Cell.CELL_TYPE_NUMERIC
									if (HSSFDateUtil.isCellDateFormatted(cell)) {
										isDate = true;
									}
								case 1: // Cell.CELL_TYPE_STRING
								case 2: // Formula
								case 3: // Cell.CELL_TYPE_BLANK
								case 5: // Cell.CELL_TYPE_ERROR
									TheText = "";
									TheText2 = "";
									TheText3 = "";

									try
									{
										TheText = cell.getStringCellValue()+"";
										TheText2 = TheText;
									}
									catch(IllegalStateException e)
									{
										try
										{
											TheText3 = cell.getDateCellValue().getTime()+"";
											//isDate = true;
										} catch(Exception e3) { }
											
										try
										{
											cell.setCellType(1);
											TheText = cell.getStringCellValue()+"";
											TheText2 = TheText;
											
											if(TheText.length()>4)
											{
												if(TheText.indexOf("E")>-1)
												{
													if((TheText+"  ").substring(1,2).equals("."))
													{
														if(TheText.substring(TheText.length()-4,TheText.length()).indexOf("E")>-1)
														{
															TheText = df.format(Double.parseDouble(TheText));
															TheText2 = TheText;
														}
													}
												}
											}
										} catch(Exception e2) // # 등 오류
										{
											TheText = "";
											TheText2 = "";
											TheText3 = "";
										}
									}
									break;
								case 4: //Cell.CELL_TYPE_BOOLEAN
									TheText = Boolean.toString(cell.getBooleanCellValue());
									break;
								default:
							}
						}
						
						sb.append(mCellMap(out, data, r, c, TheText, TheText2, TheText3, isDate));
					}
				}//cell
				
				if (r < data.headerRows+data.StartRow-1 || (data.Mode.equals("NoHeader") || data.Mode.equals("NOHEADER")) && r==data.StartRow-1) // 헤더자료면 헤더-컬럼속성 자료 준비
				{
					//헤더제외
				}
				else
				{
//					sb.append(appendColumns(data.extendParam));
				}
				
				//레코드 1개의 끝
				if(r>=data.headerRows+data.StartRow-1)
				{
					data.LoadRowCount ++;
					sb.append("},");
				}
			}//row
		}//sheet
		return sb.toString();
	}

	// 사용하는 변수들을 선언합니다.
	public class MyData {
		int MaxCols = 0;
		int headerRows = 0;
		int StartRow = 0;
		int EndRow = 0;
		int TempRow_StatusCol = -1;
		int LoadRowCount = 0;
		String SearchMode = "";
		String Mode = "";
		String StatusCol = "";
		String ColList = "";
		String OrgColList = "";
		String filePath = "";
		String saveName[] = null;
		String saveNameOrg[] = null;
		String colType[] = null;
		String colFormat[] = null;
		String dataType[] = null;
		String ColumnMapping[] = null;
		boolean isColumnMapping = false;
		int bUnMatchColHidden = 0; // 사용자가 1 설정하면 1로 들어가서 언매치 컬럼들이 컬럼히든처리됨
		boolean isFirst = false;
		int WorkSheetNo = 0;
		String WorkSheetName = "";
		byte dataBytes[] = null;

		String SaveName[][];
		String HeaderText[][];
		String RecordType[][];
		String RecordFormat[][];
		String DatePattern[][];
		boolean UsedCol[];

		String fileSaveName[][];
		String fileRecordType[][];
		String fileRecordFormat[][];
		String fileDatePattern[][];

		boolean HeaderMatch[];

		String extendParam = "";
//		ArrayList<HashMap<String, String>> dataList = null;
	}

	// 속성 값을 얻어 냅니다.
	protected String getPropValue(String Header, String prop) throws Exception {
		int findS = 0;
		int findE = 0;

		// Header = Header.replace("\r","");
		// prop = prop.replace("\r","");
		Header = replace(Header, "\r", "");
		prop = replace(prop, "\r", "");

		findS = Header.indexOf("<" + prop + ">");
		findE = Header.indexOf("</" + prop + ">");

		if (findS != -1 && findE != -1)
			return Header.substring(findS + prop.length() + 2, findE); // 시작 태그를 제외하고 데이타만 리턴해줌
		else
			return "";
	}

	private String replace(String sStrString, String sStrOld, String sStrNew) {
		if (sStrString == null)
			return null;

		for (int iIndex = 0; (iIndex = sStrString.indexOf(sStrOld, iIndex)) >= 0; iIndex += sStrNew.length())
			sStrString = sStrString.substring(0, iIndex) + sStrNew + sStrString.substring(iIndex + sStrOld.length());
		return sStrString;
	}
	
	// 엑셀문서의 셀자료를 브라우저로 전송합니다.
	private String mCellMap(PrintWriter out, MyData data, int row, int col, String TheText, String TheText2, String TheText3, boolean isDate) throws Exception
	{
//		System.out.println("row : " + row + " : " + col + " : " + isDate);
//		System.out.println("TheText : " + TheText + " TheText2 : " + TheText2 + " TheText3 : " + TheText3);

		StringBuffer sb = new StringBuffer();
		
		int i;
		int ExcelColumnNo = 0;

		// 헤더분석
		if (row == data.headerRows+data.StartRow - 2 && (data.Mode.toLowerCase().equals("headermatch") || data.Mode.toLowerCase().equals("headerskip")) && data.isColumnMapping == false) // 헤더자료면 헤더-컬럼속성 자료 준비
		{
			String headerText = TheText;

			headerText = replace(headerText, "(*)", "");

			if(data.Mode.toLowerCase().equals("headermatch"))
			{
				for (int j = 0; j < data.HeaderText[data.headerRows - 1].length; j++)
				{
					data.HeaderText[data.headerRows - 1][j] = replace(data.HeaderText[data.headerRows-1][j], "\r\n", "\n");
					if (data.HeaderText[data.headerRows - 1][j].equals(headerText) && data.UsedCol[j] == false)
					{
						for (int k = 0; k < data.SaveName.length; k++)
						{
							data.fileSaveName[k][col] = data.SaveName[k][j];
							data.fileRecordType[k][col] = data.RecordType[k][j];
							data.fileRecordFormat[k][col] = data.RecordFormat[k][j];
							data.fileDatePattern[k][col] = data.DatePattern[k][j];
							data.UsedCol[j] = true;
						}
						break;
					}
				}
			} else if(data.Mode.toLowerCase().equals("headerskip")) {
				for (int j = 0; j < data.SaveName[0].length; j++)
				{
					for (int k = 0; k < data.SaveName.length; k++)
					{
						data.fileSaveName[k][j] = data.SaveName[k][j];
						data.fileRecordType[k][j] = data.RecordType[k][j];
						data.fileRecordFormat[k][j] = data.RecordFormat[k][j];
						data.fileDatePattern[k][j] = data.DatePattern[k][j];
					}
				}
			}
		}

		if(row == 0 && data.Mode.toLowerCase().equals("noheader"))
		{
			for (int j = 0; j < data.SaveName[0].length; j++)
			{
				for (int k = 0; k < data.SaveName.length; k++)
				{
					data.fileSaveName[k][j] = data.SaveName[k][j];
					data.fileRecordType[k][j] = data.RecordType[k][j];
					data.fileRecordFormat[k][j] = data.RecordFormat[k][j];
					data.fileDatePattern[k][j] = data.DatePattern[k][j];
				}
			}
		}
		// 데이터 처리
		if (row < data.headerRows+data.StartRow-1) // 데이타이면 헤더컬럼속성 따라 매핑
			return sb.toString();

//		if(data.Mode.toLowerCase().equals("headermatch") && !data.HeaderMatch[col])
//			return;


		int rowNumber = (row - data.headerRows+data.StartRow - 1) % data.RecordType.length;

		if(data.TempRow_StatusCol!=row) //그리드에 상태 컬럼있으면 상태값 I 강제 추가
		{
			if(!data.StatusCol.equals(""))
			{
				sb.append(data.StatusCol+":\"I\",");
				excelData.getCurrentItem().setData(data.StatusCol, "I");
				
				data.TempRow_StatusCol = row;
			}
		}

		if((""+data.fileSaveName[rowNumber][col]).equals("")){return sb.toString();} //SaveName 못찾은 항목은 제외됨

		// 0.0 이 1처럼 체크되는 현상
		if(" CheckBox Radio DelCheck ".indexOf(" "+data.colType[col]+" ")>-1)
		{
			if(TheText.equals("0.0"))
			{
				TheText = "0";
			}
		}

		// 소수타입에서 소수점 짤림 현상
		if(" AutoSum AutoAvg Float NullFloat ".indexOf(" "+data.fileRecordType[rowNumber][col]+" ")>-1)
		{
			//TheText = TheText2;
		}


		if(data.isColumnMapping) //컬럼매핑
		{
			//var col = "|||1||||4|||3||||||||||||||||||||||8";

			for(i=0;i<data.ColumnMapping.length;i++)
			{
				ExcelColumnNo = Integer.parseInt("0"+data.ColumnMapping[i]);
				if(ExcelColumnNo>0 && (col+1)==ExcelColumnNo)
				{
					//if(isDate  || !"".equals(data.DatePattern[rowNumber][i]))		// 날자 데이터 변환
					if(!"".equals(data.DatePattern[rowNumber][i]))		// 날자 데이터 변환
					{
						if(isDate && !"".equals(TheText3))
							TheText = getDateValue(data, TheText3, rowNumber, i);
					}

					// 소수타입에서 소수점 짤림 현상
					if(" Status ".indexOf(" "+data.RecordType[0][i]+" ")>-1)
					{
						;// 레코드별로 엑셀에 상태컬럼없어도 그리드에 상태컬럼있으면 강제로라도 설정해야 해서 일단 여기서 처리하지 않음.
					}
					else
					{
						if(i<data.saveNameOrg.length)
						{
							if(!data.isFirst)
							{
								sb.append(",");
							}
							//out.print(data.SaveName[0][i]+":\""+TheText.replace("\r","\\\\r").replace("\n","\\\\n").replace("\"","\\\\\"").replace("'","\\\'")+"\"");
							TheText = replace(TheText,"\r","\\\\r");
							TheText = replace(TheText,"\n","\\\\n");
							TheText = replace(TheText,"\"","\\\\\"");
							TheText = replace(TheText,"'","\\\'");
							sb.append(data.SaveName[0][i]+":\""+TheText+"\"");
							excelData.getCurrentItem().setData(data.SaveName[0][i], TheText);
							
							data.isFirst = false;
						}
					}
				}
			}
		}
		else //일반
		{
			//if(isDate || !"".equals(data.fileDatePattern[rowNumber][col]))		// 날자 데이터 변환
			if(!"".equals(data.fileDatePattern[rowNumber][col]))		// 날자 데이터 변환
			{
	//System.out.println("data.DatePattern[" + rowNumber + "][" + col + "] : " + data.DatePattern[rowNumber][col]);
	//System.out.println(col + " : " + TheText + " : " + TheText3);
	//System.out.println(Arrays.deepToString(data.fileRecordType));
	//System.out.println(Arrays.deepToString(data.fileDatePattern));
				if(isDate && !"".equals(TheText3))
					TheText = getDateValue(data, TheText3, rowNumber, col);
			}

			// 소수타입에서 소수점 짤림 현상
			if(" Status ".indexOf(" "+data.fileRecordType[0][col]+" ")>-1)
			{
				return sb.toString(); // 레코드별로 엑셀에 상태컬럼없어도 그리드에 상태컬럼있으면 강제로라도 설정해야 해서 일단 여기서 처리하지 않음.
			}
			if(data.fileSaveName[0][col]!=null)
			{
				if(!data.isFirst)
				{
					sb.append(",");
				}
				//out.print(data.SaveName[0][col]+":\""+TheText.replace("\r","\\\\r").replace("\n","\\\\n").replace("\"","\\\\\"").replace("'","\\\'")+"\"");
				TheText = replace(TheText,"\r","\\\\r");
				TheText = replace(TheText,"\n","\\\\n");
				TheText = replace(TheText,"\"","\\\\\"");
				TheText = replace(TheText,"'","\\\'");
				sb.append(data.fileSaveName[0][col]+":\""+TheText+"\"");
				excelData.getCurrentItem().setData(data.fileSaveName[0][col], TheText);

				data.isFirst = false;
			}
		}

		return sb.toString();
	}

	private String getDateValue(MyData data, String date, int row, int col) throws Exception
	{
		String datePattern = "";
		if(data.isColumnMapping)
			datePattern = data.DatePattern[row][col];
		else
			datePattern = data.fileDatePattern[row][col];

		if(date == null || "".equals(date) || datePattern == null || "".equals(datePattern) )
			return "";

		String retVal = "";

		retVal = mDateValue(date, datePattern);

		return retVal;
	}
	
	private String mDateValue(String dateLongValue, String datePattern) throws Exception
	{
		SimpleDateFormat df = null;
		if(datePattern.equals("YmdHmsFormat"))
		{
			df = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
		}
		if(datePattern.equals("YmdHmFormat"))
		{
			df = new SimpleDateFormat("yyyy-MM-dd HH:mm");
		}
		if(datePattern.equals("YmdFormat"))
		{
			df = new SimpleDateFormat("yyyy-MM-dd");
		}
		if(datePattern.equals("YmFormat"))
		{
			df = new SimpleDateFormat("yyyy-MM");
		}
		if(datePattern.equals("MdFormat"))
		{
			df = new SimpleDateFormat("MM-dd");
		}
		if(datePattern.equals("HmsFormat"))
		{
			df = new SimpleDateFormat("HH:mm:ss");
		}
		if(datePattern.equals("HmFormat"))
		{
			df = new SimpleDateFormat("HH:mm");
		}

		return df.format(new Date(Long.parseLong(dateLongValue)));
	}
	
	@Override
	protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
		doPost(request, response);
	}
}
