package h5.servlet.util;

import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.regex.Pattern;

import org.json.simple.JSONArray;
import org.json.simple.JSONObject;

import com.win.frame.invoker.GridResult;
import com.win.rf.invoker.SQLInvoker;

import h5.servlet.vo.ChatbotItem;
import h5.sys.util.DBUtil;

public class ChatbotUtil {

	private List<ChatbotItem> chatbotData;
	PreparedStatement stmt = null;
	ResultSet rset = null;
	
	private static final int LIMIT_OF_FIND_ITEM = 4;

	
	public ChatbotUtil(String company_cd) {
		init( company_cd );
	}
	
	private void init(String company_cd) {
		chatbotData = loadChatbotItems( company_cd );
	}

	public List<ChatbotItem> findItem(String keyword) {
		List<ChatbotItem> findResult = new ArrayList<>();
		
		int itemcount = 0;
		int matchingCnt = 0;
		String entryPk = "";
		
		//검색 키워드가 같은 놈들만 뽑아 낼때 도는 for문
		for (ChatbotItem entry : chatbotData) {
			if (entry.pattern.matcher(keyword).matches()) {
				matchingCnt++;
				
				findResult.add(entry);
			}
			
			if ( matchingCnt == LIMIT_OF_FIND_ITEM) {
				return findResult;
			}
		}//for
		
		// 검색 문자가 매칭된 PK와 로드된 Data중에 부모의 PK와 같은게 있으면 결과값에 더해주기
		if (matchingCnt < 2) { 
			// 검색키워드를 검색 했을 때 자식들이 걸리면 도는 for문
			for (ChatbotItem entry : chatbotData) {
				// 매칭된 검색결과값들이 여러개가 나올 경우 자식들 값을 빼오면 문제가 있음 해당 검색 결과에 대한 리스트만 뿌려주자
				if (entryPk.equals(entry.getParent_pk_id())) {
					findResult.add(entry);
				}

				itemcount++;

				if (itemcount == LIMIT_OF_FIND_ITEM) {
					return findResult;
				}
			}
		}
		
		
		return findResult;
	}

	private  List<ChatbotItem> loadChatbotItems( String company_cd ) {
		List<ChatbotItem> responses = new ArrayList<>();
		Connection con = null;
		
		StringBuffer sb = new StringBuffer();
		
		String pk_id = "";
		String search_keywords = "";
		String service_nm = "";
		String type_cd = "";
		String seq = "";
		String sqlId = "";
		String baseParam = "";
		String content = "";
		BigDecimal parent_chatbot_manage_id = null;
		
		try {
			con = DBUtil.getConnection();
			
			sb.append(" SELECT "
					+ "	A.chatbot_manage_id, "
					+ "	A.service_nm, "
					+ "	A.company_cd, "
					+ "	A.type_cd, "
					+ "	A.seq, "
					+ "		( "
					+ "	SELECT "
					+ "		STRING_AGG(SEARCH_KEYWORD, ',') AS SPSK "
					+ "	FROM "
					+ "		FRM_CHATBOT_SERVICE_PARAM B "
					+ "	WHERE "
					+ "		A.CHATBOT_MANAGE_ID = B.CHATBOT_MANAGE_ID "
					+ "		) AS search_keywords, "
					+ "	A.sqlid, "
					+ "	A.basic_parameter, "
					+ "	A.content, "
					+ "	ISNULL(A.parent_chatbot_manage_id, 0) AS parent_chatbot_manage_id, "
					+ "	A.SEQ AS seq_order "
					+ " FROM "
					+ "	FRM_CHATBOT_MANAGE A "
					+ " WHERE A.COMPANY_CD = ? "
					+ " ORDER BY "
					+ "    SEQ ");
			
			stmt = con.prepareStatement(sb.toString());
			stmt.setString(1, company_cd);
			
			rset = stmt.executeQuery();
			
			while(rset.next()){
				pk_id = rset.getString("chatbot_manage_id");
				search_keywords = rset.getString("search_keywords");
				service_nm = rset.getString("service_nm");
				type_cd = rset.getString("type_cd");
				seq = rset.getString("seq");
				sqlId = rset.getString("sqlid");
				baseParam = rset.getString("basic_parameter");
				content = rset.getString("content");
				parent_chatbot_manage_id = rset.getBigDecimal("parent_chatbot_manage_id");
			
				String sWords[] = {}; 
				
				if ( search_keywords != null ){
					sWords = search_keywords.split(",");
				}
				
				ChatbotItem temp = new ChatbotItem(pk_id, sWords, service_nm, type_cd, seq, sqlId, baseParam, content , parent_chatbot_manage_id);
				
				responses.add(temp);
			}
			
			sb = null;
			
			
		} catch (SQLException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		} finally {
			try{
				if(rset != null) rset.close();
			} catch(Exception e) {}
			try{
				if(stmt != null) stmt.close();
			} catch(Exception e) {}
			try{
				if(con != null) con.close();
			} catch(Exception e) {}
		}		
		//responses.add(new ChatbotItem("인사정보조회", "내정보" , "나의 정보"));
		//responses.add(new ChatbotItem("잔여연차", "연차" , "잔여연차"));
		
		List<ChatbotItem> tempArray = new ArrayList<>();
		
		tempArray.addAll(responses);
		
		for ( ChatbotItem parent : responses ) {
			for ( ChatbotItem temp : tempArray ) {
				parent.addChild(temp);
			}
		}

		return responses;
	}

