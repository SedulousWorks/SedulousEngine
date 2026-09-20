using System;
using AngelScript;
using Sedulous.Script;

namespace Sedulous.Script.AngelScript;

/// A `ScriptCallback@` a script passed, held by native code: the function, a reference
/// kept on it, and for a delegate to a method the object it is bound to.
class AngelScriptDelegate : ScriptDelegate
{
	/// BORROWED; null once the runtime went.
	private AngelScriptRuntime mRuntime;
	private AS.Function* mFunction;

	public this(AngelScriptRuntime runtime, AS.Function* fn)
	{
		mRuntime = runtime;
		mFunction = fn;
		AS.asc_function_add_ref(fn);
		runtime.[Friend]RegisterDelegate(this);
	}

	public ~this()
	{
		if (mRuntime != null)
		{
			mRuntime.[Friend]UnregisterDelegate(this);
			AS.asc_function_release(mFunction);
		}
	}

	/// The runtime is going: the function it owns may not be touched from here on.
	public void RuntimeGone()
	{
		mRuntime = null;
		mFunction = null;
	}

	public override bool IsAlive => mRuntime != null;

	public override bool Invoke(Span<ScriptValue> args, ref ScriptValue result)
	{
		if ((mRuntime == null) || (mFunction == null))
			return false;
		// A delegate to a method carries its object; a plain function none.
		var fn = mFunction;
		let bound = AS.asc_function_get_delegate_object(fn);
		if (bound != null)
			fn = AS.asc_function_get_delegate_function(fn);
		return mRuntime.[Friend]Execute(fn, bound, args, ref result, "callback");
	}
}
