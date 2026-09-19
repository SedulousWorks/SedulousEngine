using System;
using System.Collections;

namespace Sedulous.Script;

/// How the debugger's execution state moved, delivered to a listener.
enum ScriptDebuggerState : uint8
{
	Running,
	/// Stopped at a breakpoint.
	Breakpoint,
	/// Stopped after a step.
	Stepped,
	/// The held call ran to completion, or faulted.
	Terminated
}

/// The debugger's state change sink: a remote interface or the editor. BORROWED.
interface IScriptDebuggerListener
{
	void OnDebuggerStateChanged(ScriptDebuggerState state);
}

/// A step debugger over a runtime: breakpoints by file and line, break, continue, step,
/// and the captures of a paused run's stack, locals and objects.
///
/// Single threaded and non blocking: a breakpoint SUSPENDS the script call that hit it,
/// which unwinds to the caller as a paused rather than a failed call, and the debugger
/// holds that call for inspection. Continue and the steps run the held call on, in the
/// caller's thread, on whichever frame they are asked. The run around the paused script
/// keeps going; what the host does with a paused run, hold the scene's script tick say,
/// is the host's.
interface IScriptDebugger
{
	/// A breakpoint on a line of a script section, by the name the section was compiled as.
	void SetBreakpoint(StringView file, int32 line);
	void RemoveBreakpoint(StringView file, int32 line);
	void ClearBreakpoints();

	/// Suspends at the next executed line of whatever runs next: a manual pause.
	void Break();
	/// Runs the held call on to the next breakpoint or its completion.
	void Continue();
	void StepInto();
	void StepOver();

	/// Paused at a breakpoint or a step, holding a call.
	bool IsPaused { get; }
	ScriptDebuggerState State { get; }

	/// The held call's stack, innermost first. Nothing when not paused.
	void CaptureStackFrames(List<ScriptStackFrame> outFrames);
	/// The named variables of a frame, `depth` nought the innermost.
	void CaptureLocals(uint32 depth, List<ScriptVariable> outLocals);
	/// The members of a captured object, by the ref a capture handed out. Refs are valid
	/// only within one break.
	void CaptureObject(uint64 objectRef, List<ScriptVariable> outMembers);

	/// BORROWED: null to stop listening.
	void SetListener(IScriptDebuggerListener listener);
}
