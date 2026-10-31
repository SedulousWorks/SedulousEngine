using System;

namespace Sedulous.UI.Toolkit;

/// One compiler or validator message against a line.
class CodeDiagnostic
{
	public bool IsError = true;
	/// Zero based.
	public int32 Line = 0;
	public String Message = new .() ~ delete _;

	public this() {}

	public this(bool isError, int32 line, StringView message)
	{
		IsError = isError;
		Line = line;
		Message.Set(message);
	}
}
