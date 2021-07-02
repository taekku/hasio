package h5.sap.inf.command;

import h5.sys.command.CommandExecuteException;

public class SapException extends CommandExecuteException {

	public SapException() {
		super();
	}

	public SapException(String message) {
		super(message);
	}

	public SapException(Throwable cause) {
		super(cause);
	}

	public SapException(String message, Throwable cause) {
		super(message, cause);
	}
}
