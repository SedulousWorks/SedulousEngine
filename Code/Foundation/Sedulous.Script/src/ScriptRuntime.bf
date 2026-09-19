using System;
using System.Collections;

namespace Sedulous.Script;

/// A script backend.
///
/// Thin by design: a backend is handed a surface and registers it, compiles source into
/// named modules, and calls into them. The null backend does only the first.
abstract class ScriptRuntime
{
	/// BORROWED for the runtime's life: the host owns the surface.
	protected ScriptSurface mSurface = null;

	public ScriptSurface Surface => mSurface;

	public abstract StringView Name { get; }

	/// Registers every type of the surface with the backend.
	public virtual void Bind(ScriptSurface surface)
	{
		mSurface = surface;
	}

	/// What the bound calls reach: the scene, the services. Null for a backend with no calls.
	public virtual ScriptCallContext Context => null;

	/// Compiles `source` into the module, replacing what it held. False on a compile error,
	/// with the messages in Problems.
	public virtual bool Compile(StringView moduleName, StringView sectionName, StringView source) => false;

	/// Calls a global function of a module by its declaration, `float f(int, int)` say.
	/// False when it is not there, or the call failed; the reason is in Problems.
	public virtual bool Call(StringView moduleName, StringView declaration, Span<ScriptValue> args, ref ScriptValue result) => false;

	/// What went wrong, in order: registration, compile and runtime messages.
	public List<String> Problems = new .() ~ DeleteContainerAndItems!(_);

	protected void Problem(StringView text)
	{
		Problems.Add(new String(text));
	}
}
