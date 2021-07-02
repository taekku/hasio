package h5.servlet.vo;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;
import java.util.regex.Pattern;
import java.util.stream.Collectors;
import java.util.stream.Stream;


public class ChatbotItem {

    public String pk_id;
    private String serviceName; // 서비스명
    private String typeCd; // 구분
    private String seq; //순차
    private String sqlId; //SQLID
    private String baseParam; // 기본파라메터
    private String content; // 내용
    public BigDecimal parent_pk_id = new BigDecimal(0);
    String[] search_keyword = null;
    
    
    private List<ChatbotItem> childs;
    
    
    public List<ChatbotItem> getChilds() {
		return childs;
	}

	public void setChilds(List<ChatbotItem> childs) {
		this.childs = childs;
	}

	public String[] getSearch_keyword() {
		return search_keyword;
	}

	public void setSearch_keyword(String[] search_keyword) {
		this.search_keyword = search_keyword;
	}

	String[] syns; //키워드 문자 스플릿
    public Pattern pattern;
    String response_text;
    
    public void addChild( ChatbotItem child ) {
    	
    	BigDecimal pk_idB = new BigDecimal(pk_id);
    	
    	//System.out.println("addChild 함수 --> pk_idB : " + pk_idB  );
    	
    	//System.out.println("  child.getParent_pk_id() : " +  child.getParent_pk_id() );
    	//System.out.println("  pk_idB: " +  pk_idB );
    	//System.out.println("  compare to : " +  child.getParent_pk_id().compareTo(pk_idB));
    	
    	if ( child.getParent_pk_id().compareTo(pk_idB) == 0 ) {
    		//System.out.println(" addChild함수 -> 같다 : " + child.getParent_pk_id());
    		childs.add(child);
    	}
    }

	public ChatbotItem(String key, String[] syns, String serviceName, String typeCd, String seq, String sqlId, String baseParam, String content , BigDecimal parent_pk_id) {
    	childs = new ArrayList<>();
    	
    	this.parent_pk_id = parent_pk_id;
        this.pk_id = key;
        this.search_keyword = syns;
        this.serviceName = serviceName;
        this.typeCd = typeCd;
        this.seq = seq;
        this.sqlId = sqlId;
        this.baseParam = baseParam;
        this.content = content;
        
		
		
		pattern = Pattern.compile(".*(?:" + Stream.concat(Stream.of(key), Stream.of(syns)).map(x -> "\\b" + Pattern.quote(x) + "\\b").collect(Collectors.joining("|")) + ").*");
    }
    
    @Override
    public String toString() {
    	return content;
    }

	public void setAdditionInfo( String serviceName , String typeCd ) {
		// TODO Auto-generated method stub
		
		this.serviceName = serviceName;
		this.typeCd = typeCd;
	}

	public String getPk_id() {
		return pk_id;
	}

	public void setPk_id(String pk_id) {
		this.pk_id = pk_id;
	}

	public String getServiceName() {
		return serviceName;
	}

	public void setServiceName(String serviceName) {
		this.serviceName = serviceName;
	}

	public String getTypeCd() {
		return typeCd;
	}

	public void setTypeCd(String typeCd) {
		this.typeCd = typeCd;
	}

	public String getSeq() {
		return seq;
	}

	public void setSeq(String seq) {
		this.seq = seq;
	}

	public String getSqlId() {
		return sqlId;
	}

	public void setSqlId(String sqlId) {
		this.sqlId = sqlId;
	}

	public String getBaseParam() {
		return baseParam;
	}

	public void setBaseParam(String baseParam) {
		this.baseParam = baseParam;
	}

	public String getContent() {
		return content;
	}

	public void setContent(String content) {
		this.content = content;
	}
	
	 public BigDecimal getParent_pk_id() {
		return parent_pk_id;
	}

	public void setParent_pk_id(BigDecimal parent_pk_id) {
		this.parent_pk_id = parent_pk_id;
	}
	
}
