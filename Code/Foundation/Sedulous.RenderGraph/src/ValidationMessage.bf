using System;

namespace Sedulous.RenderGraph;

/// One validation finding. OWNS its message.
class ValidationMessage
{
	public ValidationSeverity Severity = .Warning;
	public String Message = new .() ~ delete _;

	public this() {}

	public this(ValidationSeverity severity, StringView message)
	{
		Severity = severity;
		Message.Set(message);
	}
}
