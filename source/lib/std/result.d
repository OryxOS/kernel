module lib.std.result;

/* OryxOS Result<T, E> implementation
 * In kernel land, there is no RTTI, meaning that error handling
 * has to be done through return statements. RTTI also isn't great
 * for FFI and syscalls. This library has been created to create a
 * universal error handling solution
 */

struct Result(T, E) {
	private T    result;  // Result presuming success
	private E    error;   // Error presuming failure

	bool isOkay;          // Was the funtion successful (is result valid)

	this (T good) {
		this.result = good;
		isOkay = true;
	}

	this (E fail) {
	   this.error = fail;
	   isOkay = false;
	}

	T unwrapResult(string message = "Unwrap failed: no result") {
		assert(isOkay, message);
		return result;
	}

	E unwrapError(string message = "Unwrap failed: no error") {
		assert(!isOkay, message);
		return error;
	}
}