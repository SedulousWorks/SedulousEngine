using System;
using Sedulous.Scene;

namespace Sedulous.Script;

/// What a thunk reaches beyond its arguments: the ambient scene, the host's services, and
/// storage for what it hands back by pointer.
abstract class ScriptCallContext
{
	/// The scene a call is in when nothing names one: an entity value with no scene of its
	/// own, or a system reached with no object. Null outside any scene.
	public Scene Scene = null;

	/// The last failure a frame reported, for a host with no exception to raise.
	public String LastError = new .() ~ delete _;

	/// The host's service of `type`, for a Service role call, or null when the run has none.
	public abstract Object FindService(Type type);

	/// Installs, or with null removes, the service a Service role call of `type` reaches.
	/// BORROWED: the host owns it and outlives the run.
	public abstract void SetService(Type type, Object service);

	/// Storage that lives at least until the VM has consumed the call's result. A VM
	/// releases it when it has, or with the context.
	public abstract void* AllocScratch(int size, int align);

	/// Where a struct result goes: scratch, unless the VM has a place of its own for it.
	public virtual void* AllocStruct(Type type, int size, int align) => AllocScratch(size, align);

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
