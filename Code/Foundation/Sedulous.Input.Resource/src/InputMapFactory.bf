using System;
using Sedulous.Content;
using Sedulous.Resource;

namespace Sedulous.Input.Resource;

/// Binds a cooked input map.
///
/// The stored object IS the product, so the whole build is reading it. That makes it a
/// pure function of the instance's bytes, which is exactly what the async path asks for:
/// it decodes on a worker and finalize has nothing left to do.
class InputMapFactory : IResourceFactory
{
	public uint64 ProductTypeId => ResourceManager.ProductTypeIdOf<InputMapResource>();

	public bool SupportsAsync => true;

	public Object Create(ResourceManager manager, Instance instance) => Read(instance);

	public Object DecodeStage(Instance instance) => Read(instance);

	public Object FinalizeStage(ResourceManager manager, Object decoded) => decoded;

	private Object Read(Instance instance)
	{
		let stored = instance.ReadObject();
		if (stored == null)
			return null;

		// Anything else stored under this type name is a mismatch rather than a map, and
		// handing it back as one would fail later, somewhere less obvious.
		if (let map = stored as InputMapResource)
			return map;

		delete stored;
		return null;
	}
}
