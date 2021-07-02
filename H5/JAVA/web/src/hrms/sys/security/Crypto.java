package hrms.sys.security;

import hrms.sys.util.codec.Base64WithUrlNFileNameSafe;

import java.security.InvalidKeyException;
import java.security.Key;
import java.security.KeyPair;
import java.security.KeyPairGenerator;
import java.security.NoSuchAlgorithmException;
import java.security.PrivateKey;
import java.security.PublicKey;
import java.util.HashMap;
import java.util.Iterator;

import javax.crypto.Cipher;
import javax.crypto.KeyGenerator;
import javax.crypto.NoSuchPaddingException;
import javax.servlet.http.HttpSession;

/**
 * 암호화 복호화를 담당하는 class이다
 * RSA 암호화를 사용했으며, 
 * 암호화 복호화 모두 서버에서 하기때문에 (DES를 사용해도 무방하지만, 이미 깨어진 전력이 있으므로) 
 * 서버 이외에 키를 노출시킬 필요가 없어서 당연히 key distribution 작업은 없다.
 * @author 김창수
 *
 */
public class Crypto {
	protected static final int ENCRYPT_MODE = Cipher.ENCRYPT_MODE; 
	protected static final int DECRYPT_MODE = Cipher.DECRYPT_MODE; 
	
	private static final String PRIVATE_KEY_NAME = "CRYPTO_PRIVATE_KEY";
	private static final String PUBLIC_KEY_NAME = "CRYPTO_PUBLIC_KEY";
	
	
	private static boolean viewLog = true;
	/**
	 * 특정 domain에 해당하는 것들을 암호한다.
	 * @param domain    : 평문(암호화되지 않은)의 domain (ex. tableName, sequenceObjectName....
	 * @param plainText : 평문
	 * @param session   : 개인의 암호화 key를 가지고 있다.
	 * @return
	 */
	public static String encryptMsg(String domain, String plainText, HttpSession session)throws Exception{
		String encryptMsg = "";		
		if(isValidDomain(domain)){
			try{
				if (!plainText.equals(""))
					encryptMsg = doCipher(ENCRYPT_MODE, plainText, session);
			}catch(Exception e){
				e.printStackTrace();
				throw e;
			}
		}else{
			encryptMsg = plainText;
		}
		return encryptMsg;
	}
	
	/**
	 * mode 값에 따라 soruce data(message)를 암호화/복호화한다.
	 * 이때 암호화 결과(convertedBytes)가 byte[]이므로 이것을 String으로 변환할때 소실되는 부분이 있을수 있으므로 BASE64 codec를 사용하여 encoding하였으며
	 * 반대로 복호화 대상(암호화된)이 BASE64로 encoding 된 것이므로 다시 BASE64로 Decoding 하는 작업이 필요하다. 
	 * @param mode
	 * @param message
	 * @param session
	 * @return
	 * @throws Exception
	 */
	private static String doCipher(int mode, String message, HttpSession session) throws Exception{
		byte[] cipherBytes;
		
		//복호화 대상은 base64로 encoding 된 것이므로 base64로 decoding 한다.
		if(mode == ENCRYPT_MODE){
			cipherBytes = message.getBytes();
		}else if(mode == DECRYPT_MODE){
			//BASE64Decoder decoder = new BASE64Decoder();
			//cipherBytes = decoder.decodeBuffer(message);
			cipherBytes = Base64WithUrlNFileNameSafe.decode(message.getBytes());
		}else{
		    throw new Exception("암호화(복호화)모드가 잘못되었습니다. :: " + mode);
		}
		
		/*
		 * Provider를 직접 만들어서 getAsymmetricKey를 사용할수 있는 방법을 고려
		 * BounceCastle 사이트 참조 - 암호화 관련 Lab
		 * 2007.10.13 김석환, 김창수
		 */
		//Key key = getAsymmetricKey(mode, session); //mode에 따라서 Public Key, Private Key를 선택적으로 가져옴 (WebSphere-OK, WebLogic-NO)
        Key key = getSymmetricKeyArray(mode, session); //Single Key로서 mode에 상관없이 Key를 가져옴 (WebSphere-OK, WebLogic-OK)
		byte[] convertedBytes = doFinal(mode, cipherBytes, key);
		
		//암호화 결과가 소실 될 수 있으므로, base64로 encoding 한다.
		if(mode == ENCRYPT_MODE){
			//BASE64Encoder encoder = new BASE64Encoder();
			//return new String(encoder.encode(convertedBytes));
			return new String(Base64WithUrlNFileNameSafe.encode(convertedBytes));
		}else if(mode == DECRYPT_MODE){
			return new String(convertedBytes);
		}else{
		    throw new Exception("암호화(복호화)모드가 잘못되었습니다. :: " + mode);
		}
	}
	
