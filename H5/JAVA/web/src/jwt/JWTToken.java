package jwt;

import java.io.UnsupportedEncodingException;
import java.security.Key;
import java.util.ArrayList;
import java.util.Date;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

import javax.crypto.spec.SecretKeySpec;
import javax.xml.bind.DatatypeConverter;

import org.json.simple.JSONArray;
import org.json.simple.JSONObject;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.ExpiredJwtException;
import io.jsonwebtoken.JwtBuilder;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.SignatureAlgorithm;
import sun.security.util.SecurityConstants;

public class JWTToken {

	private String secretKey = "win_tokensign1";

	public static void main(String[] args) {
		JWTToken jwtTokenDemo = new JWTToken();
//		 String tokens = jwtTokenDemo.createJWT("20130054", "01", "KO", "thriev.com",
//		 "white information network", new Date(System.currentTimeMillis() + ( 60000 )
//		 ), 12999L);
//		 System.out.println("## token : "+tokens);

//		Map<String, Object> map = null;
//		
//		  String jwt =
//		  "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJhdWQiOiIyMDEzMDA1NCIsImlhdCI6MTYxMTkwNjA4NSwic3ViIjoid2hpdGUgaW5mb3JtYXRpb24gbmV0d29yayIsImlzcyI6InRocmlldi5jb20iLCJjb21wYW55Q2QiOiIwMSIsImxvZ2luSWQiOiIyMDEzMDA1NCIsImxvY2FsZUNkIjoiS08iLCJleHAiOjE2MTE5MDYxNDR9.tFgtRUDslT7ZAxzFZxbRTT4Ozl_tTulBfidy8uO7Mc8";
//		  try { map = jwtTokenDemo.verifyJWT(jwt);
//		  
//		  System.out.println(map.get("localeCd"));
//		  
//		  System.out.println("####### jwt 검증 : " + jwtTokenDemo.verifyJWT(jwt));
//		  
//		  
//		  } catch (UnsupportedEncodingException e) { // TODO Auto-generated catch block
//		  e.printStackTrace(); }

	}
	
	
	/**
	 * JWT Token 생성 
	 * @param id
	 * @param issuer
	 * @param subject
	 * @param ttlMillis
	 * @return
	 */
	public String createJWT(String loginId, String companyCd, String localeCd, String issuer, String subject,
			Date exDate, long ttlMillis) {

		SignatureAlgorithm signatureAlgorithm = SignatureAlgorithm.HS256;
		long nowMillis = System.currentTimeMillis();
		Date now = new Date(nowMillis);
		// UUID.randomUUID().toString();
		JwtBuilder builder = null;
		try {
			byte[] apiKeySecretBytes = DatatypeConverter.parseBase64Binary(secretKey);
			Key signingKey = new SecretKeySpec(apiKeySecretBytes, secretKey);//
			System.out.println("key : " + signingKey);
			builder = Jwts.builder().setHeaderParam("typ", "JWT")
					// .setId(id)
					.setAudience(loginId).setIssuedAt(new Date()).setSubject(subject).setIssuer(issuer)
					.claim("companyCd", companyCd).claim("loginId", loginId).claim("localeCd", localeCd)
//					.claim("pageType", "token")
					.signWith(signatureAlgorithm, signingKey);

			if (ttlMillis >= 0) {
				builder.setExpiration(exDate);// 토큰 만료 시간 설정
			}
			// System.out.println("JAVA compact : "+builder.compact());
		} catch (Exception e) {
			System.out.println("error !! " + e.toString());
			e.printStackTrace();
		}
		return builder.compact(); // 토큰 생성
	}

	/**
	 * 토큰 검증
	 * 
	 * @param jwt
	 * @return
	 * @throws UnsupportedEncodingException
	 */
	public Map<String, Object> verifyJWT(String jwt) throws UnsupportedEncodingException {
		Map<String, Object> claimMap = null;
		try {
			Claims claims = Jwts.parser().setSigningKey(DatatypeConverter.parseBase64Binary(secretKey))
					.parseClaimsJws(jwt).getBody();
			claimMap = claims;

		} catch (ExpiredJwtException e) { // 토큰이 만료되었을 경우
			System.out.println(e);
		} catch (Exception ee) { // 그외 에러발생
			System.out.println(ee);
		}
		return claimMap;
	}
}