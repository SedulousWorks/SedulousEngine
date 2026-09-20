using Sedulous.Script;

namespace Sedulous.Editor.Scene;

/// The debugger's state changes, parked until the page drains them on its update.
class GameDebugListener : IScriptDebuggerListener
{
	public ScriptDebuggerState State = .Running;
	public bool Changed = false;

	public void OnDebuggerStateChanged(ScriptDebuggerState state)
	{
		State = state;
		Changed = true;
	}
}
