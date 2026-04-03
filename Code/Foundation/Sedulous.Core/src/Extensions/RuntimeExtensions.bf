namespace System;


extension Runtime
{
	[NoReturn]
	public static void RuntimeError(String msg, String filePath, int line, int stackOffset = 1)
	{
#if !BF_RUNTIME_REDUCED
		String failStr = scope .()..Append(msg, " at line ");
		line.ToString(failStr);
		failStr.Append(" in ", filePath);
		Internal.FatalError(failStr, stackOffset);
#else
		Internal.FatalError("Runtime error", stackOffset);
#endif
	}

	[NoReturn]
	public static void NotImplementedError(String message = "Not implemented.", String filePath = Compiler.CallerFilePath, int line = Compiler.CallerLineNum)
	{
		Runtime.RuntimeError(message, filePath, line, 2);
	}

	[NoReturn]
	public static void InvalidOperationError(String message = "Invalid operation.", String filePath = Compiler.CallerFilePath, int line = Compiler.CallerLineNum)
	{
		Runtime.RuntimeError(message, filePath, line, 2);
	}

	[NoReturn]
	public static void ArgumentOutOfRangeError(String message = "Argument out of range.", String filePath = Compiler.CallerFilePath, int line = Compiler.CallerLineNum)
	{
		Runtime.RuntimeError(message, filePath, line, 2);
	}

	[NoReturn]
	public static void ArgumentError(String message = "Argument.", String filePath = Compiler.CallerFilePath, int line = Compiler.CallerLineNum)
	{
		Runtime.RuntimeError(message, filePath, line, 2);
	}

	[NoReturn]
	public static void ArgumentNullError(String message = "Argument null.", String filePath = Compiler.CallerFilePath, int line = Compiler.CallerLineNum)
	{
		Runtime.RuntimeError(message, filePath, line, 2);
	}

	[NoReturn]
	public static void IndexOutOfRangeError(String message = "Index out of range.", String filePath = Compiler.CallerFilePath, int line = Compiler.CallerLineNum)
	{
		Runtime.RuntimeError(message, filePath, line, 2);
	}

	[NoReturn]
	public static void DivideByZeroError(String filePath = Compiler.CallerFilePath, int line = Compiler.CallerLineNum)
	{
		Runtime.RuntimeError("Division by zero.", filePath, line, 2);
	}

	[NoReturn]
	public static void NotSupportedError(String message = "Not Supported.", String filePath = Compiler.CallerFilePath, int line = Compiler.CallerLineNum)
	{
		Runtime.RuntimeError(message, filePath, line, 2);
	}
}