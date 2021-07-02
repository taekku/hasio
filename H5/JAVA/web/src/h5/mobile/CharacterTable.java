package h5.mobile;

import java.util.Random;

public class CharacterTable {
	private int certCharLength = 6;
	private final char[] characterTable  = {
			'1', '2', '3', '4', '5', '6', '7', '8', '9', '0'
	};
	
	public String excuteRandomStr(){
		Random random = new Random(System.currentTimeMillis());
		int tableLengh = characterTable.length;
		StringBuffer sb = new StringBuffer();
		for( int i = 0 ; i < certCharLength ; i++){
			sb.append(characterTable[random.nextInt(tableLengh)]);
		}
		return sb.toString();
	}
	
	public static void main(String[] args) {
		CharacterTable st = new CharacterTable();
		System.out.println(st.excuteRandomStr());
	}
}
