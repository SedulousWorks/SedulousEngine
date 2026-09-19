using System;
using System.Collections;
using Sedulous.Scripting;

namespace Sedulous.Scripting.Fixture;

/// A context for calling thunks by hand: services by type, struct storage freed with it.
class ScratchCallContext : ScriptCallContext
{
	public Dictionary<Type, Object> Services = new .() ~ delete _;
	private List<void*> mAllocs = new .() ~ delete _;

	public ~this()
	{
		for (let p in mAllocs)
			Internal.Free(p);
	}

	public override Object FindService(Type type)
	{
		if (Services.TryGetValue(type, let service))
			return service;
		return null;
	}

	public override void* AllocStruct(Type type, int size, int align)
	{
		let p = Internal.Malloc(size);
		mAllocs.Add(p);
		return p;
	}
}
