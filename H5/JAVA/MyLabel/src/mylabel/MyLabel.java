package mylabel;

public class MyLabel extends Object{

	public String label;
	public String labelCode;
	public String resultCode;
	public String fileName;
	
	public String getLabel() {
		return label;
	}
	public String getLabelCode() {
		return labelCode;
	}
	public String getResultCode() {
		return resultCode;
	}
	public String getFileName() {
		return fileName;
	}
	public boolean isFailure() {
		return !label.equals(labelCode);
	}
	@Override
	public String toString() {
		return "Label [fileName=" + fileName.substring(fileName.lastIndexOf("\\")) + ", label=\"" + label + "\", labelCode=\"" + label + "\", labelCode=\"" + labelCode + "\"]";
	}
	
}
