using System;

namespace Sedulous.Script;

/// Reads a runtime's problem lines ("section(row,col): kind: message").
static class ScriptProblems
{
	/// Whether the line is a compiler warning: the script compiled, but the line is likely a
	/// mistake worth reading. Never a reason a compile or a cook failed.
	public static bool IsWarning(StringView problem)
	{
		let close = problem.IndexOf("): ");
		return (close >= 0) && problem.Substring(close + 3).StartsWith("warning:");
	}
}