	/**
	 * mode에 따라 세션에 저장된 Key(PrivateKey or PublicKey)를 리턴한다.
	 * 암호화 모드에서는 세션에 저장된 key가 없을 경우 새로생성해서 리턴해주고
	 * 복호화 모드에서는 세션에 저장된 key가 없을 경우 에러를 던진다.
	 * @param mode
	 * @param session
	 * @return
	 * @throws Exception
	 */
	private static Key getAsymmetricKey(int mode, HttpSession session)throws Exception{
		Key key ;
		if(mode == ENCRYPT_MODE){
			key = (PublicKey)session.getAttribute(PUBLIC_KEY_NAME);
			if(key == null){
			    createAsymmetricKey(session);
				key = (PublicKey)session.getAttribute(PUBLIC_KEY_NAME);
			}
		}else if(mode == DECRYPT_MODE){
			key = (PrivateKey)session.getAttribute(PRIVATE_KEY_NAME);
		}else{
			throw new Exception("");
		}
		return key;
	}
	
	/**
	 * 키를 생성해서 세션에 저장한다.
	 * @param session
	 * @throws Exception
	 */
	private static void createAsymmetricKey(HttpSession session)throws Exception{
		KeyPairGenerator kGen = KeyPairGenerator.getInstance("RSA");
		kGen.initialize(1024);
		
		KeyPair kPair = kGen.genKeyPair();
		PrivateKey privateKey = kPair.getPrivate();
		PublicKey publicKey = kPair.getPublic();
		
		session.setAttribute(PRIVATE_KEY_NAME, privateKey);
		session.setAttribute(PUBLIC_KEY_NAME, publicKey);
	}
	/**
	 * key를 생성한다.
	 * 로그인자의 session 정보를 사용해서 key를 생성한다.
	 * 따라서 생성된 키는 같은 session time 동안 만 유효하다.
	 * DES Algorithm을 사용하므로 key의 길이는 반드시 8의 배수여야한다.
	 * ENCRYPT_MODE일경우는session 에 키가 없을 경우 새로 생성한다, 
	 * 하지만, DECRYPT_MODE일 경우는 예외를 던진다. 
	 * @param session 사용자(logined user)의 session
	 * @return
	 */
	private static Key getSymmetricKeyArray(int mode, HttpSession session) throws Exception{
		Key key;
		String cryptoKeyName = "_CRYPTO_KEY";
		Object oKey = session.getAttribute(cryptoKeyName);
		
		if(oKey == null){
			if(mode == DECRYPT_MODE){
				throw new Exception("복호화 모드 에서는 키를 다시 생성할 수 없습니다.\n세션이 끊어졌거나, 내부적인 오류가 발생했습니다.");
			}
			KeyGenerator keyGen = KeyGenerator.getInstance("DES");
			keyGen.init(56);
			key = keyGen.generateKey();
			session.setAttribute(cryptoKeyName, key);
		}else{
			key = (Key)oKey;
		}
		
		return key;		
	}
	/**
	 * 암호화 복화화를 담당하는 함수이다.
	 * @param mode 암호화/복호화를 결정한다.
	 * @param message 암호화/복호화 대상 message
	 * @param key 암호화/복호화 key(반드시 8 x N 자리 여야한다. .. DES 알고리즘을 사용하므로)
	 * @return
	 * @throws Exception
	 */
	private static byte[] doFinal(int mode, byte[] message, Key key)throws Exception{
		byte[] cipherText = null;

		//String transfomation = "RSA/ECB/PKCS1Padding"; //WebSphere-OK, WebLogic-NO	
		String transfomation = "DES"; //WebSphere-OK, WebLogic-OK
/*		
		System.out.println("################## Provider Test - Start ####################");
		java.security.Provider[] provider = Security.getProviders(); 
		for(int i=0; i<provider.length; i++){
			
			System.out.println("Info:" + provider[i].getInfo());
			System.out.println("Name:" + provider[i].getName());
			//System.out.println("Name:" + provider[i].);
			Enumeration enum = provider[i].propertyNames();
			while(enum.hasMoreElements()){
				String name = (String)enum.nextElement();
				String value = provider[i].getProperty(name);
				System.out.println("Name:" + name + "::" +value );
			}
			System.out.println("===============================");
		}
		System.out.println("################ Provider Test - End #######################");
*/		
		try {
			Cipher cipher = Cipher.getInstance(transfomation);

			cipher.init(mode, key);
			cipherText = cipher.doFinal(message);

		} catch (NoSuchAlgorithmException e) {
			e.printStackTrace();
			throw new Exception("암호화/복호화 알고리즘 명이 잘못되었습니다. :: " + transfomation);
		} catch (NoSuchPaddingException e) {
			e.printStackTrace();
			throw new Exception("Padding Algorithm이 잘못되었습니다. :: " + transfomation);
		} catch (InvalidKeyException e) {
			e.printStackTrace();
			throw new Exception("Key 가 유효하지 않습니다. ");
		} catch (Exception e) {
			e.printStackTrace();
			throw new Exception("암호화/복호화중 예외가 발생했습니다.");
		}
		return cipherText;
	}
	/**
	 * 특정 domain에 해당하는 것들을 복호화한다.
	 * @param domain	 : 암호문의의 domain (ex. tableName, sequenceObjectName....
	 * @param encryptMsg : 암호문
	 * @param session    : 개인의 암호화 key를 가지고 있다.
	 * @return
	 */
	public static String decryptMsg(String domain, String encryptMsg, HttpSession session)throws Exception{
		String decryptMsg = "";
		if(isValidDomain(domain)){
			try{				
				decryptMsg = doCipher(DECRYPT_MODE, encryptMsg, session );
			}catch(Exception e){
				e.printStackTrace();
				throw e;
			}
		}else{
			decryptMsg = encryptMsg;
		}
		return decryptMsg;
	}
	
