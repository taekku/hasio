package h5.secure;

import java.io.UnsupportedEncodingException;
import java.util.Base64;
import java.util.Base64.Decoder;
import java.util.Base64.Encoder;

public class KISA_SEED {
	 
    static String charset = "utf-8";
 
    public static byte pbUserKey[];
    
    public static byte bszIV[] = { (byte) 0x64, (byte) 0x6f, (byte) 0x6e, (byte) 0x67,
    		(byte) 0x77, (byte) 0x6f, (byte) 0x6e, (byte) 0x31, (byte) 0x32, (byte) 0x33,
    		(byte) 0x65, (byte) 0x68, (byte) 0x72, (byte) 0x61,
    		(byte) 0x70, (byte) 0x69 };
    
//    public static void main(String[] args) {
//        
//    	System.out.println("Key1 : " + pbUserKey);
//    	KISA_SEED seed = new KISA_SEED("dongwon123ehrapi");
//    	
//        String encryptData;
//        
//        try {
//            encryptData = seed.encrypt("E20140002");
//            seed.decrypt(encryptData);
//        } catch (UnsupportedEncodingException e) {
//            e.printStackTrace();
//        }
//    }
    
    public KISA_SEED(final String key) {
    	System.out.println("before validation : " + key);
        validation(key);
        try {
			pbUserKey = key.getBytes(charset);
		} catch (UnsupportedEncodingException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
        System.out.println("Key : " + pbUserKey);
    }
    
	private void validation(final String key) {
		/*
		 * Optional.ofNullable(key) .filter(Predicate.not(String::isBlank))
		 * .filter(Predicate.not(s -> s.length() != 16))
		 * .orElseThrow(IllegalArgumentException::new);
		 */ }
 
    public String encrypt(String str) throws UnsupportedEncodingException {
        byte[] msg = null;
 
        try {
            msg = KISA_SEED_CBC.SEED_CBC_Encrypt(pbUserKey, bszIV, str.getBytes(charset), 0,
                    str.getBytes(charset).length);
        } catch (UnsupportedEncodingException e) {
            e.printStackTrace();
        }
 
        Encoder encoder = Base64.getEncoder();
        byte[] encArray = encoder.encode(msg);
        try {
            System.out.println(new String(encArray, "utf-8"));
        } catch (UnsupportedEncodingException e) {
            e.printStackTrace();
        }
        return new String(encArray, "utf-8");
    }
 
    public String decrypt(String str) {
    	
    	System.out.println("decrypt str : " + str);
 
        Decoder decoder = Base64.getDecoder();
        System.out.println("decoder : " + decoder);
        
        byte[] msg = decoder.decode(str);
        System.out.println("msg : " + msg);
        
 
        String result = "";
        byte[] dec = null;
 
        try {
            dec = KISA_SEED_CBC.SEED_CBC_Decrypt(pbUserKey, bszIV, msg, 0, msg.length);
            result = new String(dec, charset);
            
            System.out.println("decrypt result : " + result);
            
        } catch (UnsupportedEncodingException e) {
            e.printStackTrace();
        }
 
        System.out.println("decrypt Result = " + result);
        return result;
    }
 
}