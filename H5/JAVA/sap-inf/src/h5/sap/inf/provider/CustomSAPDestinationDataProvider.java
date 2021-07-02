package h5.sap.inf.provider;

import java.util.HashMap;
import java.util.Properties;

import com.sap.conn.jco.ext.DestinationDataEventListener;
import com.sap.conn.jco.ext.DestinationDataProvider;

public class CustomSAPDestinationDataProvider {

	public static class MyDestinationDataProvider implements DestinationDataProvider {

		private DestinationDataEventListener eL;

		private HashMap<String, Properties> destinations;

		private static MyDestinationDataProvider provider = new MyDestinationDataProvider();

		private MyDestinationDataProvider() {// singleton mode

			if (provider == null) {

				destinations = new HashMap<String, Properties>();
			}
		}

		public static MyDestinationDataProvider getInstance() {

			return provider;
		}

		// Implement interface: Get connection configuration properties
		public Properties getDestinationProperties(String destinationName) {

			if (destinations.containsKey(destinationName)) {

				return destinations.get(destinationName);
			} else {

				throw new RuntimeException("Destination " + destinationName + " is not available");
			}
		}

		public void setDestinationDataEventListener(DestinationDataEventListener eventListener) {

			this.eL = eventListener;
		}

		public boolean supportsEvents() {

			return true;
		}

		/**
		 * Add new destination Add connection configuration properties
		 *
		 * @param properties holds all the required data for a destination
		 **/
		public void addDestination(String destinationName, Properties properties) {

			synchronized (destinations) {

				destinations.put(destinationName, properties);
			}
		}
	}
}
