package hrms.sys.util.codec;

import org.apache.commons.codec.binary.Base64;

/**
 * base 64 with url and filename safe를 구현(?) 하였다.
 * 기존에 rfc 2045에 정의된 스펙의 구현을(jakarta commons-codec project)확장하였다.
 * 명세는 http://www.ietf.org/rfc/rfc4648.txt 에서 확인 할 수 있으며
 * 이 class에서는 단지 63, 64번째 문자를 replacing 한다.
 * @author 김창수
 *
 */
public class Base64WithUrlNFileNameSafe {
	/**
	 * base64(with url and filename safe) encoding  
	 * @param binaryData
	 * @return
	 */
	public static byte[] encode(byte[] binaryData){
		byte[] encodedData = Base64.encodeBase64(binaryData);
		for (int i = 0 ; i < encodedData.length; i++){
			if(encodedData[i] == '+' ){
				encodedData[i] = '-';//minus
			}else if(encodedData[i] == '/'){
				encodedData[i] = '_'; //underline
			}
		}
		
		return encodedData;
	}
	
	/**
	 * base64(with url and filename safe) decoding
	 * @param encodedData
	 * @return
	 */
	public static byte[] decode(byte[] encodedData){
		for(int i = 0 ; i < encodedData.length ; i++){
			if(encodedData[i] == '-' ){//minus
				encodedData[i] = '+';
			}else if(encodedData[i] == '_'){//underline
				encodedData[i] = '/'; 
			}
		}
		byte[] decodedData = Base64.decodeBase64(encodedData);
		return decodedData;
	}
	
}
