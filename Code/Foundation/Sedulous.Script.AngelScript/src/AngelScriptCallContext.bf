using System;
using System.Collections;
using Sedulous.Script;

namespace Sedulous.Script.AngelScript;

/// The context the AngelScript backend hands its thunks.
///
/// A struct result is placed where AngelScript wants it: the return location of the call
/// in progress, or the value being constructed. Outside a call there is no such place, and
/// storage is taken from a scratch list freed with the context.
class AngelScriptCallContext : ScriptCallContext
{
	public Dictionary<Type, Object> Services = new .() ~ delete _;
	private List<void*> mScratch = new .() ~ delete _;

	/// Where the thunk's struct result goes, set by the trampoline around each call.
	public void* ResultTarget = null;

	public ~this()
	{
		for (let p in mScratch)
			Internal.Free(p);
	}

	public override Object FindService(Type type)
	{
		if (Services.TryGetValue(type, let service))
			return service;
		return null;
	}

	public override void* AllocScratch(int size, int align)
	{
		let p = Internal.Malloc(size);
		mScratch.Add(p);
		return p;
	}

	public override void* AllocStruct(Type type, int size, int align)
	{
		if (ResultTarget != null)
			return ResultTarget;
		return AllocScratch(size, align);
	}

	/// The scratch high water mark before a call, and the release back to it once the
	/// call's result is consumed: nested calls stack, and a tick's lists do not pile up.
	public int ScratchMark => mScratch.Count;

	public void ReleaseScratch(int mark)
	{
		for (int i = mScratch.Count - 1; i >= mark; i--)
			Internal.Free(mScratch[i]);
		mScratch.Count = Math.Min(mark, mScratch.Count);
	}
}