	public ChatbotItem findItemById(String pkId) {
		for ( ChatbotItem temp : chatbotData ) {
			if ( temp.pk_id.equals(pkId)) {
				return temp;
			}
		}
		return null;
	}
	
	public JSONObject processResult( ChatbotItem resultItem) {
		JSONObject resultObj = new JSONObject();
		JSONArray array = new JSONArray();
		
		// 누른 PK에 속한 자식들 가져오기 
		List<ChatbotItem> childResultItem = resultItem.getChilds();
		
		//typeCd가 메뉴인지 서비스인지 
		String typeCd = resultItem.getTypeCd();
		String service_name = resultItem.getServiceName();
		String content = resultItem.getContent();
		String sqlId = resultItem.getSqlId();
		String draw_type = "";
		String pkId = resultItem.getPk_id();
		String parameter = resultItem.getBaseParam();
		String newTxt = "";
		
		if( typeCd.equals("100")) {
			//부모의 content내용은 뿌려줘야 한다. 
			HashMap hashMap = new HashMap();
			
			hashMap.put("pk_id", resultItem.getPk_id());
			hashMap.put("content", resultItem.getContent());
			hashMap.put("draw_type", "msg");
			
			array.add(hashMap);
			
			if( childResultItem.size() > 0  ) {
				for( ChatbotItem tempChildResultItem : childResultItem) {
					HashMap hashMapChild = new HashMap();
					
					hashMapChild.put("pk_id", tempChildResultItem.getPk_id());
					hashMapChild.put("service_name", tempChildResultItem.getServiceName());
					hashMapChild.put("draw_type", "icon");
					
					array.add(hashMapChild);
				}
			}
		} else if( typeCd.equals("200")) {
			//클릭한 서비스건에 대해서는 항상 content에 대한 결과값 하나만 전달하자
			if (sqlId != null) {
				HashMap hashMap = new HashMap();
				// SQL ID로 쿼리를 타고 기본 파라미터로 ',' 구분자에 따라 주소바인딩으로 파라미터를 넣어주자
				newTxt = getSearchSqlResult(parameter, sqlId, content);

				hashMap.put("content", newTxt);
				hashMap.put("draw_type", "msg");
				hashMap.put("pk_id", pkId);

				array.add(hashMap);
			} else {
				HashMap hashMap = new HashMap();

				hashMap.put("content", content);
				hashMap.put("draw_type", "msg");
				hashMap.put("pk_id", pkId);

				array.add(hashMap);
			}
		}
		
		resultObj.put("result_cd", "SUCCESS!");
		resultObj.put("result", array );
		
		return resultObj;
		
	}
	
	
	public JSONObject processResult( List<ChatbotItem> resultItems) {
		JSONObject resultObj = new JSONObject();	
		
		if ( resultItems.size() == 0 ) {
			resultObj = processZero();
		} else if ( resultItems.size() == 1 ) {
			resultObj = processOne( resultItems );
		} else if ( resultItems.size() >  1 ) {
			resultObj = processMany( resultItems );
		}
		
		return resultObj;
	}
	
