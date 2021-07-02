package h5.menu;

import java.util.HashMap;
import java.util.Iterator;
import java.util.Vector;

import com.win.frame.invoker.GridResult;

/**
 * 좌측 메뉴를 만드는 클래스
 * @author win
 *
 */
public class MenuGenerator {

	GridResult result = null;
	HashMap <String, MenuItem> itemMap;
	Vector<MenuItem> rootItems;
	StringBuffer menuData = null;
	
	/**
	 * 생성자, 좌측 메뉴의 목록을 파라미터로 받아 초기화 한다.
	 * @param result
	 */
	public MenuGenerator(GridResult result){
		this.result = result;
		itemMap = new HashMap<String, MenuItem>();
		rootItems = new Vector<MenuItem>();
		menuData = new StringBuffer();
		
		menuData.append("var md = {}; ");
		
		while(result != null && result.next()){
			String menuText = result.getValueString("title");
			int level = Integer.parseInt(result.getValueString("level"));
			String authCheck = result.getValueString("auth_check");
			String objectId = result.getValueString("object_id");
			String parentMenuId = result.getValueString("parent_menu_id");
			String menuId = result.getValueString("menu_id");
			boolean isFavorite = false;
			if(result.getValueString("is_favorite") != null && "Y".equals(result.getValueString("is_favorite")))
				isFavorite = true;

			// 메뉴 데이터를 구성한다.
			
			menuData.append(" md['"+menuId+"'] = {'object_id':'"+objectId+"', 'auth_check':'"+authCheck+"', 'menu_nm':'"+menuText+"', 'is_favorite':'"+(isFavorite == true ? "Y" : "N" )+"'  }; ");
			
			// 메뉴 구조를 구성한다.
			MenuItem item = new MenuItem(menuId, menuText, level, objectId, authCheck, isFavorite);
			
			itemMap.put(menuId,item);
			
			if(itemMap.containsKey(parentMenuId)){
				MenuItem pMenu = itemMap.get(parentMenuId);
				if(pMenu != null)
					pMenu.addChild(item);
			}
			if(level == 1)
				rootItems.add(item);

		}
	
	}
	
	/**
	 * 메뉴 문자열을 반환한다.
	 * @return
	 */
	public String getMenuString(){

		Iterator <MenuItem>itor = rootItems.iterator();
		StringBuffer sb = new StringBuffer();
		while(itor.hasNext()){
			sb.append(itor.next().toMenuString());
		}
		
		return sb.toString();
	}
	
	/**
	 * 메뉴 데이터 문자열을 반환한다.
	 * @return
	 */
	public String getMenuData(){
		return menuData.toString();
	}
	
}
