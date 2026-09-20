using System;

namespace Sedulous.Editor.Core;

/// A shared script debugger breakpoint: the script page's gutter toggles them per source
/// file and line, a Game run applies them to its debugger. Plain data, so a remote debugger
/// consumes the same set.
class ScriptBreakpoint
{
	/// The source file name, the section the runtime reports.
	public String File = new .() ~ delete _;
	/// 1 based.
	public int32 Line = 0;

	public this(StringView file, int32 line)
	{
		File.Set(file);
		Line = line;
	}
}
