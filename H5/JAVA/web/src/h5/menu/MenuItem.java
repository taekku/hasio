package h5.menu;

import java.util.Iterator;
import java.util.Vector;

/**
 * 메뉴 항목 하나하나를 의미하는 클래스
 * @author win
 *
 */
public class MenuItem {

	String id;
	String menuText;
	String menuClass;
	String objectId;
	boolean isFavorite;
	int level;
	String authCheck;
	
	Vector <MenuItem> childs;
	
	/**
	 * 메뉴 항목을 초기화 한다.
	 * @param id 메뉴아이디
	 * @param menuText 메뉴 텍스트
	 * @param level 메뉴 수준
	 * @param objectId 연결 오브젝트 id
	 * @param authCheck 권한 체크 여부
	 */
	public MenuItem(String id, String menuText, int level, String objectId, String authCheck, boolean isFavorite){
		this.id = id;
		this.menuText = menuText;
		this.level = level;
		this.objectId = objectId;
		this.authCheck = authCheck;
		this.isFavorite = isFavorite;
	}
	
	public void addChild(MenuItem item){
		if(childs == null)
			childs = new Vector<MenuItem>();
		childs.add(item);
	}
	
	public String toMenuString(){
		StringBuffer sb = new StringBuffer();
		String openTag = null;
		String closeTag = null;
		
		if(level == 1){
			openTag = "<ul class=\"d1\"  > \n"+getMenuTextTag();
			closeTag = "</ul>\n";	
		}
		else if(level ==2){
			openTag = "<ul class=\"d2 hideMenu\" > \n"+getMenuTextTag();
			closeTag = "</ul>\n";
		}
		else{
			openTag = "\n"+getMenuTextTag();
			closeTag = "\n";
		}
		if(childs != null){
			Iterator <MenuItem> itor = childs.iterator();
			
			if(level == 2){
				openTag += "\t<div class=\"d3 hideMenu\">\n\t\t <ul>\n ";
				closeTag = "\n\t\t </ul> \n\t</div> " +closeTag;
			}
				
			while(itor.hasNext()){
				MenuItem item = itor.next();
				if(item != null)
					sb.append(item.toMenuString());
			}
			
		}
		return openTag+sb.toString()+closeTag;
	}
	
	protected String getMenuTextTag(){

		 if(level == 1){
			 if(childs == null){
				 return "\t<li id=\""+this.id+"\" class=\"showMenu m s2\" >"+menuText+"</li>\n";
			 }else{
				 return "\t<li id=\""+this.id+"\" class=\"showMenu m\" >"+menuText+"</li>\n";
			 }
			 
		 }else if(level == 2){
			 if(childs == null){
				 return "\t<li id=\""+this.id+"\" class=\"hideMenu m nochild\">"+menuText+"</li>\n";
			 }else{
				 return "\t<li id=\""+this.id+"\" class=\"hideMenu m\">"+menuText+"</li>\n";
			 }
		 }else{
			 return "\t<li id=\""+this.id+"\" class=\"hideMenu m\">"+menuText+"</li>\n";
		 }
	}
}
