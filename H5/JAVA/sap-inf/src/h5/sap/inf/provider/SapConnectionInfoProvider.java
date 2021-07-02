package h5.sap.inf.provider;

import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.InputStream;
import java.util.Properties;

import com.sap.conn.jco.ext.DestinationDataProvider;
import com.sap.conn.jco.ext.Environment;
import com.win.rf.config.ConfigurationManager;
import com.win.rf.config.IConfigurationInfoProvider;

import h5.sap.inf.provider.CustomSAPDestinationDataProvider.MyDestinationDataProvider;
import h5.sap.inf.vo.SapConnectionInfo;

public class SapConnectionInfoProvider {
	private final static String destinationName = "PAY_SAP_INF";
	final public static String COMPANY_CODE[] = { "F", "I", "C", "H", "A", "E", "S" };

	/**
	 * 접속정보초기화 회사별접속정보등록
	 */
	public static void initConnection() {
		// 논리적인 명칭. 로그용 으로 사용 예정

		IConfigurationInfoProvider provider = ConfigurationManager.getConfigurationInfoProvider();
		String sapProperties = provider.getItem("h5_sap").getValue();

		//String resource = "/h5_sap.properties";

		if (!Environment.isDestinationDataProviderRegistered()) {
			// Get a singleton
			MyDestinationDataProvider myProvider = MyDestinationDataProvider.getInstance();
			Properties conProp;

			Properties properties = new Properties();
			InputStream input;
			String[] companies = {};
			try {
				// input = getClass().getResourceAsStream(resource);
				input = new FileInputStream(sapProperties);
				//System.out.println(input);
				properties.load(input);
				companies = properties.getProperty("SAP_COMPANIES").split(",");
				System.out.println("=========== SAP ===>");

				for (int i = 0; i < companies.length; i++) {
					conProp = new Properties();
					String companyCd = companies[i];
					System.out.println("SapConnectionInfoProvider===>company:" + companyCd);
					System.out.println("SapConnectionInfoProvider===>.ASHOST:" + properties.getProperty(companyCd + ".ASHOST"));
					System.out.println("SapConnectionInfoProvider===>.SYSNR:" + properties.getProperty(companyCd + ".SYSNR"));
					System.out.println("SapConnectionInfoProvider===>.CLIENT:" + properties.getProperty(companyCd + ".CLIENT"));
					System.out.println("SapConnectionInfoProvider===>.USER:" + properties.getProperty(companyCd + ".USER"));
					//System.out.println("SapConnectionInfoProvider===>.PASSWD:" + properties.getProperty(companyCd + ".PASSWD"));
					System.out.println("SapConnectionInfoProvider===>.LANG:" + properties.getProperty(companyCd + ".LANG"));

					conProp.setProperty(DestinationDataProvider.JCO_ASHOST,
							properties.getProperty(companyCd + ".ASHOST"));
					conProp.setProperty(DestinationDataProvider.JCO_SYSNR,
							properties.getProperty(companyCd + ".SYSNR")); // SYSTEM Number Parameter ABAP system number
																			// ('sysnr') needs to be a two digit number
					conProp.setProperty(DestinationDataProvider.JCO_CLIENT,
							properties.getProperty(companyCd + ".CLIENT")); // Client Number Parameter SAP client
																			// ('client') needs to be a three digit
																			// number
					conProp.setProperty(DestinationDataProvider.JCO_USER, properties.getProperty(companyCd + ".USER"));
					conProp.setProperty(DestinationDataProvider.JCO_PASSWD,
							properties.getProperty(companyCd + ".PASSWD"));
					conProp.setProperty(DestinationDataProvider.JCO_LANG, properties.getProperty(companyCd + ".LANG"));
					myProvider.addDestination(destinationName + "_" + companyCd, conProp);
				}
			} catch (FileNotFoundException e) {
				e.printStackTrace();
				return;
			} catch (IOException e) {
				e.printStackTrace();
				return;
			}

			Environment.registerDestinationDataProvider(myProvider);
		}
	}

	public static SapConnectionInfo getConnectionInfo(String companyCd) {

		// 프로퍼티화 할것
		SapConnectionInfo rturnInfo = new SapConnectionInfo();

		if ("F".equals(companyCd)) { // 동원 F&B

			rturnInfo.setJCO_ASHOST("172.16.8.2");
			rturnInfo.setJCO_SYSNR("00");
			rturnInfo.setJCO_CLIENT("720");
			rturnInfo.setJCO_USER("dev21");
			rturnInfo.setJCO_PASSWD("fi1234!");
			rturnInfo.setJCO_LANG("EN");

		} else if ("I".equals(companyCd)) { // 동원산업

			rturnInfo.setJCO_ASHOST("172.16.8.104");
			rturnInfo.setJCO_SYSNR("00");
			rturnInfo.setJCO_CLIENT("750");
			rturnInfo.setJCO_USER("dev11");
			rturnInfo.setJCO_PASSWD("dev1234!!");
			rturnInfo.setJCO_LANG("EN");

		} else if ("C".equals(companyCd)) { // 동원시스템즈

			rturnInfo.setJCO_ASHOST("172.16.8.161");
			rturnInfo.setJCO_SYSNR("00");
			rturnInfo.setJCO_CLIENT("700");
			rturnInfo.setJCO_USER("dev21");
			rturnInfo.setJCO_PASSWD("fi1234!");
			rturnInfo.setJCO_LANG("EN");

		} else if ("H".equals(companyCd)) { // 동원홈푸드

			rturnInfo.setJCO_ASHOST("172.16.8.211");
			rturnInfo.setJCO_SYSNR("00");
			rturnInfo.setJCO_CLIENT("700");
			rturnInfo.setJCO_USER("dev21");
			rturnInfo.setJCO_PASSWD("fi1234!");
			rturnInfo.setJCO_LANG("EN");

		} else if ("A".equals(companyCd)) { // 동원건설산업

			rturnInfo.setJCO_ASHOST("172.20.16.15");
			rturnInfo.setJCO_SYSNR("00");
			rturnInfo.setJCO_CLIENT("700");
			rturnInfo.setJCO_USER("dev11");
			rturnInfo.setJCO_PASSWD("fi1234!");
			rturnInfo.setJCO_LANG("EN");

		} else if ("E".equals(companyCd)) { // FI통합서버 엔터프라이즈

			rturnInfo.setJCO_ASHOST("172.16.6.113");
			rturnInfo.setJCO_SYSNR("00");
			rturnInfo.setJCO_CLIENT("720");
			rturnInfo.setJCO_USER("dev11");
			rturnInfo.setJCO_PASSWD("fi1234!");
			rturnInfo.setJCO_LANG("EN");

		} else if ("S".equals(companyCd)) { // 동원팜스

			rturnInfo.setJCO_ASHOST("172.16.8.17");
			rturnInfo.setJCO_SYSNR("00");
			rturnInfo.setJCO_CLIENT("720");
			rturnInfo.setJCO_USER("dev11");
			rturnInfo.setJCO_PASSWD("fi1234!");
			rturnInfo.setJCO_LANG("EN");
		}

		return rturnInfo;
	}
}