	private JSONObject processZero() {
		
		JSONObject resultObj = new JSONObject();
		
		// 찾는게 없어요
		String resultMsg = "결과가 존재하지 않습니다.";
		
		JSONArray array = new JSONArray();
		
		HashMap temp = new HashMap();
		
		temp.put("result_msg", resultMsg);
		temp.put("draw_type", "msg");
		
		array.add(temp);
		
		resultObj.put("result_cd", "FAILURE!");
		resultObj.put("result", array);
		
		
		return resultObj;
	}
	
	
	private JSONObject processOne( List<ChatbotItem> resultItems ) {
		//키워드를 쳤는데 결과값이 한개만 나왔을때
		JSONArray array = new JSONArray();
		JSONObject resultObj = new JSONObject();
		
		if( "100".equals(resultItems.get(0).getTypeCd())) {	// 메뉴
			HashMap hashMap = new HashMap();
			
			//내 정보
			hashMap.put("draw_type", "msg");
			hashMap.put("content", resultItems.get(0).getContent());
			hashMap.put("typeCd", resultItems.get(0).getTypeCd());
			hashMap.put("sqlId", null);
			hashMap.put("pk_id", resultItems.get(0).getPk_id());
			
			array.add(hashMap);
			
			for ( ChatbotItem child : resultItems.get(0).getChilds()) {
				HashMap hashMapChild = new HashMap();
				
				hashMapChild.put("service_name", child.getServiceName());
				hashMapChild.put("draw_type", "icon");
				hashMapChild.put("typeCd", child.getTypeCd());
				hashMapChild.put("pk_id", child.getPk_id());
				
				array.add(hashMapChild);
			}
			
		} else if( "200".equals(resultItems.get(0).getTypeCd())) {	// 서비스
			
			// typeCd 가 서비스
			// SQL ID 가 있을 경우
			// SQL 실행해서 나온결과로 content replace 해서 반환
			
			String sqlId = resultItems.get(0).getSqlId();
			String parameter = resultItems.get(0).getBaseParam();
			String content = resultItems.get(0).getContent();
			String newTxt = "";
			
			if( sqlId != null ) {
				HashMap hashMap = new HashMap();
				//SQL ID로 쿼리를 타고 기본 파라미터로 ',' 구분자에 따라 주소바인딩으로 파라미터를 넣어주자
				
				newTxt = getSearchSqlResult(parameter, sqlId, content);

				hashMap.put("draw_type", "msg");
				hashMap.put("content", newTxt);
				hashMap.put("typeCd", resultItems.get(0).getTypeCd());
				hashMap.put("sqlId", sqlId);
				hashMap.put("pk_id", resultItems.get(0).getPk_id());
				
				array.add(hashMap);
				
				
			} else {
				HashMap hashMap = new HashMap();
				// SQL ID 가 없을 경우
				// 그냥 content 반환
				hashMap.put("draw_type", "msg");
				hashMap.put("content", resultItems.get(0).getContent());
				hashMap.put("typeCd", resultItems.get(0).getTypeCd());
				hashMap.put("sqlId", null);
				hashMap.put("pk_id", resultItems.get(0).getPk_id());
				
				array.add(hashMap);
			}
			
		} // typeCd = "200"

			
		resultObj.put("result_cd", "SUCCESS!");
		resultObj.put("result", array );
		
		return resultObj;
	}
	
	
	private JSONObject processMany( List<ChatbotItem> resultItems ) {
		JSONObject resultObj = new JSONObject();
		JSONArray array = new JSONArray();
		String resultMsg = "";
		
		
		for (ChatbotItem temp : resultItems) {
			resultMsg += temp.getPk_id() + "," + temp.getServiceName() + "," + temp.getTypeCd() + "<br/>";
			HashMap hashMap = new HashMap();
			
			hashMap.put("draw_type", "icon");
			hashMap.put("service_name", temp.getServiceName() );
			hashMap.put("pk_id", temp.getPk_id());
			hashMap.put("sqlId", temp.getSqlId());
			
			array.add(hashMap);
		}

		resultObj.put("result_cd", "SUCCESS!");
		resultObj.put("result", array );
		
		return resultObj;
	} //processMany
	
	
	//챗봇 Service 기능 중 SqlId가 있는 놈들은 디비에서 조회 해와서 결과값을 #~#값과 취환하여 String 으로 결과값을 반환해주자
	public String getSearchSqlResult( String parameter, String sqlId, String content ) {
		String newText = "";
		
		String[] paramArray = parameter.split(",");
		StringBuffer sb  = new StringBuffer();
		HashMap paramMap = new HashMap();
		
		for( int i=0; i < paramArray.length; i++) {
			paramMap.put(("" + (i+1)), paramArray[i]);
		}
		
		try {
        	SQLInvoker invoker = new SQLInvoker(sqlId, paramMap);
			GridResult result = (GridResult)invoker.doService();
			newText = content;
			
			result = (GridResult)invoker.doService();
			
			if(result.next()){
				//내용값 안에 있는 #~#의 값들을 뺴내서 #을 없애고 getValueString의 인자값으로 넣어줘서 값을 얻어내자!
				
				String reg = "[#](.*?)[#]";
				
				Pattern pattern = Pattern.compile(reg);
				java.util.regex.Matcher matcher = pattern.matcher(content);
				
				while(matcher.find()) {
					String matchString = matcher.group(1);
					
					//#을뺀 컬럼명들이 출력된다.
					newText = newText.replace("#"+matchString+"#", result.getValueString(matchString) );
				
					if(matcher.group(1) == null)
						break;
				}
			} 
				
		} catch (Exception e) {
			e.printStackTrace();
		}
		
		return newText;
	}

}
