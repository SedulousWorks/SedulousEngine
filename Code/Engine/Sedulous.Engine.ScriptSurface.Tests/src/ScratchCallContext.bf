using System;
using System.Collections;
using Sedulous.Script;

namespace Sedulous.Engine.ScriptSurface.Tests;

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

	public override void SetService(Type type, Object service)
	{
		if (service == null)
			Services.Remove(type);
		else
			Services[type] = service;
	}

	public override void* AllocScratch(int size, int align)
	{
		let p = Internal.Malloc(size);
		mAllocs.Add(p);
		return p;
	}
}
