package h5.servlet.util;

import java.util.Random;

public class SeqUtil {

	public static int getNextInt(int param){
		Random r = new Random();
		return r.nextInt(param);
	}
}
