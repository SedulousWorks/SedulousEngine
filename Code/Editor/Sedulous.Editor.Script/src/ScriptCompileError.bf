using System;

namespace Sedulous.Editor.Script;

/// One line of a cook's problem list, split as the margin and the error pane show it:
/// "section(row,col): kind: message" from a runtime, or a bare message.
class ScriptCompileError
{
	/// The reporting section; empty is the asset's own file.
	public String Module = new .() ~ delete _;
	/// One based; zero when the problem has no line.
	public int32 Line = 0;
	public String Message = new .() ~ delete _;

	/// Parses a runtime's "section(row,col): kind: message"; anything else lands whole in
	/// the message.
	public static ScriptCompileError Parse(StringView problem)
	{
		let error = new ScriptCompileError();
		let open = problem.IndexOf('(');
		let close = (open >= 0) ? problem.IndexOf(')', open) : -1;
		if ((open > 0) && (close > open) && (close + 1 < problem.Length) && (problem[close + 1] == ':'))
		{
			let inside = problem.Substring(open + 1, close - open - 1);
			let comma = inside.IndexOf(',');
			let rowText = (comma >= 0) ? inside.Substring(0, comma) : inside;
			if (int32.Parse(rowText) case .Ok(let row))
			{
				error.Module.Set(problem.Substring(0, open));
				error.Line = row;
				var rest = problem.Substring(close + 2);
				rest.Trim();
				error.Message.Set(rest);
				return error;
			}
		}
		error.Message.Set(problem);
		return error;
	}
}
