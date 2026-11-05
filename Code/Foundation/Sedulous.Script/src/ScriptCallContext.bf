using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.Script;

/// What a thunk reaches beyond its arguments: the ambient scene, the host's services, and
/// storage for what it hands back by pointer.
abstract class ScriptCallContext
{
	/// The owner an entity naming none resolves in, and the one a call is in when nothing
	/// names one: an entity value with no owner of its own, or a system reached with no
	/// object. Null outside any.
	public Object AmbientOwner = null;

	/// The last failure a frame reported, for a host with no exception to raise.
	public String LastError = new .() ~ delete _;

	/// The references calls handed over and the VM has yet to drop: one each, released once
	/// the VM has taken its own (ReleasePending), or with the context.
	private List<IScriptCounted> mPending = new .() ~ delete _;

	public ~this()
	{
		ReleasePending(0);
	}

	/// Asked for a service the context does not hold itself (SetService's): its owner's lookup, a
	/// run host's (its own, its run's, the application's). OWNED; null asks no one.
	private delegate Object(Type type) mResolver = null ~ delete _;

	/// The host's service of `type`, for a Service role call, or null when the run has none: the
	/// context's own (SetService), else what its resolver finds.
	public abstract Object FindService(Type type);

	/// Who answers for a service the context does not hold itself. TAKES OWNERSHIP; null asks no
	/// one.
	public void SetServiceResolver(delegate Object(Type type) resolver)
	{
		delete mResolver;
		mResolver = resolver;
	}

	/// What the resolver finds of `type`; null without one.
	protected Object ResolveService(Type type) => (mResolver != null) ? mResolver(type) : null;

	/// Installs, or with null removes, the service a Service role call of `type` reaches.
	/// BORROWED: the host owns it and outlives the run.
	public abstract void SetService(Type type, Object service);

	/// Storage that lives at least until the VM has consumed the call's result. A VM
	/// releases it when it has, or with the context.
	public abstract void* AllocScratch(int size, int align);

	/// Where a struct result goes: scratch, unless the VM has a place of its own for it.
	public virtual void* AllocStruct(Type type, int size, int align) => AllocScratch(size, align);

	/// The reference a counted result carries, a constructor's or a [ScriptReturnsReference]
	/// method's: released after the call, by when the VM has taken one of its own if it keeps
	/// the object. Null is nothing to release.
	public void ReleaseAfterCall(IScriptCounted counted)
	{
		if (counted != null)
			mPending.Add(counted);
	}

	/// The pending high water mark before a call, and the release back to it once the call's
	/// result is consumed, as for scratch: nested calls stack.
	public int PendingMark => mPending.Count;

	public void ReleasePending(int mark)
	{
		// One at a time: a release may free an object whose teardown calls back in.
		while (mPending.Count > mark)
			mPending.PopBack().ReleaseRef();
	}

	/// A list of `count` Nil values of `elementKind`, in scratch, for the thunk to fill.
	public ScriptList* AllocList(int count, ScriptValueKind elementKind, StringView elementType)
	{
		// strideof, not sizeof: the items are an array, and a Beef sizeof leaves off the
		// tail padding the next element starts after.
		let list = (ScriptList*)AllocScratch(strideof(ScriptList), alignof(ScriptList));
		list.Count = (int32)count;
		list.ElementKind = elementKind;
		list.ElementType = elementType;
		list.Items = (count > 0) ? (ScriptValue*)AllocScratch(strideof(ScriptValue) * count, alignof(ScriptValue)) : null;
		for (int i < count)
			list.Items[i] = .Nil;
		return list;
	}
}
