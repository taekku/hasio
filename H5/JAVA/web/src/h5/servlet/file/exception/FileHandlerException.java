package h5.servlet.file.exception;

public class FileHandlerException extends Exception {

	private String errCode = null;
	private String errMessage = null;
	
	public FileHandlerException() {
		// TODO Auto-generated constructor stub
	}

	public FileHandlerException(String arg0) {
		super(arg0);
		// TODO Auto-generated constructor stub
	}

	public FileHandlerException(Throwable arg0) {
		super(arg0);
		// TODO Auto-generated constructor stub
	}

	public FileHandlerException(String arg0, Throwable arg1) {
		super(arg0, arg1);
		// TODO Auto-generated constructor stub
	}
	
	public String getErrCode() {
		return errCode;
	}
	public void setErrCode(String errCode) {
		this.errCode = errCode;
	}
	public String getErrMessage() {
		return errMessage;
	}
	public void setErrMessage(String errMessage) {
		this.errMessage = errMessage;
	}
}
