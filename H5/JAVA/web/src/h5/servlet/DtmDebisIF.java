package h5.servlet;

import java.io.IOException;
import java.io.PrintWriter;
import java.net.InetAddress;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.json.simple.JSONObject;

import com.dongwon.eai.EaiIndigoSender;
import com.dongwon.eai.EaiResponse;

public class DtmDebisIF extends HttpServlet{

	@Override
	protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {

		InetAddress ia = InetAddress.getLocalHost();
		String serverIp = ia.getHostAddress();
		//개발ip
		String eaiIp = "172.16.5.25";

		//운영ip
		if("172.20.31.51".equals(serverIp) || "172.20.31.52".equals(serverIp)){
			eaiIp = "172.16.6.110";
		}

		String base_ym = request.getParameter("base_ym");

		EaiIndigoSender indigoEaiSender = new EaiIndigoSender(eaiIp, 8222);

		response.setContentType("application/x-json; charset=UTF-8");
		PrintWriter pw = response.getWriter();
		JSONObject result = new JSONObject();

		//년월 형식 체크
		Pattern pattern =  Pattern.compile("^((19|20)\\d\\d)?([- /.])?(0[1-9]|1[012])$");
		Matcher matcher = pattern.matcher(base_ym);

		if(matcher.find() == false) // 체크
		{
		    result.put("result", "FAIL!");
			result.put("errMsg", "대상년월 형식이 일치하지 않습니다.");
		} else {
			try {
				//상용직인원일자별I/F
				indigoEaiSender.setParameter("YM_DUTY", base_ym);
				EaiResponse response1 = indigoEaiSender.sendAndResponse("DEBIS_REGULAR_DAILY"		, "APTDC", "EHR");
				//상용직월별집계I/F
				indigoEaiSender.setParameter("YM_DUTY", base_ym);
				EaiResponse response2 = indigoEaiSender.sendAndResponse("DEBIS_REGULAR_MONTH"		, "APTDC", "EHR");
				//상용직연장월별I/F
				indigoEaiSender.setParameter("YM_DUTY", base_ym);
				EaiResponse response3 = indigoEaiSender.sendAndResponse("DEBIS_EXT_REGULAR_MONTH"	, "APTDC", "EHR");
				//정규직인원일자별I/F
				indigoEaiSender.setParameter("YM_DUTY", base_ym);
				EaiResponse response4 = indigoEaiSender.sendAndResponse("DEBIS_FULLTIME_DAILY"		, "APTDC", "EHR");
				//정규직인원월별I/F
				indigoEaiSender.setParameter("YM_DUTY", base_ym);
				EaiResponse response5 = indigoEaiSender.sendAndResponse("DEBIS_FULLTIME_MONTH"		, "APTDC", "EHR");

				result.put("result", "SUCCESS!");
				result.put("errMsg", "null");

				//인터페이스 중 하나라도 오류일 시 FAIL
				if (response1.getStatus().equals("E") ) {
					result.put("result", "FAIL!");
					result.put("errMsg", "1>> " + response1.getMessage());
				} else if (response2.getStatus().equals("E") ) {
					result.put("result", "FAIL!");
					result.put("errMsg", "2>> " + response2.getMessage());
				} else if (response3.getStatus().equals("E") ) {
					result.put("result", "FAIL!");
					result.put("errMsg", "3>> " + response3.getMessage());
				} else if (response4.getStatus().equals("E") ) {
					result.put("result", "FAIL!");
					result.put("errMsg", "4>> " + response4.getMessage());
				} else if (response5.getStatus().equals("E") ) {
					result.put("result", "FAIL!");
					result.put("errMsg", "5>> " + response5.getMessage());
				}
			} catch(Exception e){
				e.printStackTrace();
			}
		}

		pw.print(result);
		pw.flush();

	}
}