	/**
	 * map의 key값이 암호화 대상 domain에 해당하는 경우 복호화 한다.
	 * (Map의)key 값에 해당하는 value가 string, string[] 두가지 경우가 올 수 있다.
	 * @param map
	 * @param session
	 */
	public static void decryptMap(HashMap map, HttpSession session)throws Exception{
		Iterator iter = map.keySet().iterator();
		Object key ;
		Object value;
		
		while(iter.hasNext()){
			key = iter.next();
			if(key instanceof String && isValidDomain((String)key)) {
				value = map.get(key);
				if(value instanceof String && !value.equals("")){
					value = decryptMsg((String)key, (String)value,session); 
				}else if(value instanceof String[]){
					for(int i = 0 ; i < ((String[])value).length ; i++){
						if (!((String[])value)[i].equals(""))
							((String[])value)[i] = decryptMsg((String)key, ((String[])value)[i],session);						
					}
				}
			}
		}
	}
	
	/**
	 * domain이 암호화 대상인지를 판단한다.
	 * @param domain
	 * @return
	 */
	private static boolean isValidDomain(String domain){
		if("tableName".equals(domain)
				|| "sequenceColumnName".equals(domain)
				|| "passwordId".equals(domain)
				|| "applicantId".equals(domain)
				|| "juminId".equals(domain)
		  ){
			return true;
		}
		return false;
	}
	
    /**
     * HashMap에 있는 String , String [] , HashMap에 해당하는 object값을 print(stand out으로)한다.
     * @param map
     */
    public static void printMap(HashMap map){
    	Iterator iterator = map.keySet().iterator();
    	Object key ;
    	Object value;
    	while(iterator.hasNext()){
    		key = iterator.next();
    		if(key instanceof String){
    			value = map.get((String)key);
    			if(value instanceof String){
    				System.out.println((String)key + ":::" + (String)value);
    			}else if(value instanceof String[]){
    				String[] values = (String[])value;
    				for(int i = 0 ; i < values.length ; i++){
    					System.out.println((String)key + "[" + i + "]" + values[i]);
    				}
    			}else if(value instanceof HashMap){
                    System.out.println("map name :: " + key);
    				printMap((HashMap)value);
    			}else if(value.getClass().isArray()){
                    System.out.println("map name :: " + key);
                    if(((Object[])value)[0] instanceof HashMap){
                        printMap((HashMap)((Object[])value)[0]);
                    }
                }else{
                    continue;
                }
    		}else{
    			continue;
    		}
    	}
    }
}
