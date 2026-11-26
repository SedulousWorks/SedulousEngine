using System;

namespace Sedulous.Script;

/// A live object a behavior class made, held by the host: the run's game object, a scene's, an
/// entity's behavior. The layer that runs behaviors calls it by method name and reads its
/// properties through it, never knowing what is behind it: a script object in a language's VM,
/// which a backend subclasses with what it needs to reach it and whose calls go to its runtime, or
/// a class written in native code, which answers them itself (and has no runtime). Let go through
/// Release, never deleted directly.
abstract class BehaviorObject
{
	/// BORROWED: the runtime a script object lives in; null for a native one.
	public ScriptRuntime Runtime;
	public String ClassName = new .() ~ delete _;

	/// Whether the object has a method `name` taking `arity` arguments.
	public virtual bool HasMethod(StringView name, int arity) => (Runtime != null) && Runtime.HasMethod(this, name, arity);
	/// Calls method `name`; false when it faulted (or the call could not be made), its reason with
	/// whoever made the object.
	public virtual bool Invoke(StringView name, Span<ScriptValue> args, ref ScriptValue result) => (Runtime != null) && Runtime.Invoke(this, name, args, ref result);
	/// Reads property `name`; false when the object has none.
	public virtual bool GetProperty(StringView name, ref ScriptValue value) => (Runtime != null) && Runtime.GetProperty(this, name, ref value);
	/// Writes property `name`; false when the object has none of that type.
	public virtual bool SetProperty(StringView name, ScriptValue value) => (Runtime != null) && Runtime.SetProperty(this, name, value);
	/// Ends every coroutine the object started.
	public virtual void CancelCoroutines()
	{
		if (Runtime != null)
			Runtime.CancelCoroutinesFor(this);
	}
	/// Lets the object go: a script object back to its runtime, a native one deleted. Not used after.
	public virtual void Release()
	{
		if (Runtime != null)
			Runtime.Release(this);
	}
}
