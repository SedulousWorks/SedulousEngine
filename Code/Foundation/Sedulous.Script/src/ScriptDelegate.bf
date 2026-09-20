using System;

namespace Sedulous.Script;

/// A script function held by native code as a callback: what `button.OnClick(fn)` keeps.
///
/// A backend makes one from the function a script passed, holding the function alive, and
/// Invoke calls back into the script with the arguments marshalled against the function's
/// own parameters. OWNED by the native side a call handed it to, which deletes it when the
/// binding is replaced or the holder goes; a runtime that dies first leaves it dead, and a
/// dead one answers false. To a script the parameter is a `ScriptCallback@`.
abstract class ScriptDelegate
{
	/// Whether the runtime behind it still exists.
	public abstract bool IsAlive { get; }

	/// Calls the script function. False when it faulted, is dead, or a debugger held it.
	public abstract bool Invoke(Span<ScriptValue> args, ref ScriptValue result);

	public bool Invoke() { var r = ScriptValue.Nil; return Invoke(default, ref r); }
}
