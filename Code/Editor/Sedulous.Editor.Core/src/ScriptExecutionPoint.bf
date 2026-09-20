using System;

namespace Sedulous.Editor.Core;

/// The paused debugger's location, the innermost frame: set by a Game run's debugger
/// listener on a breakpoint or a step, cleared on resume or stop. The script page editing
/// that file shows it as the execution line marker.
class ScriptExecutionPoint
{
	public String File = new .() ~ delete _;
	/// 1 based.
	public int32 Line = 0;
	public bool Active = false;
}
